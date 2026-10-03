"""Fine-tune the ReadBuddy Sinhala CNN with an Unknown/Invalid class.

This script is designed for a free Google Colab T4 runtime. It keeps the
original 454 classifier outputs, adds output 455 for invalid pen input, creates
deterministic synthetic hard negatives, fine-tunes from the retained Keras
checkpoint, evaluates a held-out split, and exports a TFLite artifact.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import shutil
import tempfile
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


IMAGE_SIZE = 64
LETTER_CLASS_COUNT = 454
UNKNOWN_CLASS_ID = 455
PIPELINE_VERSION = "readbuddy-open-set-cnn-v1"
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".bmp"}


def write_json(path: Path, value: object) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True), encoding="utf-8"
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _random_point(rng: random.Random, margin: int = 5) -> tuple[int, int]:
    return (
        rng.randint(margin, IMAGE_SIZE - margin - 1),
        rng.randint(margin, IMAGE_SIZE - margin - 1),
    )


def _draw_invalid_sample(seed: int) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("L", (IMAGE_SIZE, IMAGE_SIZE), color=0)
    draw = ImageDraw.Draw(image)
    width = rng.randint(3, 8)
    pattern = seed % 7

    if pattern == 0:  # repeated zig-zag
        points = []
        left = rng.randint(5, 18)
        right = rng.randint(45, 58)
        top = rng.randint(4, 12)
        step = rng.randint(5, 10)
        for index in range(rng.randint(6, 11)):
            points.append((left if index % 2 == 0 else right, min(59, top + index * step)))
        draw.line(points, fill=255, width=width, joint="curve")
    elif pattern == 1:  # dense random walk
        points = [_random_point(rng, 12)]
        for _ in range(rng.randint(15, 28)):
            x, y = points[-1]
            points.append(
                (
                    max(3, min(60, x + rng.randint(-18, 18))),
                    max(3, min(60, y + rng.randint(-18, 18))),
                )
            )
        draw.line(points, fill=255, width=width, joint="curve")
    elif pattern == 2:  # crossed unrelated lines
        for _ in range(rng.randint(3, 7)):
            draw.line(
                [_random_point(rng), _random_point(rng)],
                fill=255,
                width=width,
            )
    elif pattern == 3:  # nested loops / blobs
        center_x, center_y = _random_point(rng, 18)
        for radius in range(rng.randint(7, 12), rng.randint(20, 27), 5):
            box = (
                center_x - radius,
                center_y - radius,
                center_x + radius,
                center_y + radius,
            )
            draw.ellipse(box, outline=255, width=width)
    elif pattern == 4:  # incomplete short marks
        for _ in range(rng.randint(1, 3)):
            start = _random_point(rng, 12)
            end = (
                max(3, min(60, start[0] + rng.randint(-12, 12))),
                max(3, min(60, start[1] + rng.randint(-12, 12))),
            )
            draw.line([start, end], fill=255, width=width)
    elif pattern == 5:  # filled geometric noise
        for _ in range(rng.randint(2, 5)):
            x, y = _random_point(rng, 12)
            radius = rng.randint(4, 12)
            draw.ellipse(
                (x - radius, y - radius, x + radius, y + radius), fill=255
            )
    else:  # back-and-forth strokes like a child's scribble
        x = rng.randint(15, 30)
        points = []
        for index in range(rng.randint(7, 13)):
            points.append(
                (
                    max(4, min(59, x + rng.randint(-10, 10))),
                    rng.randint(5, 24) if index % 2 == 0 else rng.randint(39, 58),
                )
            )
        draw.line(points, fill=255, width=width, joint="curve")

    if rng.random() < 0.35:
        image = image.filter(ImageFilter.GaussianBlur(radius=rng.uniform(0.2, 0.8)))
    return image


def generate_unknown_class(
    dataset: Path,
    seed: int,
    train_count: int,
    validation_count: int,
    test_count: int,
) -> dict[str, int]:
    split_specs = {
        "train": train_count,
        "valid": validation_count,
        "test": test_count,
    }
    generated: dict[str, int] = {}
    seed_offset = 0
    for split, count in split_specs.items():
        output = dataset / split / str(UNKNOWN_CLASS_ID)
        if output.exists():
            shutil.rmtree(output)
        output.mkdir(parents=True, exist_ok=True)
        for index in range(count):
            sample_seed = seed + seed_offset + index
            image = _draw_invalid_sample(sample_seed)
            image.save(output / f"invalid_{sample_seed:07d}.png")
        generated[split] = count
        seed_offset += 100_000
    return generated


def validate_dataset(dataset: Path) -> None:
    for split in ("train", "valid", "test"):
        split_dir = dataset / split
        if not split_dir.is_dir():
            raise FileNotFoundError(f"Missing dataset split: {split_dir}")
        missing = [
            class_id
            for class_id in range(1, UNKNOWN_CLASS_ID + 1)
            if not (split_dir / str(class_id)).is_dir()
        ]
        if missing:
            raise ValueError(
                f"{split} is missing {len(missing)} classes; first missing: {missing[:10]}"
            )


def collect_split(dataset: Path, split: str) -> tuple[list[str], list[int]]:
    paths: list[str] = []
    labels: list[int] = []
    for class_id in range(1, UNKNOWN_CLASS_ID + 1):
        class_dir = dataset / split / str(class_id)
        for path in sorted(class_dir.iterdir()):
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES:
                paths.append(str(path))
                labels.append(class_id - 1)
    if not paths:
        raise ValueError(f"No images found in {dataset / split}")
    return paths, labels


def build_dataset(tf, paths, labels, batch_size: int, training: bool, seed: int):
    dataset = tf.data.Dataset.from_tensor_slices((paths, labels))

    def decode(path, label):
        image = tf.io.decode_image(
            tf.io.read_file(path), channels=1, expand_animations=False
        )
        image.set_shape([None, None, 1])
        image = tf.image.resize(image, [IMAGE_SIZE, IMAGE_SIZE], antialias=True)
        image = tf.cast(image, tf.float32) / 255.0
        return image, label

    dataset = dataset.map(
        decode, num_parallel_calls=tf.data.AUTOTUNE, deterministic=True
    )
    if training:
        dataset = dataset.shuffle(
            min(len(paths), 15000), seed=seed, reshuffle_each_iteration=True
        )
    return dataset.batch(batch_size).prefetch(tf.data.AUTOTUNE)


def build_base_model(tf):
    """Rebuild the 454-class architecture and load weights separately.

    Colab and the original training environment can use different Keras config
    schemas even when their numerical layers are compatible. Reconstructing
    the audited architecture avoids unsafe whole-model deserialization.
    """
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
            tf.keras.layers.Dropout(0.30, name="dropout"),
            tf.keras.layers.Dense(
                LETTER_CLASS_COUNT, activation="softmax", name="class_output"
            ),
        ],
        name="readbuddy_custom_cnn",
    )


def load_base_weights(model, checkpoint_path: Path) -> None:
    """Load weights from a .keras archive without reading its model config."""
    if zipfile.is_zipfile(checkpoint_path):
        with zipfile.ZipFile(checkpoint_path) as archive:
            weight_name = next(
                (name for name in archive.namelist() if name.endswith(".weights.h5")),
                None,
            )
            if weight_name is None:
                raise ValueError(f"No weights file found inside {checkpoint_path}")
            with tempfile.TemporaryDirectory() as temporary_directory:
                archive.extract(weight_name, temporary_directory)
                model.load_weights(Path(temporary_directory) / weight_name)
        return
    model.load_weights(checkpoint_path)


def extend_model(tf, np_module, base_model):
    old_output = base_model.get_layer("class_output")
    if old_output.units != LETTER_CLASS_COUNT:
        raise ValueError(
            f"Expected a {LETTER_CLASS_COUNT}-class base model, found {old_output.units}."
        )
    features = base_model.get_layer("dropout").output
    new_output_layer = tf.keras.layers.Dense(
        UNKNOWN_CLASS_ID, activation="softmax", name="open_set_output"
    )
    outputs = new_output_layer(features)
    model = tf.keras.Model(
        inputs=base_model.inputs, outputs=outputs, name="readbuddy_open_set_cnn"
    )

    old_kernel, old_bias = old_output.get_weights()
    new_kernel, new_bias = new_output_layer.get_weights()
    new_kernel[:, :LETTER_CLASS_COUNT] = old_kernel
    new_bias[:LETTER_CLASS_COUNT] = old_bias
    new_kernel[:, LETTER_CLASS_COUNT] = np_module.mean(old_kernel, axis=1)
    new_bias[LETTER_CLASS_COUNT] = float(np_module.median(old_bias))
    new_output_layer.set_weights([new_kernel, new_bias])
    return model


def history_dict(histories) -> dict[str, list[float]]:
    combined: dict[str, list[float]] = {}
    for history in histories:
        for key, values in history.history.items():
            combined.setdefault(key, []).extend(float(value) for value in values)
    return combined


def evaluate(np_module, probabilities, labels) -> dict[str, float | int]:
    y_true = np_module.asarray(labels, dtype=np_module.int64)
    y_pred = probabilities.argmax(axis=1)
    unknown_index = UNKNOWN_CLASS_ID - 1
    letter_mask = y_true != unknown_index
    unknown_mask = ~letter_mask
    predicted_unknown = y_pred == unknown_index

    true_unknown = int(np_module.sum(unknown_mask & predicted_unknown))
    false_unknown = int(np_module.sum(letter_mask & predicted_unknown))
    missed_unknown = int(np_module.sum(unknown_mask & ~predicted_unknown))
    unknown_precision = true_unknown / max(1, true_unknown + false_unknown)
    unknown_recall = true_unknown / max(1, true_unknown + missed_unknown)

    f1_scores = []
    for class_index in range(UNKNOWN_CLASS_ID):
        true_positive = int(np_module.sum((y_true == class_index) & (y_pred == class_index)))
        false_positive = int(np_module.sum((y_true != class_index) & (y_pred == class_index)))
        false_negative = int(np_module.sum((y_true == class_index) & (y_pred != class_index)))
        precision = true_positive / max(1, true_positive + false_positive)
        recall = true_positive / max(1, true_positive + false_negative)
        f1_scores.append(
            0.0 if precision + recall == 0 else 2 * precision * recall / (precision + recall)
        )

    top3 = np_module.argpartition(probabilities, -3, axis=1)[:, -3:]
    confidence = probabilities.max(axis=1)
    correct = (y_true == y_pred).astype(float)
    edges = np_module.linspace(0.0, 1.0, 11)
    ece = 0.0
    for lower, upper in zip(edges[:-1], edges[1:]):
        mask = (confidence > lower) & (confidence <= upper)
        if np_module.any(mask):
            ece += float(np_module.mean(mask)) * abs(
                float(np_module.mean(correct[mask]))
                - float(np_module.mean(confidence[mask]))
            )

    return {
        "overallAccuracy": float(np_module.mean(y_true == y_pred)),
        "letterOnlyAccuracy": float(np_module.mean(y_true[letter_mask] == y_pred[letter_mask])),
        "unknownPrecision": float(unknown_precision),
        "unknownRecall": float(unknown_recall),
        "invalidFalseAcceptanceRate": float(1.0 - unknown_recall),
        "letterFalseRejectionRate": float(np_module.mean(predicted_unknown[letter_mask])),
        "macroF1": float(np_module.mean(f1_scores)),
        "top3Accuracy": float(np_module.mean(np_module.any(top3 == y_true[:, None], axis=1))),
        "expectedCalibrationError10Bins": float(ece),
        "testSamples": int(len(y_true)),
        "unknownTestSamples": int(np_module.sum(unknown_mask)),
    }


def check_tflite_parity(tf, np_module, model, test_dataset, tflite_bytes: bytes):
    interpreter = tf.lite.Interpreter(model_content=tflite_bytes)
    interpreter.allocate_tensors()
    input_detail = interpreter.get_input_details()[0]
    output_detail = interpreter.get_output_details()[0]
    keras_batches = []
    tflite_batches = []
    compared = 0
    for images, _ in test_dataset:
        for image in images.numpy():
            sample = image[np_module.newaxis, ...].astype(np_module.float32)
            keras_probability = model(sample, training=False).numpy()[0]
            interpreter.set_tensor(input_detail["index"], sample)
            interpreter.invoke()
            tflite_probability = interpreter.get_tensor(output_detail["index"])[0]
            keras_batches.append(keras_probability)
            tflite_batches.append(tflite_probability)
            compared += 1
            if compared >= 100:
                break
        if compared >= 100:
            break
    keras_values = np_module.asarray(keras_batches)
    tflite_values = np_module.asarray(tflite_batches)
    return {
        "samples": compared,
        "top1Agreement": float(
            np_module.mean(
                keras_values.argmax(axis=1) == tflite_values.argmax(axis=1)
            )
        ),
        "meanAbsoluteProbabilityDifference": float(
            np_module.mean(np_module.abs(keras_values - tflite_values))
        ),
        "maximumAbsoluteProbabilityDifference": float(
            np_module.max(np_module.abs(keras_values - tflite_values))
        ),
        "inputShape": input_detail["shape"].tolist(),
        "outputShape": output_detail["shape"].tolist(),
    }


def train(args) -> None:
    import tensorflow as tf

    random.seed(args.seed)
    np.random.seed(args.seed)
    tf.keras.utils.set_random_seed(args.seed)
    try:
        tf.config.experimental.enable_op_determinism()
    except Exception:
        pass

    dataset = Path(args.dataset).resolve()
    base_model_path = Path(args.base_model).resolve()
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)

    generated = generate_unknown_class(
        dataset,
        args.seed,
        args.unknown_train,
        args.unknown_validation,
        args.unknown_test,
    )
    validate_dataset(dataset)
    write_json(output / "unknown_generation.json", generated)

    train_paths, train_labels = collect_split(dataset, "train")
    validation_paths, validation_labels = collect_split(dataset, "valid")
    test_paths, test_labels = collect_split(dataset, "test")
    train_dataset = build_dataset(
        tf, train_paths, train_labels, args.batch_size, True, args.seed
    )
    validation_dataset = build_dataset(
        tf, validation_paths, validation_labels, args.batch_size, False, args.seed
    )
    test_dataset = build_dataset(
        tf, test_paths, test_labels, args.batch_size, False, args.seed
    )

    base_model = build_base_model(tf)
    load_base_weights(base_model, base_model_path)
    model = extend_model(tf, np, base_model)

    for layer in model.layers[:-1]:
        layer.trainable = False
    model.compile(
        optimizer=tf.keras.optimizers.Adam(args.head_learning_rate),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    head_history = model.fit(
        train_dataset,
        validation_data=validation_dataset,
        epochs=args.head_epochs,
        verbose=2,
    )

    trainable_names = {"conv_3", "dense_128", "dropout", "open_set_output"}
    for layer in model.layers:
        layer.trainable = layer.name in trainable_names
    model.compile(
        optimizer=tf.keras.optimizers.Adam(args.learning_rate),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    callbacks = [
        tf.keras.callbacks.ModelCheckpoint(
            output / "open_set_cnn_best.keras",
            monitor="val_loss",
            save_best_only=True,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=args.patience,
            restore_best_weights=True,
        ),
        tf.keras.callbacks.CSVLogger(output / "open_set_epoch_log.csv"),
    ]
    fine_history = model.fit(
        train_dataset,
        validation_data=validation_dataset,
        epochs=args.epochs,
        callbacks=callbacks,
        verbose=2,
    )
    model.save(output / "open_set_cnn.keras")
    write_json(output / "open_set_history.json", history_dict([head_history, fine_history]))

    probabilities = model.predict(test_dataset, verbose=1)
    metrics = evaluate(np, probabilities, test_labels)
    write_json(output / "open_set_metrics.json", metrics)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()
    tflite_path = output / "sinhala_letter_open_set_model.tflite"
    tflite_path.write_bytes(tflite_bytes)
    (output / "class_names.txt").write_text(
        "\n".join(str(value) for value in range(1, UNKNOWN_CLASS_ID + 1)) + "\n",
        encoding="utf-8",
    )
    parity = check_tflite_parity(tf, np, model, test_dataset, tflite_bytes)
    write_json(output / "keras_tflite_parity.json", parity)

    manifest = {
        "pipelineVersion": PIPELINE_VERSION,
        "seed": args.seed,
        "tensorflow": tf.__version__,
        "numpy": np.__version__,
        "baseModel": str(base_model_path),
        "baseModelSha256": sha256_file(base_model_path),
        "tfliteSha256": sha256_file(tflite_path),
        "classNamesSha256": sha256_file(output / "class_names.txt"),
        "classCount": UNKNOWN_CLASS_ID,
        "unknownClassId": UNKNOWN_CLASS_ID,
        "splitCounts": {
            "train": len(train_paths),
            "validation": len(validation_paths),
            "test": len(test_paths),
        },
        "arguments": vars(args),
    }
    write_json(output / "run_manifest.json", manifest)
    (output / "MODEL_CARD.md").write_text(
        "# ReadBuddy Open-Set Sinhala Letter CNN\n\n"
        f"Pipeline: `{PIPELINE_VERSION}`  \n"
        f"Classes: {UNKNOWN_CLASS_ID} (1–454 letters, 455 Unknown/Invalid)  \n"
        f"Base model SHA-256: `{manifest['baseModelSha256']}`  \n"
        f"TFLite SHA-256: `{manifest['tfliteSha256']}`\n\n"
        "## Held-out results\n\n"
        f"```json\n{json.dumps(metrics, indent=2, sort_keys=True)}\n```\n\n"
        "## Limitation\n\n"
        "Unknown-class evidence is deterministic synthetic hard-negative data. "
        "Before real-world deployment, evaluate and fine-tune with consented, "
        "de-identified child traces collected independently from this test set.\n",
        encoding="utf-8",
    )
    archive = shutil.make_archive(str(output), "zip", root_dir=output)
    print(json.dumps(metrics, indent=2, sort_keys=True))
    print(f"OUTPUT_ZIP={archive}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--base-model", required=True)
    parser.add_argument("--output-dir", default="/content/readbuddy_open_set_output")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--head-epochs", type=int, default=2)
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--patience", type=int, default=3)
    parser.add_argument("--head-learning-rate", type=float, default=0.001)
    parser.add_argument("--learning-rate", type=float, default=0.0001)
    parser.add_argument("--unknown-train", type=int, default=1800)
    parser.add_argument("--unknown-validation", type=int, default=400)
    parser.add_argument("--unknown-test", type=int, default=400)
    return parser


if __name__ == "__main__":
    train(build_parser().parse_args())
