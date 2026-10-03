"""Reproducible training/evaluation pipeline for ReadBuddy's shipped CNN shape.

This script deliberately separates split creation from model training. Run
`--prepare-only` first, review and freeze split_manifest.csv, then train using
that same manifest. It expects numeric class folders (1..454) from the
Sinhala Letter 454 dataset and never infers Unicode order from folder sorting.

Designed for Python 3.10/3.11 in Google Colab's free runtime. TensorFlow and
scikit-learn are imported only after dataset auditing so `--help` and
`--prepare-only` remain usable in lighter environments.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import random
import statistics
import sys
import time
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence


IMAGE_SUFFIXES = {".bmp", ".jpeg", ".jpg", ".png", ".webp"}
EXPECTED_CLASS_COUNT = 454
IMAGE_SIZE = 64
SPLIT_NAMES = ("train", "validation", "test")
PIPELINE_VERSION = "readbuddy-stage3-cnn-v4"


@dataclass(frozen=True)
class Sample:
    relative_path: str
    class_id: int
    sha256: str
    split: str = ""


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def discover_samples(dataset_dir: Path) -> list[Sample]:
    if not dataset_dir.is_dir():
        raise FileNotFoundError(f"Dataset directory does not exist: {dataset_dir}")

    candidates: list[tuple[Path, int]] = []
    invalid_folders: list[str] = []
    for class_dir in sorted(path for path in dataset_dir.iterdir() if path.is_dir()):
        try:
            class_id = int(class_dir.name)
        except ValueError:
            invalid_folders.append(class_dir.name)
            continue
        if not 1 <= class_id <= EXPECTED_CLASS_COUNT:
            raise ValueError(f"Class folder is outside 1..454: {class_dir}")
        candidates.extend(
            (image_path, class_id)
            for image_path in sorted(class_dir.rglob("*"))
            if image_path.is_file() and image_path.suffix.lower() in IMAGE_SUFFIXES
        )

    if invalid_folders:
        raise ValueError(
            "Dataset root contains non-numeric class folders: "
            + ", ".join(invalid_folders[:10])
        )
    if not candidates:
        raise ValueError(f"No supported images found under {dataset_dir}")

    # map() preserves candidate ordering, so the manifest remains deterministic.
    # Concurrent reads substantially reduce Windows overhead for 100k tiny JPEGs.
    from concurrent.futures import ThreadPoolExecutor

    worker_count = min(16, max(4, os.cpu_count() or 4))
    with ThreadPoolExecutor(max_workers=worker_count) as executor:
        digests = executor.map(sha256_file, (path for path, _ in candidates))
        return [
            Sample(
                relative_path=image_path.relative_to(dataset_dir).as_posix(),
                class_id=class_id,
                sha256=digest,
            )
            for (image_path, class_id), digest in zip(candidates, digests)
        ]


def _allocate_group_splits(group_count: int) -> list[str]:
    if group_count < 3:
        raise ValueError(
            "Every class needs at least three unique-image groups for a "
            "non-overlapping train/validation/test split."
        )
    validation_count = max(1, round(group_count * 0.15))
    test_count = max(1, round(group_count * 0.15))
    train_count = group_count - validation_count - test_count
    while train_count < 1:
        if validation_count > test_count and validation_count > 1:
            validation_count -= 1
        elif test_count > 1:
            test_count -= 1
        else:
            raise ValueError("Could not allocate non-empty stratified splits.")
        train_count = group_count - validation_count - test_count
    return (
        ["train"] * train_count
        + ["validation"] * validation_count
        + ["test"] * test_count
    )


def create_split_manifest(
    dataset_dir: Path,
    manifest_path: Path,
    seed: int,
    allow_subset: bool,
) -> dict[str, object]:
    samples = discover_samples(dataset_dir)
    by_hash_classes: dict[str, set[int]] = defaultdict(set)
    for sample in samples:
        by_hash_classes[sample.sha256].add(sample.class_id)
    cross_class_duplicates = {
        digest: sorted(class_ids)
        for digest, class_ids in by_hash_classes.items()
        if len(class_ids) > 1
    }
    if cross_class_duplicates:
        example = next(iter(cross_class_duplicates.items()))
        raise ValueError(
            "Identical image bytes occur under different class IDs; resolve "
            f"label conflict before splitting. Example: {example}"
        )

    by_class: dict[int, list[Sample]] = defaultdict(list)
    for sample in samples:
        by_class[sample.class_id].append(sample)
    class_ids = sorted(by_class)
    if not allow_subset and class_ids != list(range(1, EXPECTED_CLASS_COUNT + 1)):
        missing = sorted(set(range(1, EXPECTED_CLASS_COUNT + 1)) - set(class_ids))
        raise ValueError(
            f"Expected all 454 numeric classes; found {len(class_ids)}. "
            f"First missing IDs: {missing[:20]}. Use --allow-subset only for "
            "an explicitly labelled pilot experiment."
        )

    assigned: list[Sample] = []
    unique_groups_per_class: dict[int, int] = {}
    for class_id in class_ids:
        groups: dict[str, list[Sample]] = defaultdict(list)
        for sample in by_class[class_id]:
            groups[sample.sha256].append(sample)
        ordered_groups = sorted(groups.items())
        random.Random(f"{seed}:{class_id}").shuffle(ordered_groups)
        split_labels = _allocate_group_splits(len(ordered_groups))
        unique_groups_per_class[class_id] = len(ordered_groups)
        for (_, duplicate_group), split in zip(ordered_groups, split_labels):
            assigned.extend(
                Sample(sample.relative_path, sample.class_id, sample.sha256, split)
                for sample in duplicate_group
            )

    assigned.sort(key=lambda sample: (sample.split, sample.class_id, sample.relative_path))
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with manifest_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=("relative_path", "class_id", "sha256", "split"),
        )
        writer.writeheader()
        writer.writerows(asdict(sample) for sample in assigned)

    manifest_hash = sha256_file(manifest_path)
    split_counts = {
        split: sum(sample.split == split for sample in assigned)
        for split in SPLIT_NAMES
    }
    duplicate_paths = len(assigned) - len({sample.sha256 for sample in assigned})
    summary = {
        "pipelineVersion": PIPELINE_VERSION,
        "seed": seed,
        "datasetDirectory": str(dataset_dir.resolve()),
        "manifest": str(manifest_path.resolve()),
        "manifestSha256": manifest_hash,
        "sampleCount": len(assigned),
        "uniqueImageCount": len({sample.sha256 for sample in assigned}),
        "duplicatePathCount": duplicate_paths,
        "classCount": len(class_ids),
        "classIds": class_ids,
        "splitCounts": split_counts,
        "minimumUniqueGroupsPerClass": min(unique_groups_per_class.values()),
        "maximumUniqueGroupsPerClass": max(unique_groups_per_class.values()),
    }
    write_json(manifest_path.with_suffix(".summary.json"), summary)
    return summary


def create_provided_split_manifest(
    dataset_dir: Path,
    manifest_path: Path,
    seed: int,
    allow_subset: bool,
    quarantine_conflicts: bool = False,
) -> dict[str, object]:
    """Freeze publisher-provided train/valid/test directories without reshuffling."""
    source_directories = {
        "train": "train",
        "validation": "valid" if (dataset_dir / "valid").is_dir() else "validation",
        "test": "test",
    }
    assigned: list[Sample] = []
    expected_ids = list(range(1, EXPECTED_CLASS_COUNT + 1))
    for split, source_name in source_directories.items():
        source_dir = dataset_dir / source_name
        discovered = discover_samples(source_dir)
        class_ids = sorted({sample.class_id for sample in discovered})
        if not allow_subset and class_ids != expected_ids:
            missing = sorted(set(expected_ids) - set(class_ids))
            raise ValueError(
                f"Publisher {source_name} split has {len(class_ids)} classes; "
                f"first missing IDs: {missing[:20]}."
            )
        assigned.extend(
            Sample(
                relative_path=f"{source_name}/{sample.relative_path}",
                class_id=sample.class_id,
                sha256=sample.sha256,
                split=split,
            )
            for sample in discovered
        )

    by_hash_classes: dict[str, set[int]] = defaultdict(set)
    by_hash_splits: dict[str, set[str]] = defaultdict(set)
    for sample in assigned:
        by_hash_classes[sample.sha256].add(sample.class_id)
        by_hash_splits[sample.sha256].add(sample.split)
    conflicts = {
        digest: sorted(class_ids)
        for digest, class_ids in by_hash_classes.items()
        if len(class_ids) > 1
    }
    leaked = {
        digest: sorted(splits)
        for digest, splits in by_hash_splits.items()
        if len(splits) > 1
    }
    quarantined_hashes = set(conflicts) | set(leaked)
    if quarantined_hashes and not quarantine_conflicts:
        example_hash = sorted(quarantined_hashes)[0]
        raise ValueError(
            "Dataset contains ambiguous or cross-split duplicate images: "
            f"{len(conflicts)} cross-class hashes and {len(leaked)} cross-split "
            "hashes. Re-run with --quarantine-conflicts to exclude every path "
            f"for those hashes. Example: {example_hash}"
        )

    original_sample_count = len(assigned)
    exclusions = [sample for sample in assigned if sample.sha256 in quarantined_hashes]
    exclusions_path = manifest_path.with_suffix(".exclusions.csv")
    if exclusions:
        exclusions_path.parent.mkdir(parents=True, exist_ok=True)
        with exclusions_path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.writer(stream)
            writer.writerow(
                ["relative_path", "class_id", "sha256", "split", "reason"]
            )
            for sample in sorted(
                exclusions,
                key=lambda row: (row.sha256, row.split, row.class_id, row.relative_path),
            ):
                reasons = []
                if sample.sha256 in conflicts:
                    reasons.append("identical-bytes-cross-class-label-conflict")
                if sample.sha256 in leaked:
                    reasons.append("identical-bytes-cross-split-leakage")
                writer.writerow(
                    [
                        sample.relative_path,
                        sample.class_id,
                        sample.sha256,
                        sample.split,
                        "+".join(reasons),
                    ]
                )
        assigned = [
            sample for sample in assigned if sample.sha256 not in quarantined_hashes
        ]

    expected_class_set = set(expected_ids)
    for split in SPLIT_NAMES:
        split_classes = {
            sample.class_id for sample in assigned if sample.split == split
        }
        if not split_classes:
            raise ValueError(f"No samples remain in {split} after quarantine.")
        if not allow_subset and split_classes != expected_class_set:
            missing = sorted(expected_class_set - split_classes)
            raise ValueError(
                f"Quarantine removed all {split} samples for classes: {missing[:20]}"
            )

    assigned.sort(key=lambda sample: (sample.split, sample.class_id, sample.relative_path))
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with manifest_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=("relative_path", "class_id", "sha256", "split"),
        )
        writer.writeheader()
        writer.writerows(asdict(sample) for sample in assigned)

    class_ids = sorted({sample.class_id for sample in assigned})
    summary = {
        "pipelineVersion": PIPELINE_VERSION,
        "splitStrategy": "publisher-provided-train-valid-test",
        "sourceDirectories": source_directories,
        "seed": seed,
        "seedUsedForSplit": False,
        "datasetDirectory": str(dataset_dir.resolve()),
        "manifest": str(manifest_path.resolve()),
        "manifestSha256": sha256_file(manifest_path),
        "originalSampleCount": original_sample_count,
        "sampleCount": len(assigned),
        "uniqueImageCount": len({sample.sha256 for sample in assigned}),
        "duplicatePathCount": len(assigned)
        - len({sample.sha256 for sample in assigned}),
        "excludedPathCount": len(exclusions),
        "excludedUniqueHashCount": len(quarantined_hashes),
        "crossClassConflictHashCount": len(conflicts),
        "crossSplitLeakageHashCount": len(leaked),
        "exclusions": str(exclusions_path.resolve()) if exclusions else None,
        "exclusionsSha256": sha256_file(exclusions_path) if exclusions else None,
        "classCount": len(class_ids),
        "classIds": class_ids,
        "splitCounts": {
            split: sum(sample.split == split for sample in assigned)
            for split in SPLIT_NAMES
        },
    }
    write_json(manifest_path.with_suffix(".summary.json"), summary)
    return summary


def create_regrouped_manifest_from_provided_splits(
    dataset_dir: Path,
    manifest_path: Path,
    seed: int,
    allow_subset: bool,
    quarantine_conflicts: bool,
) -> dict[str, object]:
    """Deduplicate and regroup a contaminated publisher split by image hash."""
    source_directories = ("train", "valid", "test")
    discovered_all: list[Sample] = []
    for source_name in source_directories:
        for sample in discover_samples(dataset_dir / source_name):
            discovered_all.append(
                Sample(
                    relative_path=f"{source_name}/{sample.relative_path}",
                    class_id=sample.class_id,
                    sha256=sample.sha256,
                    split=source_name,
                )
            )

    by_hash: dict[str, list[Sample]] = defaultdict(list)
    for sample in discovered_all:
        by_hash[sample.sha256].append(sample)
    conflict_hashes = {
        digest
        for digest, rows in by_hash.items()
        if len({row.class_id for row in rows}) > 1
    }
    publisher_leakage_hashes = {
        digest
        for digest, rows in by_hash.items()
        if len({row.split for row in rows}) > 1
    }
    if conflict_hashes and not quarantine_conflicts:
        raise ValueError(
            f"Found {len(conflict_hashes)} cross-class hash conflicts. "
            "Use --quarantine-conflicts to exclude them with an audit trail."
        )

    representatives: list[Sample] = []
    exclusions: list[tuple[Sample, str]] = []
    for digest, rows in sorted(by_hash.items()):
        ordered = sorted(
            rows, key=lambda row: (row.relative_path, row.class_id, row.split)
        )
        if digest in conflict_hashes:
            exclusions.extend(
                (row, "identical-bytes-cross-class-label-conflict")
                for row in ordered
            )
            continue
        representatives.append(ordered[0])
        exclusions.extend(
            (row, "identical-bytes-duplicate-path-deduplication")
            for row in ordered[1:]
        )

    by_class: dict[int, list[Sample]] = defaultdict(list)
    for sample in representatives:
        by_class[sample.class_id].append(sample)
    class_ids = sorted(by_class)
    expected_ids = list(range(1, EXPECTED_CLASS_COUNT + 1))
    if not allow_subset and class_ids != expected_ids:
        missing = sorted(set(expected_ids) - set(class_ids))
        raise ValueError(
            f"After conflict quarantine, {len(class_ids)} classes remain; "
            f"first missing IDs: {missing[:20]}."
        )

    assigned: list[Sample] = []
    unique_images_per_class: dict[int, int] = {}
    for class_id in class_ids:
        rows = sorted(by_class[class_id], key=lambda row: row.sha256)
        random.Random(f"{seed}:{class_id}:regrouped").shuffle(rows)
        split_labels = _allocate_group_splits(len(rows))
        unique_images_per_class[class_id] = len(rows)
        assigned.extend(
            Sample(row.relative_path, row.class_id, row.sha256, split)
            for row, split in zip(rows, split_labels)
        )

    assigned.sort(key=lambda row: (row.split, row.class_id, row.relative_path))
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with manifest_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=("relative_path", "class_id", "sha256", "split"),
        )
        writer.writeheader()
        writer.writerows(asdict(sample) for sample in assigned)

    exclusions_path = manifest_path.with_suffix(".exclusions.csv")
    with exclusions_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["relative_path", "class_id", "sha256", "source_split", "reason"])
        for sample, reason in sorted(
            exclusions,
            key=lambda item: (
                item[0].sha256,
                item[0].split,
                item[0].class_id,
                item[0].relative_path,
            ),
        ):
            writer.writerow(
                [
                    sample.relative_path,
                    sample.class_id,
                    sample.sha256,
                    sample.split,
                    reason,
                ]
            )

    summary = {
        "pipelineVersion": PIPELINE_VERSION,
        "splitStrategy": "hash-deduplicated-stratified-70-15-15-after-publisher-leakage",
        "publisherSourceDirectories": list(source_directories),
        "seed": seed,
        "seedUsedForSplit": True,
        "datasetDirectory": str(dataset_dir.resolve()),
        "manifest": str(manifest_path.resolve()),
        "manifestSha256": sha256_file(manifest_path),
        "exclusions": str(exclusions_path.resolve()),
        "exclusionsSha256": sha256_file(exclusions_path),
        "originalPathCount": len(discovered_all),
        "originalUniqueHashCount": len(by_hash),
        "sampleCount": len(assigned),
        "excludedPathCount": len(exclusions),
        "crossClassConflictHashCount": len(conflict_hashes),
        "publisherCrossSplitLeakageHashCount": len(publisher_leakage_hashes),
        "classCount": len(class_ids),
        "classIds": class_ids,
        "splitCounts": {
            split: sum(row.split == split for row in assigned)
            for split in SPLIT_NAMES
        },
        "minimumUniqueImagesPerClass": min(unique_images_per_class.values()),
        "maximumUniqueImagesPerClass": max(unique_images_per_class.values()),
    }
    write_json(manifest_path.with_suffix(".summary.json"), summary)
    return summary


def load_and_verify_manifest(dataset_dir: Path, manifest_path: Path) -> list[Sample]:
    samples: list[Sample] = []
    absolute_paths: list[Path] = []
    with manifest_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            sample = Sample(
                relative_path=row["relative_path"],
                class_id=int(row["class_id"]),
                sha256=row["sha256"],
                split=row["split"],
            )
            if sample.split not in SPLIT_NAMES:
                raise ValueError(f"Invalid split in manifest: {sample.split}")
            absolute_path = dataset_dir / sample.relative_path
            if not absolute_path.is_file():
                raise FileNotFoundError(f"Manifest file is missing: {absolute_path}")
            samples.append(sample)
            absolute_paths.append(absolute_path)

    if not samples:
        raise ValueError("Split manifest is empty.")
    from concurrent.futures import ThreadPoolExecutor

    worker_count = min(16, max(4, os.cpu_count() or 4))
    with ThreadPoolExecutor(max_workers=worker_count) as executor:
        actual_hashes = executor.map(sha256_file, absolute_paths)
        for sample, absolute_path, actual_hash in zip(
            samples, absolute_paths, actual_hashes
        ):
            if actual_hash != sample.sha256:
                raise ValueError(
                    f"Dataset file changed after split freeze: {absolute_path}"
                )

    hash_to_splits: dict[str, set[str]] = defaultdict(set)
    for sample in samples:
        hash_to_splits[sample.sha256].add(sample.split)
    leaked = {
        digest: splits
        for digest, splits in hash_to_splits.items()
        if len(splits) > 1
    }
    if leaked:
        raise ValueError(f"Duplicate-image leakage across splits: {len(leaked)} hashes")
    for split in SPLIT_NAMES:
        if not any(sample.split == split for sample in samples):
            raise ValueError(f"Manifest has no {split} samples.")
    return samples


def configure_determinism(seed: int):
    os.environ.setdefault("PYTHONHASHSEED", str(seed))
    os.environ.setdefault("TF_DETERMINISTIC_OPS", "1")
    import numpy as np
    import tensorflow as tf

    random.seed(seed)
    np.random.seed(seed)
    tf.keras.utils.set_random_seed(seed)
    try:
        tf.config.experimental.enable_op_determinism()
    except Exception:
        pass
    return np, tf


def build_dataset(
    tf,
    dataset_dir: Path,
    samples: Sequence[Sample],
    class_to_index: dict[int, int],
    split: str,
    batch_size: int,
    training: bool,
    seed: int,
):
    selected = [sample for sample in samples if sample.split == split]
    paths = [str(dataset_dir / sample.relative_path) for sample in selected]
    labels = [class_to_index[sample.class_id] for sample in selected]
    dataset = tf.data.Dataset.from_tensor_slices((paths, labels))

    def decode(path, label):
        image = tf.io.decode_image(
            tf.io.read_file(path), channels=1, expand_animations=False
        )
        image.set_shape([None, None, 1])
        image = tf.image.resize(image, [IMAGE_SIZE, IMAGE_SIZE], antialias=True)
        image = tf.cast(image, tf.float32) / 255.0
        return image, label

    dataset = dataset.map(decode, num_parallel_calls=tf.data.AUTOTUNE, deterministic=True)
    if training:
        dataset = dataset.shuffle(
            min(len(selected), 10000), seed=seed, reshuffle_each_iteration=True
        )
    return dataset.batch(batch_size).prefetch(tf.data.AUTOTUNE)


def build_custom_cnn(tf, num_classes: int, dropout: float):
    # Layer dimensions recovered from the shipped TFLite FlatBuffer:
    # 64x64x1 -> Conv32 -> Pool -> Conv64 -> Pool -> Conv128 ->
    # Flatten(18432) -> Dense128 -> Dense454 -> Softmax.
    return tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 1), name="image"),
            tf.keras.layers.Conv2D(32, 3, activation="relu", name="conv_1"),
            tf.keras.layers.MaxPooling2D(2, name="pool_1"),
            tf.keras.layers.Conv2D(64, 3, activation="relu", name="conv_2"),
            tf.keras.layers.MaxPooling2D(2, name="pool_2"),
            tf.keras.layers.Conv2D(128, 3, activation="relu", name="conv_3"),
            tf.keras.layers.Flatten(name="flatten"),
            tf.keras.layers.Dense(128, activation="relu", name="dense_128"),
            tf.keras.layers.Dropout(dropout, name="dropout"),
            tf.keras.layers.Dense(num_classes, activation="softmax", name="class_output"),
        ],
        name="readbuddy_custom_cnn",
    )


def build_baseline(tf, num_classes: int):
    # A deliberately simple, low-cost baseline trained on the identical split.
    return tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 1), name="image"),
            tf.keras.layers.Conv2D(16, 5, activation="relu", name="baseline_conv"),
            tf.keras.layers.MaxPooling2D(4, name="baseline_pool"),
            tf.keras.layers.GlobalAveragePooling2D(name="baseline_gap"),
            tf.keras.layers.Dense(num_classes, activation="softmax", name="class_output"),
        ],
        name="compact_cnn_baseline",
    )


def expected_calibration_error(np, y_true, probabilities, bins: int = 10) -> float:
    confidence = probabilities.max(axis=1)
    predicted = probabilities.argmax(axis=1)
    correct = (predicted == y_true).astype(float)
    edges = np.linspace(0.0, 1.0, bins + 1)
    ece = 0.0
    for lower, upper in zip(edges[:-1], edges[1:]):
        mask = (confidence > lower) & (confidence <= upper)
        if mask.any():
            ece += mask.mean() * abs(correct[mask].mean() - confidence[mask].mean())
    return float(ece)


def save_calibration_plot(np, plt, y_true, probabilities, output_path: Path) -> None:
    confidence = probabilities.max(axis=1)
    correct = (probabilities.argmax(axis=1) == y_true).astype(float)
    edges = np.linspace(0.0, 1.0, 11)
    centers, accuracy = [], []
    for lower, upper in zip(edges[:-1], edges[1:]):
        mask = (confidence > lower) & (confidence <= upper)
        if mask.any():
            centers.append(float(confidence[mask].mean()))
            accuracy.append(float(correct[mask].mean()))
    fig, axis = plt.subplots(figsize=(5, 5))
    axis.plot([0, 1], [0, 1], "--", color="gray", label="Perfect calibration")
    axis.plot(centers, accuracy, marker="o", label="Model")
    axis.set(xlabel="Mean confidence", ylabel="Observed accuracy", xlim=(0, 1), ylim=(0, 1))
    axis.legend()
    fig.tight_layout()
    fig.savefig(output_path, dpi=160)
    plt.close(fig)


def evaluate_model(
    np,
    model,
    dataset,
    test_samples: Sequence[Sample],
    class_ids: Sequence[int],
    output_dir: Path,
    model_name: str,
) -> tuple[dict[str, object], object]:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from sklearn.metrics import (
        accuracy_score,
        balanced_accuracy_score,
        classification_report,
        confusion_matrix,
        log_loss,
        precision_recall_fscore_support,
        top_k_accuracy_score,
    )

    probabilities = model.predict(dataset, verbose=1)
    y_true = np.array([class_ids.index(sample.class_id) for sample in test_samples])
    y_pred = probabilities.argmax(axis=1)
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true, y_pred, average="macro", zero_division=0
    )
    metrics = {
        "model": model_name,
        "testSamples": len(y_true),
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "balancedAccuracy": float(balanced_accuracy_score(y_true, y_pred)),
        "macroPrecision": float(precision),
        "macroRecall": float(recall),
        "macroF1": float(f1),
        "top2Accuracy": float(
            top_k_accuracy_score(y_true, probabilities, k=2, labels=range(len(class_ids)))
        ),
        "top3Accuracy": float(
            top_k_accuracy_score(y_true, probabilities, k=3, labels=range(len(class_ids)))
        ),
        "logLoss": float(log_loss(y_true, probabilities, labels=range(len(class_ids)))),
        "expectedCalibrationError10Bins": expected_calibration_error(
            np, y_true, probabilities
        ),
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    write_json(output_dir / f"{model_name}_metrics.json", metrics)
    report = classification_report(
        y_true,
        y_pred,
        labels=range(len(class_ids)),
        target_names=[str(class_id) for class_id in class_ids],
        output_dict=True,
        zero_division=0,
    )
    write_json(output_dir / f"{model_name}_classification_report.json", report)

    matrix = confusion_matrix(y_true, y_pred, labels=range(len(class_ids)))
    np.save(output_dir / f"{model_name}_confusion_matrix.npy", matrix)
    with (output_dir / f"{model_name}_per_class.csv").open(
        "w", newline="", encoding="utf-8"
    ) as stream:
        writer = csv.writer(stream)
        writer.writerow(["class_id", "precision", "recall", "f1", "support"])
        for class_id in class_ids:
            values = report[str(class_id)]
            writer.writerow(
                [
                    class_id,
                    values["precision"],
                    values["recall"],
                    values["f1-score"],
                    values["support"],
                ]
            )

    save_calibration_plot(
        np,
        plt,
        y_true,
        probabilities,
        output_dir / f"{model_name}_calibration.png",
    )
    with (output_dir / f"{model_name}_predictions.csv").open(
        "w", newline="", encoding="utf-8"
    ) as stream:
        writer = csv.writer(stream)
        writer.writerow(
            ["relative_path", "true_class_id", "predicted_class_id", "confidence"]
        )
        for sample, predicted_index, row in zip(test_samples, y_pred, probabilities):
            writer.writerow(
                [
                    sample.relative_path,
                    sample.class_id,
                    class_ids[int(predicted_index)],
                    float(row[int(predicted_index)]),
                ]
            )
    return metrics, probabilities


def export_tflite_and_check_parity(
    np,
    tf,
    model,
    test_dataset,
    keras_probabilities,
    output_path: Path,
    sample_limit: int,
) -> dict[str, object]:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()
    output_path.write_bytes(tflite_bytes)

    interpreter = tf.lite.Interpreter(model_content=tflite_bytes)
    interpreter.allocate_tensors()
    input_detail = interpreter.get_input_details()[0]
    output_detail = interpreter.get_output_details()[0]
    tflite_rows = []
    images_seen = 0
    start = time.perf_counter()
    for image_batch, _ in test_dataset:
        for image in image_batch.numpy():
            interpreter.set_tensor(input_detail["index"], image[np.newaxis, ...])
            interpreter.invoke()
            tflite_rows.append(interpreter.get_tensor(output_detail["index"])[0].copy())
            images_seen += 1
            if images_seen >= sample_limit:
                break
        if images_seen >= sample_limit:
            break
    elapsed = time.perf_counter() - start
    tflite_probabilities = np.asarray(tflite_rows)
    keras_subset = keras_probabilities[: len(tflite_probabilities)]
    top1_agreement = float(
        np.mean(
            keras_subset.argmax(axis=1) == tflite_probabilities.argmax(axis=1)
        )
    )
    parity = {
        "samples": len(tflite_probabilities),
        "top1Agreement": top1_agreement,
        "meanAbsoluteProbabilityDifference": float(
            np.mean(np.abs(keras_subset - tflite_probabilities))
        ),
        "maximumAbsoluteProbabilityDifference": float(
            np.max(np.abs(keras_subset - tflite_probabilities))
        ),
        "hostEndToEndMillisecondsPerSample": elapsed / images_seen * 1000,
        "inputShape": input_detail["shape"].tolist(),
        "inputDtype": str(input_detail["dtype"]),
        "outputShape": output_detail["shape"].tolist(),
        "outputDtype": str(output_detail["dtype"]),
        "tfliteBytes": len(tflite_bytes),
        "tfliteSha256": hashlib.sha256(tflite_bytes).hexdigest(),
    }
    if top1_agreement < 0.98:
        raise RuntimeError(
            f"Keras/TFLite top-1 agreement {top1_agreement:.3f} is below 0.98."
        )
    return parity


def history_to_json(history) -> dict[str, list[float]]:
    return {
        name: [float(value) for value in values]
        for name, values in history.history.items()
    }


def write_model_card(
    path: Path,
    args,
    manifest_summary: dict[str, object],
    custom_metrics: dict[str, object],
    baseline_metrics: dict[str, object],
    parity: dict[str, object],
) -> None:
    content = f"""# ReadBuddy Sinhala Letter CNN Model Card

Pipeline version: `{PIPELINE_VERSION}`  
Created: {time.strftime('%Y-%m-%d %H:%M:%S %z')}  
Intended scope: Sinhala handwriting research and the five exposed Grade 1 tracing letters.  
Not intended for clinical diagnosis, high-stakes assessment, or unsupported Grade 3 claims.

## Data

- Dataset root supplied by operator: `{args.dataset}`
- Frozen manifest SHA-256: `{manifest_summary['manifestSha256']}`
- Seed: `{args.seed}`
- Samples: {manifest_summary['sampleCount']}
- Classes: {manifest_summary['classCount']}
- Split counts: `{manifest_summary['splitCounts']}`
- Duplicate bytes are kept within one split; cross-class duplicate bytes cause failure.

## Preprocessing

- Decode as one grayscale channel.
- Resize to 64×64 with antialiasing.
- Scale pixel values to `[0,1]`.
- No horizontal or vertical flips.

## Architecture

`Conv32(3×3 valid) → MaxPool2 → Conv64(3×3 valid) → MaxPool2 → Conv128(3×3 valid) → Flatten(18,432) → Dense128 → Dropout({args.dropout}) → Dense({manifest_summary['classCount']})/Softmax`

The inference dimensions match the shipped TFLite FlatBuffer. The original training-time dropout and optimizer state were not recoverable; they are explicit choices in this reproduction.

## Training

- Optimizer: Adam, learning rate `{args.learning_rate}`
- Loss: sparse categorical cross-entropy
- Maximum epochs: `{args.epochs}`
- Batch size: `{args.batch_size}`
- Early stopping monitors validation loss and restores best weights.

## Held-out test results

Custom CNN: `{json.dumps(custom_metrics, sort_keys=True)}`

Compact baseline: `{json.dumps(baseline_metrics, sort_keys=True)}`

## Conversion parity

`{json.dumps(parity, sort_keys=True)}`

## Limitations

- Performance applies only to the frozen test manifest and must not be generalized to children's traces without a separately approved child-trace evaluation.
- The numeric-ID-to-Unicode mapping is independently verified in the application only for අ, ආ, ක, ග and ස.
- Confidence is a model score; calibration metrics must be reviewed before interpreting it probabilistically.
- Dataset licensing, consent and demographic coverage must be checked before redistribution or field deployment.
"""
    path.write_text(content, encoding="utf-8")


def train(args) -> None:
    dataset_dir = Path(args.dataset).resolve()
    output_dir = Path(args.output_dir).resolve()
    manifest_path = Path(args.manifest).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.create_manifest or not manifest_path.exists():
        if args.regroup_provided_splits:
            summary = create_regrouped_manifest_from_provided_splits(
                dataset_dir,
                manifest_path,
                args.seed,
                args.allow_subset,
                args.quarantine_conflicts,
            )
        elif args.provided_splits:
            summary = create_provided_split_manifest(
                dataset_dir,
                manifest_path,
                args.seed,
                args.allow_subset,
                args.quarantine_conflicts,
            )
        else:
            summary = create_split_manifest(
                dataset_dir,
                manifest_path,
                args.seed,
                args.allow_subset,
                args.quarantine_conflicts,
            )
    else:
        summary_path = manifest_path.with_suffix(".summary.json")
        if not summary_path.exists():
            raise FileNotFoundError(
                f"Manifest summary is missing: {summary_path}. Recreate/freeze the split."
            )
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        if sha256_file(manifest_path) != summary["manifestSha256"]:
            raise ValueError("Frozen split manifest hash no longer matches its summary.")

    print(json.dumps(summary, indent=2, sort_keys=True))
    if args.prepare_only:
        return

    samples = load_and_verify_manifest(dataset_dir, manifest_path)
    class_ids = sorted({sample.class_id for sample in samples})
    class_to_index = {class_id: index for index, class_id in enumerate(class_ids)}
    np, tf = configure_determinism(args.seed)

    train_ds = build_dataset(
        tf, dataset_dir, samples, class_to_index, "train", args.batch_size, True, args.seed
    )
    validation_ds = build_dataset(
        tf,
        dataset_dir,
        samples,
        class_to_index,
        "validation",
        args.batch_size,
        False,
        args.seed,
    )
    test_ds = build_dataset(
        tf, dataset_dir, samples, class_to_index, "test", args.batch_size, False, args.seed
    )
    test_samples = [sample for sample in samples if sample.split == "test"]

    custom_backup_dir = output_dir / "custom_training_backup"
    callbacks = [
        tf.keras.callbacks.BackupAndRestore(
            backup_dir=str(custom_backup_dir),
            save_freq="epoch",
        ),
        tf.keras.callbacks.CSVLogger(
            str(output_dir / "custom_cnn_epoch_log.csv"), append=True
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(output_dir / "custom_cnn_best.keras"),
            monitor="val_loss",
            save_best_only=True,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=args.patience, restore_best_weights=True
        )
    ]
    custom_model = build_custom_cnn(tf, len(class_ids), args.dropout)
    custom_model.compile(
        optimizer=tf.keras.optimizers.Adam(args.learning_rate),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    custom_model.summary()
    custom_history = custom_model.fit(
        train_ds,
        validation_data=validation_ds,
        epochs=args.epochs,
        callbacks=callbacks,
        verbose=2,
    )
    custom_model.save(output_dir / "custom_cnn.keras")
    write_json(output_dir / "custom_cnn_history.json", history_to_json(custom_history))
    custom_metrics, custom_probabilities = evaluate_model(
        np,
        custom_model,
        test_ds,
        test_samples,
        class_ids,
        output_dir,
        "custom_cnn",
    )

    baseline_model = build_baseline(tf, len(class_ids))
    baseline_model.compile(
        optimizer=tf.keras.optimizers.Adam(args.learning_rate),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    baseline_history = baseline_model.fit(
        train_ds,
        validation_data=validation_ds,
        epochs=args.epochs,
        callbacks=[
            tf.keras.callbacks.BackupAndRestore(
                backup_dir=str(output_dir / "baseline_training_backup"),
                save_freq="epoch",
            ),
            tf.keras.callbacks.CSVLogger(
                str(output_dir / "compact_cnn_baseline_epoch_log.csv"), append=True
            ),
            tf.keras.callbacks.ModelCheckpoint(
                filepath=str(output_dir / "compact_cnn_baseline_best.keras"),
                monitor="val_loss",
                save_best_only=True,
            ),
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=args.patience, restore_best_weights=True
            )
        ],
        verbose=2,
    )
    baseline_model.save(output_dir / "compact_cnn_baseline.keras")
    write_json(
        output_dir / "compact_cnn_baseline_history.json",
        history_to_json(baseline_history),
    )
    baseline_metrics, _ = evaluate_model(
        np,
        baseline_model,
        test_ds,
        test_samples,
        class_ids,
        output_dir,
        "compact_cnn_baseline",
    )

    tflite_path = output_dir / "sinhala_letter_model.tflite"
    parity = export_tflite_and_check_parity(
        np,
        tf,
        custom_model,
        test_ds,
        custom_probabilities,
        tflite_path,
        min(args.parity_samples, len(test_samples)),
    )
    write_json(output_dir / "keras_tflite_parity.json", parity)
    (output_dir / "class_names.txt").write_text(
        "\n".join(str(class_id) for class_id in class_ids) + "\n",
        encoding="utf-8",
    )
    comparison = {
        "custom": custom_metrics,
        "baseline": baseline_metrics,
        "macroF1Difference": custom_metrics["macroF1"] - baseline_metrics["macroF1"],
        "balancedAccuracyDifference": custom_metrics["balancedAccuracy"]
        - baseline_metrics["balancedAccuracy"],
    }
    write_json(output_dir / "model_comparison.json", comparison)
    write_model_card(
        output_dir / "MODEL_CARD.md",
        args,
        summary,
        custom_metrics,
        baseline_metrics,
        parity,
    )
    run_manifest = {
        "pipelineVersion": PIPELINE_VERSION,
        "python": sys.version,
        "tensorflow": tf.__version__,
        "numpy": np.__version__,
        "arguments": vars(args),
        "splitManifestSha256": summary["manifestSha256"],
        "tfliteSha256": sha256_file(tflite_path),
        "classNamesSha256": sha256_file(output_dir / "class_names.txt"),
    }
    write_json(output_dir / "run_manifest.json", run_manifest)
    print(json.dumps(comparison, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", required=True, help="Numeric ImageFolder root")
    parser.add_argument("--output-dir", default="training/outputs/stage3")
    parser.add_argument("--manifest", default="training/splits/split_manifest.csv")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--epochs", type=int, default=40)
    parser.add_argument("--patience", type=int, default=6)
    parser.add_argument("--learning-rate", type=float, default=0.001)
    parser.add_argument("--dropout", type=float, default=0.30)
    parser.add_argument("--parity-samples", type=int, default=100)
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--create-manifest", action="store_true")
    parser.add_argument(
        "--provided-splits",
        action="store_true",
        help="Preserve publisher train/valid/test directories exactly",
    )
    parser.add_argument(
        "--regroup-provided-splits",
        action="store_true",
        help="Deduplicate contaminated publisher splits and stratify by hash",
    )
    parser.add_argument(
        "--quarantine-conflicts",
        action="store_true",
        help="Exclude and record all ambiguous/cross-split duplicate hashes",
    )
    parser.add_argument(
        "--allow-subset",
        action="store_true",
        help="Permit fewer than 454 classes for an explicitly labelled pilot only",
    )
    return parser


def parse_args():
    parser = build_parser()
    args = parser.parse_args()
    if args.provided_splits and args.regroup_provided_splits:
        parser.error("Choose either --provided-splits or --regroup-provided-splits.")
    return args


if __name__ == "__main__":
    train(parse_args())
