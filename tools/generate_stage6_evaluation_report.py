"""Generate the ReadBuddy Stage 6 evaluation evidence package.

This script uses only saved Stage 3/5 artifacts. It does not retrain a model,
collect participant information, or invent pilot-study observations.

Usage:
    python tools/generate_stage6_evaluation_report.py
    python tools/generate_stage6_evaluation_report.py --pilot-export path.json
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RESULTS = ROOT / "training" / "outputs" / "stage3_kaggle_v1_protected"
DEFAULT_SPLIT_SUMMARY = (
    ROOT / "training" / "splits" / "kaggle_v1_regrouped_manifest.summary.json"
)
DEFAULT_DEVICE_BENCHMARK = ROOT / "training" / "device_benchmark_android14_emulator.json"
DEFAULT_OUTPUT = ROOT / "deliverables" / "stage6_evaluation"
EXPECTED_PIPELINE = "readbuddy-stage3-cnn-v4"


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def wilson_interval(successes: int, total: int, z: float = 1.959963984540054) -> tuple[float, float]:
    if total <= 0:
        return (0.0, 0.0)
    p = successes / total
    denominator = 1 + z * z / total
    centre = (p + z * z / (2 * total)) / denominator
    margin = z * math.sqrt((p * (1 - p) + z * z / (4 * total)) / total) / denominator
    return (max(0.0, centre - margin), min(1.0, centre + margin))


def load_per_class(path: Path) -> list[dict[str, float]]:
    rows: list[dict[str, float]] = []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            rows.append(
                {
                    "class_id": int(row["class_id"]),
                    "precision": float(row["precision"]),
                    "recall": float(row["recall"]),
                    "f1": float(row["f1"]),
                    "support": int(float(row["support"])),
                }
            )
    return rows


def save_csv(path: Path, fieldnames: Iterable[str], rows: Iterable[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(fieldnames), extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def configure_plot_style() -> None:
    plt.rcParams.update(
        {
            "figure.facecolor": "white",
            "axes.facecolor": "#FAFAFA",
            "axes.edgecolor": "#333333",
            "axes.titleweight": "bold",
            "axes.grid": True,
            "grid.alpha": 0.22,
            "font.size": 10,
            "savefig.bbox": "tight",
        }
    )


def plot_model_comparison(custom: dict[str, Any], baseline: dict[str, Any], output: Path) -> None:
    labels = ["Top-1 accuracy", "Macro F1", "Balanced accuracy", "Top-3 accuracy"]
    keys = ["accuracy", "macroF1", "balancedAccuracy", "top3Accuracy"]
    custom_values = [100 * float(custom[key]) for key in keys]
    baseline_values = [100 * float(baseline[key]) for key in keys]
    x = np.arange(len(labels))
    width = 0.36
    fig, ax = plt.subplots(figsize=(9.2, 5.4))
    bars1 = ax.bar(x - width / 2, custom_values, width, label="Custom CNN", color="#176B87")
    bars2 = ax.bar(x + width / 2, baseline_values, width, label="Low-capacity control", color="#B4B4B8")
    ax.set_ylabel("Score (%)")
    ax.set_ylim(0, 100)
    ax.set_xticks(x, labels)
    ax.set_title("Held-out Test Performance (n = 11,984)")
    ax.legend(loc="upper right")
    ax.bar_label(bars1, fmt="%.2f", padding=3, fontsize=9)
    ax.bar_label(bars2, fmt="%.2f", padding=3, fontsize=9)
    ax.text(
        0.01,
        -0.16,
        "The low-capacity model is a negative control, not a competitive benchmark.",
        transform=ax.transAxes,
        fontsize=9,
        color="#555555",
    )
    fig.savefig(output, dpi=300)
    plt.close(fig)


def plot_training_history(history: dict[str, Any], output: Path) -> None:
    epochs = np.arange(1, len(history["accuracy"]) + 1)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.6))
    axes[0].plot(epochs, np.array(history["accuracy"]) * 100, label="Training", color="#176B87", linewidth=2)
    axes[0].plot(epochs, np.array(history["val_accuracy"]) * 100, label="Validation", color="#E36414", linewidth=2)
    axes[0].set(title="Accuracy by Epoch", xlabel="Epoch", ylabel="Accuracy (%)", ylim=(0, 100))
    axes[0].legend()
    axes[1].plot(epochs, history["loss"], label="Training", color="#176B87", linewidth=2)
    axes[1].plot(epochs, history["val_loss"], label="Validation", color="#E36414", linewidth=2)
    axes[1].set(title="Loss by Epoch", xlabel="Epoch", ylabel="Cross-entropy loss")
    axes[1].legend()
    fig.suptitle("Custom CNN Training History", fontsize=14, fontweight="bold")
    fig.tight_layout()
    fig.savefig(output, dpi=300)
    plt.close(fig)


def plot_per_class_recall(rows: list[dict[str, float]], output: Path) -> None:
    recalls = np.array([row["recall"] for row in rows]) * 100
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.8))
    axes[0].hist(recalls, bins=np.arange(0, 105, 5), color="#176B87", edgecolor="white")
    axes[0].axvline(recalls.mean(), color="#E36414", linestyle="--", linewidth=2, label=f"Mean {recalls.mean():.2f}%")
    axes[0].set(title="Recall Distribution Across 454 Classes", xlabel="Per-class recall (%)", ylabel="Number of classes", xlim=(0, 100))
    axes[0].legend()

    weakest = sorted(rows, key=lambda row: (row["recall"], row["class_id"]))[:15]
    ids = [str(int(row["class_id"])) for row in weakest]
    values = [100 * row["recall"] for row in weakest]
    axes[1].barh(ids[::-1], values[::-1], color="#C51605")
    axes[1].set(title="15 Lowest-Recall Classes", xlabel="Recall (%)", ylabel="Class ID", xlim=(0, 100))
    fig.suptitle("Class-level Error Analysis", fontsize=14, fontweight="bold")
    fig.tight_layout()
    fig.savefig(output, dpi=300)
    plt.close(fig)


def top_confusions(matrix: np.ndarray, count: int = 20) -> list[dict[str, Any]]:
    if matrix.ndim != 2 or matrix.shape[0] != matrix.shape[1]:
        raise ValueError(f"Expected a square confusion matrix, got {matrix.shape}")
    errors = matrix.copy().astype(np.int64)
    np.fill_diagonal(errors, 0)
    flat_indices = np.argsort(errors, axis=None)[::-1]
    rows: list[dict[str, Any]] = []
    for flat in flat_indices:
        actual_index, predicted_index = np.unravel_index(flat, errors.shape)
        value = int(errors[actual_index, predicted_index])
        if value <= 0 or len(rows) >= count:
            break
        actual_total = int(matrix[actual_index].sum())
        rows.append(
            {
                "actual_class_id": actual_index + 1,
                "predicted_class_id": predicted_index + 1,
                "error_count": value,
                "actual_class_support": actual_total,
                "percentage_of_actual_class": value / actual_total if actual_total else 0.0,
            }
        )
    return rows


def plot_top_confusions(rows: list[dict[str, Any]], output: Path) -> None:
    labels = [f"{row['actual_class_id']} -> {row['predicted_class_id']}" for row in rows]
    counts = [row["error_count"] for row in rows]
    fig, ax = plt.subplots(figsize=(9.2, 6.4))
    bars = ax.barh(labels[::-1], counts[::-1], color="#C51605")
    ax.set(title="Most Frequent Misclassification Pairs", xlabel="Test images misclassified", ylabel="Actual -> predicted class ID")
    ax.bar_label(bars, padding=3, fontsize=8)
    fig.savefig(output, dpi=300)
    plt.close(fig)


def plot_deployment(parity: dict[str, Any], device: dict[str, Any], output: Path) -> None:
    native = device["nativeInferenceMilliseconds"]
    end_to_end = device["endToEndMilliseconds"]
    labels = ["Native mean", "Native p95", "End-to-end mean", "End-to-end p95"]
    values = [native["mean"], native["p95"], end_to_end["mean"], end_to_end["p95"]]
    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    bars = ax.bar(labels, values, color=["#176B87", "#176B87", "#E36414", "#E36414"])
    ax.set(title="Android 14 Emulator Latency (30 Measured Runs)", ylabel="Milliseconds")
    ax.bar_label(bars, fmt="%.1f ms", padding=3)
    ax.text(
        0.01,
        -0.20,
        f"Keras-TFLite top-1 agreement: {100 * parity['top1Agreement']:.1f}% over {parity['samples']} samples. "
        "Emulator timing is technical evidence, not physical-device or child-study performance.",
        transform=ax.transAxes,
        fontsize=9,
        color="#555555",
        wrap=True,
    )
    fig.savefig(output, dpi=300)
    plt.close(fig)


def validate_pilot_export(payload: dict[str, Any]) -> list[dict[str, Any]]:
    if payload.get("schemaVersion") != "readbuddy-trace-evaluation-v1":
        raise ValueError("Unsupported pilot export schemaVersion")
    privacy = payload.get("privacy", {})
    if privacy.get("containsStudentIdentifier") is not False or privacy.get("containsRawTraceImage") is not False:
        raise ValueError("Pilot export must explicitly exclude student identifiers and raw trace images")
    records = payload.get("records")
    if not isinstance(records, list):
        raise ValueError("Pilot export records must be a list")
    forbidden = {"studentId", "studentName", "name", "rawImage", "image", "imagePath"}
    for record in records:
        if not isinstance(record, dict):
            raise ValueError("Every pilot record must be a JSON object")
        present = forbidden.intersection(record)
        if present:
            raise ValueError(f"Pilot record contains prohibited fields: {sorted(present)}")
    return records


def summarize_pilot(records: list[dict[str, Any]]) -> dict[str, Any]:
    total = len(records)
    correct = sum(bool(row.get("isCorrect")) for row in records)
    confidence_values = [float(row["confidence"]) for row in records if row.get("confidence") is not None]
    inference_values = [float(row["inferenceMilliseconds"]) for row in records if row.get("inferenceMilliseconds") is not None]
    letter_counts: dict[str, Counter[str]] = {}
    for row in records:
        expected = str(row.get("expectedLetter", "unknown"))
        predicted = str(row.get("predictedLabel", "unknown"))
        letter_counts.setdefault(expected, Counter())[predicted] += 1
    low, high = wilson_interval(correct, total)
    return {
        "status": "observed-deidentified-local-practice-data" if total else "pending-no-records",
        "scope": "technical pilot evidence; not a controlled child study",
        "totalAttempts": total,
        "correctAttempts": correct,
        "accuracy": correct / total if total else None,
        "accuracyWilson95CI": [low, high] if total else None,
        "meanConfidence": float(np.mean(confidence_values)) if confidence_values else None,
        "meanInferenceMilliseconds": float(np.mean(inference_values)) if inference_values else None,
        "confusionCounts": {expected: dict(counts) for expected, counts in sorted(letter_counts.items())},
    }


def write_pilot_template(path: Path) -> None:
    fields = [
        "session_code",
        "input_source",
        "device_type",
        "expected_letter",
        "predicted_label",
        "prediction_class_id",
        "confidence",
        "inference_ms",
        "is_correct",
        "model_version",
        "timestamp_utc",
        "notes_no_personal_data",
    ]
    example = {
        "session_code": "EXAMPLE-REMOVE-BEFORE-USE",
        "input_source": "synthetic",
        "device_type": "Android emulator",
        "expected_letter": "class-id-1",
        "predicted_label": "class-id-1",
        "prediction_class_id": 1,
        "confidence": 0.95,
        "inference_ms": 85.0,
        "is_correct": "TRUE",
        "model_version": "readbuddy-stage3-cnn-v4-ad082e94",
        "timestamp_utc": "2099-01-01T00:00:00Z",
        "notes_no_personal_data": "Example row only; delete it before collection.",
    }
    save_csv(path, fields, [example])


def write_report(path: Path, summary: dict[str, Any], output_dir: Path) -> None:
    model = summary["customModel"]
    control = summary["lowCapacityControl"]
    split = summary["dataset"]
    deployment = summary["deployment"]
    pilot = summary["pilotEvaluation"]
    ci = model["accuracyWilson95CI"]
    pilot_line = (
        f"A supplied de-identified export contained **{pilot['totalAttempts']} attempts**. "
        f"Its descriptive accuracy was **{100 * pilot['accuracy']:.2f}%**."
        if pilot.get("accuracy") is not None
        else "No pilot export was supplied. Participant/pilot outcomes therefore remain **pending** and are not fabricated."
    )
    text = f"""# ReadBuddy AI - Stage 6 Evaluation Report

Generated: {summary['generatedAt']}

## Verified model result

The custom CNN achieved **{100 * model['accuracy']:.2f}% held-out test accuracy** (95% Wilson CI: **{100 * ci[0]:.2f}% to {100 * ci[1]:.2f}%**) on **{model['testSamples']:,} images** from 454 classes. Macro-F1 was **{100 * model['macroF1']:.2f}%**, balanced accuracy was **{100 * model['balancedAccuracy']:.2f}%**, top-2 accuracy was **{100 * model['top2Accuracy']:.2f}%**, and top-3 accuracy was **{100 * model['top3Accuracy']:.2f}%**.

The low-capacity control obtained **{100 * control['accuracy']:.2f}%** accuracy. This is reported as a negative control that failed to learn effectively; it is not presented as a competitive literature baseline.

## Dataset integrity

- Original publisher paths: {split['originalPathCount']:,}
- Unique image hashes before conflict removal: {split['originalUniqueHashCount']:,}
- Publisher cross-split duplicate hashes detected: {split['publisherCrossSplitLeakageHashCount']:,}
- Cross-class conflict hashes quarantined: {split['crossClassConflictHashCount']:,}
- Excluded paths: {split['excludedPathCount']:,}
- Final deduplicated samples: {split['sampleCount']:,}
- Protected split: {split['splitCounts']['train']:,} train / {split['splitCounts']['validation']:,} validation / {split['splitCounts']['test']:,} test
- Strategy: `{split['splitStrategy']}` with seed {split['seed']}

## Deployment verification

The evaluated TFLite model hash is `{deployment['modelSha256']}`. It matches the training run, parity evaluation, bundled Flutter asset, and benchmark evidence. Keras-TFLite top-1 agreement was **{100 * deployment['top1Agreement']:.1f}%** over {deployment['paritySamples']} samples. On the Android 14 x86_64 emulator, mean native inference latency was **{deployment['nativeMeanMs']:.2f} ms** and p95 was **{deployment['nativeP95Ms']:.2f} ms** over 30 measured runs. These timings are not physical-device measurements.

## Pilot status

{pilot_line}

Child usability/effectiveness testing must not begin until supervisor approval and any required institutional ethics, school permission, parent/guardian consent, and child assent are documented. Adult or synthetic technical checks must also avoid names, student IDs, and raw trace images.

## Generated evidence files

- `model_performance_comparison.png`: held-out metric comparison
- `custom_cnn_training_history.png`: training and validation learning curves
- `per_class_recall_analysis.png`: class-level recall distribution and weakest classes
- `top_confusion_pairs.png`: most frequent directed errors
- `deployment_latency_and_parity.png`: emulator latency with conversion parity note
- `top_confusion_pairs.csv`: exact values behind the confusion figure
- `per_class_metrics.csv`: exact class-level precision, recall, F1 and support
- `pilot_data_template.csv`: de-identified adult/synthetic pilot template
- `evaluation_summary.json`: machine-readable consolidated evidence

## Interpretation limits

The held-out result measures classification performance on the protected image dataset. It does not establish classroom learning gains, usability for children, or generalisation to every phone, writing style, lighting condition, or camera. The current app-level tracing interface supports five mapped Sinhala letters (class IDs 1, 2, 12, 25 and 250); the model output layer contains 454 dataset classes. Any claims in a thesis or paper must keep dataset testing, emulator benchmarking, local practice evidence, and future child-study evidence separate.

## Reproduction

From the repository root:

```powershell
python tools\\generate_stage6_evaluation_report.py
```

To analyze a de-identified Stage 5 export:

```powershell
python tools\\generate_stage6_evaluation_report.py --pilot-export path\\to\\trace_export.json
```

Output directory: `{output_dir}`
"""
    path.write_text(text, encoding="utf-8")


def generate(args: argparse.Namespace) -> dict[str, Any]:
    results = args.results_dir.resolve()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)

    custom = read_json(results / "custom_cnn_metrics.json")
    control = read_json(results / "compact_cnn_baseline_metrics.json")
    history = read_json(results / "custom_cnn_history.json")
    parity = read_json(results / "keras_tflite_parity.json")
    manifest = read_json(results / "run_manifest.json")
    split = read_json(args.split_summary.resolve())
    device = read_json(args.device_benchmark.resolve())
    per_class = load_per_class(results / "custom_cnn_per_class.csv")
    confusion_matrix = np.load(results / "custom_cnn_confusion_matrix.npy", allow_pickle=False)

    if manifest.get("pipelineVersion") != EXPECTED_PIPELINE:
        raise ValueError(f"Unexpected pipeline: {manifest.get('pipelineVersion')}")
    if len(per_class) != 454 or confusion_matrix.shape != (454, 454):
        raise ValueError("Expected exactly 454 class rows and a 454 x 454 confusion matrix")
    if int(confusion_matrix.sum()) != int(custom["testSamples"]):
        raise ValueError("Confusion matrix sample count does not match metrics JSON")

    model_path = results / "sinhala_letter_model.tflite"
    actual_hash = sha256(model_path)
    expected_hashes = {
        str(manifest["tfliteSha256"]).lower(),
        str(parity["tfliteSha256"]).lower(),
        str(device["evidence"]["modelSha256"]).lower(),
        str(device["evidence"]["regularAppEmbeddedModelSha256"]).lower(),
    }
    if expected_hashes != {actual_hash}:
        raise ValueError(f"Model hash mismatch: artifact={actual_hash}, evidence={sorted(expected_hashes)}")

    errors = top_confusions(confusion_matrix)
    correct = int(np.trace(confusion_matrix))
    total = int(confusion_matrix.sum())
    ci_low, ci_high = wilson_interval(correct, total)
    custom_summary = dict(custom)
    custom_summary.update(
        {
            "correctPredictions": correct,
            "incorrectPredictions": total - correct,
            "accuracyWilson95CI": [ci_low, ci_high],
        }
    )

    pilot_summary: dict[str, Any] = {
        "status": "pending-no-export-supplied",
        "scope": "technical pilot evidence; not a controlled child study",
        "totalAttempts": 0,
        "correctAttempts": 0,
        "accuracy": None,
        "accuracyWilson95CI": None,
        "meanConfidence": None,
        "meanInferenceMilliseconds": None,
        "confusionCounts": {},
    }
    if args.pilot_export is not None:
        pilot_payload = read_json(args.pilot_export.resolve())
        pilot_summary = summarize_pilot(validate_pilot_export(pilot_payload))
        pilot_summary["sourceFile"] = str(args.pilot_export.resolve())

    summary = {
        "schemaVersion": "readbuddy-stage6-evaluation-v1",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "claimBoundary": "Dataset test evidence and technical deployment evidence only; child-study effectiveness is not established.",
        "customModel": custom_summary,
        "lowCapacityControl": control,
        "dataset": split,
        "deployment": {
            "pipelineVersion": manifest["pipelineVersion"],
            "modelSha256": actual_hash,
            "classNamesSha256": manifest["classNamesSha256"],
            "top1Agreement": parity["top1Agreement"],
            "paritySamples": parity["samples"],
            "nativeMeanMs": device["nativeInferenceMilliseconds"]["mean"],
            "nativeP50Ms": device["nativeInferenceMilliseconds"]["p50"],
            "nativeP95Ms": device["nativeInferenceMilliseconds"]["p95"],
            "endToEndMeanMs": device["endToEndMilliseconds"]["mean"],
            "endToEndP50Ms": device["endToEndMilliseconds"]["p50"],
            "endToEndP95Ms": device["endToEndMilliseconds"]["p95"],
            "runtimeScope": device["evidence"]["deviceScope"],
            "regularAppLaunchPassed": device["evidence"]["regularAppLaunchPassed"],
        },
        "pilotEvaluation": pilot_summary,
        "supportedAppLetterClassIds": [1, 2, 12, 25, 250],
        "sourceArtifacts": {
            "resultsDirectory": str(results),
            "splitSummary": str(args.split_summary.resolve()),
            "deviceBenchmark": str(args.device_benchmark.resolve()),
        },
    }

    configure_plot_style()
    plot_model_comparison(custom, control, output / "model_performance_comparison.png")
    plot_training_history(history, output / "custom_cnn_training_history.png")
    plot_per_class_recall(per_class, output / "per_class_recall_analysis.png")
    plot_top_confusions(errors, output / "top_confusion_pairs.png")
    plot_deployment(parity, device, output / "deployment_latency_and_parity.png")
    save_csv(
        output / "per_class_metrics.csv",
        ["class_id", "precision", "recall", "f1", "support"],
        per_class,
    )
    save_csv(
        output / "top_confusion_pairs.csv",
        ["actual_class_id", "predicted_class_id", "error_count", "actual_class_support", "percentage_of_actual_class"],
        errors,
    )
    write_pilot_template(output / "pilot_data_template.csv")
    with (output / "evaluation_summary.json").open("w", encoding="utf-8") as handle:
        json.dump(summary, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    write_report(output / "STAGE_6_EVALUATION_REPORT.md", summary, output)
    return summary


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS)
    parser.add_argument("--split-summary", type=Path, default=DEFAULT_SPLIT_SUMMARY)
    parser.add_argument("--device-benchmark", type=Path, default=DEFAULT_DEVICE_BENCHMARK)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--pilot-export", type=Path)
    return parser.parse_args()


if __name__ == "__main__":
    generated = generate(parse_args())
    model = generated["customModel"]
    deployment = generated["deployment"]
    print(f"Stage 6 package generated: {DEFAULT_OUTPUT}")
    print(f"Held-out accuracy: {100 * model['accuracy']:.2f}% ({model['testSamples']} samples)")
    print(f"Verified model SHA-256: {deployment['modelSha256']}")
    print(f"Pilot status: {generated['pilotEvaluation']['status']}")
