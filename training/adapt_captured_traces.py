"""Adapt the 455-class ReadBuddy CNN to consented in-app traces.

This is a deliberately conservative pilot adapter. It keeps the deployed
64x64x1 -> 455 contract, trains only captured samples whose original dataset
class ID is verified, and mixes a compact replay set from all 454 source
classes plus synthetic invalid marks to reduce catastrophic forgetting.

Captured samples from a single writer are training evidence, not an
independent test set. The script calls their score ``training fit`` and uses
the publisher-provided test split only for a regression check.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import random
import tempfile
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


IMAGE_SIZE = 64
LETTER_CLASS_COUNT = 454
CLASS_COUNT = 455
UNKNOWN_INDEX = 454
PIPELINE_VERSION = "readbuddy-captured-trace-adapter-v1"
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".bmp"}


def write_json(path: Path, value: object) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False),
        encoding="utf-8",
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def build_model(tf):
    inputs = tf.keras.Input((IMAGE_SIZE, IMAGE_SIZE, 1), name="image")
    value = tf.keras.layers.Conv2D(32, 3, activation="relu", name="conv_1")(inputs)
    value = tf.keras.layers.MaxPooling2D(2, name="pool_1")(value)
    value = tf.keras.layers.Conv2D(64, 3, activation="relu", name="conv_2")(value)
    value = tf.keras.layers.MaxPooling2D(2, name="pool_2")(value)
    value = tf.keras.layers.Conv2D(128, 3, activation="relu", name="conv_3")(value)
    value = tf.keras.layers.Flatten(name="flatten")(value)
    value = tf.keras.layers.Dense(128, activation="relu", name="dense_128")(value)
    value = tf.keras.layers.Dropout(0.30, name="dropout")(value)
    outputs = tf.keras.layers.Dense(
        CLASS_COUNT, activation="softmax", name="open_set_output"
    )(value)
    return tf.keras.Model(inputs, outputs, name="readbuddy_open_set_cnn")


def load_weights(model, checkpoint: Path) -> None:
    """Load numerical weights without relying on version-sensitive config."""
    if not zipfile.is_zipfile(checkpoint):
        model.load_weights(checkpoint)
        return
    with zipfile.ZipFile(checkpoint) as archive:
        weight_name = next(
            (name for name in archive.namelist() if name.endswith(".weights.h5")),
            None,
        )
        if weight_name is None:
            raise ValueError(f"No .weights.h5 payload exists in {checkpoint}")
        with tempfile.TemporaryDirectory() as temporary:
            archive.extract(weight_name, temporary)
            model.load_weights(Path(temporary) / weight_name)


def collect_replay(replay_dir: Path, split: str) -> tuple[list[Path], list[int]]:
    paths: list[Path] = []
    labels: list[int] = []
    root = replay_dir / split
    for class_id in range(1, LETTER_CLASS_COUNT + 1):
        class_dir = root / str(class_id)
        if not class_dir.is_dir():
            raise ValueError(f"Replay split is missing class {class_id}: {class_dir}")
        images = sorted(
            path
            for path in class_dir.iterdir()
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
        )
        if not images:
            raise ValueError(f"Replay class has no images: {class_dir}")
        paths.extend(images)
        labels.extend([class_id - 1] * len(images))
    return paths, labels


def collect_captured(captured_dir: Path) -> tuple[list[Path], list[int], dict]:
    manifest = captured_dir / "manifest.jsonl"
    if not manifest.is_file():
        raise ValueError(f"Captured manifest not found: {manifest}")
    mapped_paths: list[Path] = []
    mapped_labels: list[int] = []
    mapped_ids: list[str] = []
    ignored: list[dict] = []
    seen: set[str] = set()
    kinds: dict[str, int] = {}
    writers: set[str] = set()
    for line_number, line in enumerate(manifest.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        item = json.loads(line)
        sample_id = str(item.get("sampleId", ""))
        if not sample_id or sample_id in seen:
            raise ValueError(f"Invalid/duplicate sampleId at manifest line {line_number}")
        seen.add(sample_id)
        writers.add(str(item.get("writerId", "unknown")))
        kind = str(item.get("kind", "unknown"))
        kinds[kind] = kinds.get(kind, 0) + 1
        class_id = item.get("currentModelClassId")
        relative = Path(str(item.get("modelInputPath", "")))
        image_path = captured_dir / relative
        if class_id is None:
            ignored.append(
                {
                    "sampleId": sample_id,
                    "label": item.get("label"),
                    "kind": kind,
                    "reason": "no verified class ID in the deployed 455-class model",
                }
            )
            continue
        class_id = int(class_id)
        if not 1 <= class_id <= CLASS_COUNT:
            raise ValueError(f"Out-of-range class ID {class_id} for {sample_id}")
        if not image_path.is_file():
            raise ValueError(f"Captured model input is missing: {image_path}")
        mapped_paths.append(image_path)
        mapped_labels.append(class_id - 1)
        mapped_ids.append(sample_id)
    if len(mapped_paths) < 20:
        raise ValueError("At least 20 mapped app traces are required for this pilot.")
    audit = {
        "totalManifestSamples": len(seen),
        "mappedSamples": len(mapped_paths),
        "ignoredSamples": ignored,
        "writers": sorted(writers),
        "writerCount": len(writers),
        "kindCounts": kinds,
        "mappedSampleIds": mapped_ids,
    }
    return mapped_paths, mapped_labels, audit


def draw_invalid(path: Path, seed: int) -> None:
    rng = random.Random(seed)
    image = Image.new("L", (IMAGE_SIZE, IMAGE_SIZE), 0)
    draw = ImageDraw.Draw(image)
    width = rng.randint(3, 8)
    pattern = seed % 6
    if pattern == 0:
        points = [(rng.randint(5, 59), rng.randint(5, 59)) for _ in range(12)]
        draw.line(points, fill=255, width=width, joint="curve")
    elif pattern == 1:
        for _ in range(rng.randint(3, 7)):
            draw.line(
                [(rng.randint(4, 60), rng.randint(4, 60)) for _ in range(2)],
                fill=255,
                width=width,
            )
    elif pattern == 2:
        for radius in range(7, rng.randint(19, 27), 5):
            x, y = rng.randint(22, 42), rng.randint(22, 42)
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), outline=255, width=width)
    elif pattern == 3:
        x = rng.randint(8, 22)
        points = []
        for index in range(rng.randint(6, 11)):
            points.append((x if index % 2 == 0 else 64 - x, 5 + index * 5))
        draw.line(points, fill=255, width=width, joint="curve")
    elif pattern == 4:
        start = (rng.randint(15, 45), rng.randint(15, 45))
        end = (start[0] + rng.randint(-10, 10), start[1] + rng.randint(-10, 10))
        draw.line([start, end], fill=255, width=width)
    else:
        for _ in range(rng.randint(2, 5)):
            x, y, radius = rng.randint(10, 54), rng.randint(10, 54), rng.randint(4, 10)
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    image.save(path)


def generate_invalid(output: Path, seed: int, counts: dict[str, int]) -> dict[str, list[Path]]:
    result: dict[str, list[Path]] = {}
    cursor = seed * 10000
    for split, count in counts.items():
        split_dir = output / "generated_invalid" / split
        split_dir.mkdir(parents=True, exist_ok=True)
        result[split] = []
        for index in range(count):
            path = split_dir / f"invalid_{index:04d}.png"
            draw_invalid(path, cursor + index)
            result[split].append(path)
        cursor += count
    return result


def make_augmenter(tf, seed: int):
    return tf.keras.Sequential(
        [
            tf.keras.layers.RandomTranslation(0.08, 0.08, fill_mode="constant", seed=seed),
            tf.keras.layers.RandomRotation(0.055, fill_mode="constant", seed=seed + 1),
            tf.keras.layers.RandomZoom((-0.08, 0.10), (-0.08, 0.10), fill_mode="constant", seed=seed + 2),
        ],
        name="captured_trace_augmentation",
    )


def build_dataset(tf, paths, labels, augment_flags, batch_size, training, seed):
    augmenter = make_augmenter(tf, seed)
    dataset = tf.data.Dataset.from_tensor_slices(
        ([str(path) for path in paths], labels, augment_flags)
    )

    def load(path, label, should_augment):
        value = tf.io.decode_image(
            tf.io.read_file(path), channels=1, expand_animations=False
        )
        value.set_shape([None, None, 1])
        value = tf.image.resize(value, [IMAGE_SIZE, IMAGE_SIZE])
        value = tf.cast(value, tf.float32) / 255.0
        if training:
            value = tf.cond(
                should_augment,
                lambda: augmenter(value, training=True),
                lambda: value,
            )
        return value, tf.cast(label, tf.int64)

    if training:
        dataset = dataset.shuffle(len(paths), seed=seed, reshuffle_each_iteration=True)
    return dataset.map(load, num_parallel_calls=tf.data.AUTOTUNE).batch(batch_size).prefetch(tf.data.AUTOTUNE)


def evaluate(tf, model, dataset) -> dict[str, float | int]:
    probabilities = model.predict(dataset, verbose=0)
    labels = np.concatenate([label.numpy() for _, label in dataset])
    predictions = probabilities.argmax(axis=1)
    top3 = np.argpartition(probabilities, -3, axis=1)[:, -3:]
    return {
        "samples": int(len(labels)),
        "accuracy": float(np.mean(predictions == labels)),
        "top3Accuracy": float(np.mean(np.any(top3 == labels[:, None], axis=1))),
        "meanConfidence": float(np.mean(probabilities.max(axis=1))),
        "meanExpectedClassProbability": float(np.mean(probabilities[np.arange(len(labels)), labels])),
    }


def parity(tf, model, tflite_bytes: bytes, dataset) -> dict[str, float | int | list[int]]:
    interpreter = tf.lite.Interpreter(model_content=tflite_bytes)
    interpreter.allocate_tensors()
    input_detail = interpreter.get_input_details()[0]
    output_detail = interpreter.get_output_details()[0]
    agreements: list[bool] = []
    differences: list[float] = []
    for images, _ in dataset:
        for image in images.numpy():
            sample = image[np.newaxis, ...].astype(np.float32)
            keras_output = model(sample, training=False).numpy()[0]
            interpreter.set_tensor(input_detail["index"], sample)
            interpreter.invoke()
            lite_output = interpreter.get_tensor(output_detail["index"])[0]
            agreements.append(int(np.argmax(keras_output)) == int(np.argmax(lite_output)))
            differences.append(float(np.max(np.abs(keras_output - lite_output))))
            if len(agreements) >= 100:
                return {
                    "samples": len(agreements),
                    "top1Agreement": float(np.mean(agreements)),
                    "maximumAbsoluteProbabilityDifference": float(max(differences)),
                    "inputShape": input_detail["shape"].tolist(),
                    "outputShape": output_detail["shape"].tolist(),
                }
    raise ValueError("Parity dataset was empty.")


def run(args) -> None:
    import tensorflow as tf

    random.seed(args.seed)
    np.random.seed(args.seed)
    tf.keras.utils.set_random_seed(args.seed)
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    captured_dir = Path(args.captured_dir).resolve()
    replay_dir = Path(args.replay_dir).resolve()
    checkpoint = Path(args.base_model).resolve()

    captured_paths, captured_labels, capture_audit = collect_captured(captured_dir)
    train_replay_paths, train_replay_labels = collect_replay(replay_dir, "train")
    valid_paths, valid_labels = collect_replay(replay_dir, "valid")
    test_paths, test_labels = collect_replay(replay_dir, "test")
    invalid = generate_invalid(
        output,
        args.seed,
        {"train": args.invalid_train, "valid": args.invalid_valid, "test": args.invalid_test},
    )

    train_paths = list(train_replay_paths)
    train_labels = list(train_replay_labels)
    train_augment = [False] * len(train_paths)
    for _ in range(args.capture_repeats):
        train_paths.extend(captured_paths)
        train_labels.extend(captured_labels)
        train_augment.extend([True] * len(captured_paths))
    train_paths.extend(invalid["train"])
    train_labels.extend([UNKNOWN_INDEX] * len(invalid["train"]))
    train_augment.extend([False] * len(invalid["train"]))

    valid_paths.extend(invalid["valid"])
    valid_labels.extend([UNKNOWN_INDEX] * len(invalid["valid"]))
    test_paths.extend(invalid["test"])
    test_labels.extend([UNKNOWN_INDEX] * len(invalid["test"]))

    train_ds = build_dataset(
        tf, train_paths, train_labels, train_augment, args.batch_size, True, args.seed
    )
    valid_ds = build_dataset(
        tf, valid_paths, valid_labels, [False] * len(valid_paths), args.batch_size, False, args.seed
    )
    test_ds = build_dataset(
        tf, test_paths, test_labels, [False] * len(test_paths), args.batch_size, False, args.seed
    )
    captured_ds = build_dataset(
        tf,
        captured_paths,
        captured_labels,
        [False] * len(captured_paths),
        args.batch_size,
        False,
        args.seed,
    )

    model = build_model(tf)
    load_weights(model, checkpoint)
    before = {
        "validationReplay": evaluate(tf, model, valid_ds),
        "heldOutReplay": evaluate(tf, model, test_ds),
        "capturedTrainingFit": evaluate(tf, model, captured_ds),
    }

    # App traces differ from the source dataset in stroke width and rendering,
    # so the middle/high-level feature extractors must be allowed to adapt.
    # conv_1 remains frozen to preserve generic edge filters.
    trainable = {
        "conv_2",
        "conv_3",
        "dense_128",
        "dropout",
        "open_set_output",
    }
    for layer in model.layers:
        layer.trainable = layer.name in trainable
    model.compile(
        optimizer=tf.keras.optimizers.Adam(args.learning_rate),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    # A conventional val-loss early stop selected the source-domain model and
    # stopped before app traces improved. Select checkpoints using both the
    # original validation replay and captured training fit instead. The held-
    # out test split remains untouched until the selected checkpoint is fixed.
    baseline_validation_accuracy = before["validationReplay"]["accuracy"]
    best_weights = [value.copy() for value in model.get_weights()]
    best_capture_score = (
        before["capturedTrainingFit"]["accuracy"],
        before["capturedTrainingFit"]["meanExpectedClassProbability"],
    )
    best_epoch = 0
    epochs_without_improvement = 0
    epoch_records: list[dict] = []
    for epoch in range(1, args.epochs + 1):
        fit = model.fit(train_ds, epochs=1, verbose=2)
        validation_metrics = evaluate(tf, model, valid_ds)
        capture_metrics = evaluate(tf, model, captured_ds)
        validation_drop = (
            baseline_validation_accuracy - validation_metrics["accuracy"]
        )
        capture_score = (
            capture_metrics["accuracy"],
            capture_metrics["meanExpectedClassProbability"],
        )
        eligible = validation_drop <= args.maximum_regression_drop
        improved = eligible and capture_score > best_capture_score
        if improved:
            best_weights = [value.copy() for value in model.get_weights()]
            best_capture_score = capture_score
            best_epoch = epoch
            epochs_without_improvement = 0
        else:
            epochs_without_improvement += 1
        epoch_records.append(
            {
                "epoch": epoch,
                "trainLoss": float(fit.history["loss"][-1]),
                "trainAccuracy": float(fit.history["accuracy"][-1]),
                "validationAccuracy": validation_metrics["accuracy"],
                "validationDrop": float(validation_drop),
                "capturedFitAccuracy": capture_metrics["accuracy"],
                "capturedExpectedProbability": capture_metrics[
                    "meanExpectedClassProbability"
                ],
                "eligible": bool(eligible),
                "selectedAtThisEpoch": bool(improved),
            }
        )
        print(json.dumps(epoch_records[-1], indent=2))
        if epoch >= args.minimum_epochs and epochs_without_improvement >= args.patience:
            break
    model.set_weights(best_weights)
    with (output / "adapter_epoch_log.csv").open(
        "w", newline="", encoding="utf-8"
    ) as stream:
        writer = csv.DictWriter(stream, fieldnames=list(epoch_records[0]))
        writer.writeheader()
        writer.writerows(epoch_records)

    after = {
        "validationReplay": evaluate(tf, model, valid_ds),
        "heldOutReplay": evaluate(tf, model, test_ds),
        "capturedTrainingFit": evaluate(tf, model, captured_ds),
    }
    regression_drop = (
        before["heldOutReplay"]["accuracy"] - after["heldOutReplay"]["accuracy"]
    )
    deployment_pass = (
        regression_drop <= args.maximum_regression_drop
        and after["capturedTrainingFit"]["accuracy"] >= args.minimum_capture_fit
    )

    model.save(output / "captured_adapter.keras")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()
    tflite_path = output / "sinhala_letter_captured_adapter.tflite"
    tflite_path.write_bytes(tflite_bytes)
    (output / "class_names.txt").write_text(
        "\n".join(str(value) for value in range(1, CLASS_COUNT + 1)) + "\n",
        encoding="utf-8",
    )
    parity_result = parity(tf, model, tflite_bytes, test_ds)

    report = {
        "pipelineVersion": PIPELINE_VERSION,
        "warning": "Captured samples are from one writer and are not an independent test set.",
        "captureAudit": capture_audit,
        "before": before,
        "after": after,
        "heldOutAccuracyDrop": float(regression_drop),
        "deploymentGatePassed": bool(deployment_pass),
        "deploymentGate": {
            "maximumRegressionDrop": args.maximum_regression_drop,
            "minimumCapturedTrainingFit": args.minimum_capture_fit,
        },
        "splitCounts": {
            "trainRowsAfterRepeating": len(train_paths),
            "validation": len(valid_paths),
            "heldOutTest": len(test_paths),
            "uniqueMappedCaptured": len(captured_paths),
        },
        "checkpointSelection": {
            "bestEpoch": best_epoch,
            "epochsRun": len(epoch_records),
            "selectionRule": "maximize captured fit while validation replay accuracy drop <= gate",
            "epochs": epoch_records,
        },
        "tfliteParity": parity_result,
        "baseModelSha256": sha256_file(checkpoint),
        "tfliteSha256": sha256_file(tflite_path),
        "tensorflow": tf.__version__,
        "numpy": np.__version__,
        "arguments": vars(args),
    }
    write_json(output / "captured_adapter_report.json", report)
    status = "PASSED" if deployment_pass else "FAILED"
    (output / "MODEL_CARD.md").write_text(
        "# ReadBuddy Captured-Trace Adapter (Pilot)\n\n"
        f"Deployment gate: **{status}**\n\n"
        "This pilot keeps the deployed 455-class contract and adapts verified "
        "classes to consented in-app traces. Captured training fit is not test "
        "accuracy because the captured data contains only one writer. Review "
        "`captured_adapter_report.json` before replacing the app asset.\n",
        encoding="utf-8",
    )
    print(json.dumps(report, indent=2, ensure_ascii=False))


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser()
    value.add_argument("--captured-dir", required=True)
    value.add_argument("--replay-dir", required=True)
    value.add_argument("--base-model", required=True)
    value.add_argument("--output-dir", default="/content/readbuddy_adapter_output")
    value.add_argument("--seed", type=int, default=42)
    value.add_argument("--batch-size", type=int, default=32)
    value.add_argument("--epochs", type=int, default=18)
    value.add_argument("--minimum-epochs", type=int, default=8)
    value.add_argument("--patience", type=int, default=6)
    value.add_argument("--learning-rate", type=float, default=0.00005)
    value.add_argument("--capture-repeats", type=int, default=60)
    value.add_argument("--invalid-train", type=int, default=500)
    value.add_argument("--invalid-valid", type=int, default=100)
    value.add_argument("--invalid-test", type=int, default=200)
    value.add_argument("--maximum-regression-drop", type=float, default=0.04)
    value.add_argument("--minimum-capture-fit", type=float, default=0.70)
    return value


if __name__ == "__main__":
    run(parser().parse_args())
