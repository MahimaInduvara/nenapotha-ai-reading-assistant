# Stage 3 — Reproducible Sinhala Letter CNN

Stage 3 turns the bundled `64×64×1 → 454` TensorFlow Lite classifier into an
auditable research experiment. It creates a frozen split, trains the recovered
CNN and a compact baseline on the same samples, evaluates only on the held-out
test set, exports TFLite, and checks Keras/TFLite parity.

No result is pre-filled. Accuracy, F1, calibration and latency must come from
executed experiments and retained output files.

## What was recovered from the shipped model

`shipped_model_architecture.json` is a FlatBuffer inspection of the exact app
asset. Its inference architecture is:

`Conv32 → MaxPool → Conv64 → MaxPool → Conv128 → Flatten(18,432) → Dense128 → Dense454 → Softmax`

Input is float32 `[1,64,64,1]`; output is float32 `[1,454]`. Large weights use
dynamic-range int8 storage. The original split, training seed, dropout,
optimizer state and training history cannot be recovered from a TFLite file,
so the reproduction records new choices explicitly.

The former 128×128 MobileNet/cloud notebook is preserved as
`legacy_mobilenet_cloud_train.ipynb`; it does **not** describe the model used by
the current Flutter app.

## Free execution route

Use `stage3_reproduce_shipped_cnn.ipynb` in Google Colab's free runtime. Put the
dataset in numeric ImageFolder form:

```text
dataset/
  1/*.png
  2/*.png
  ...
  454/*.png
```

The numeric folder IDs must match `assets/models/class_names.txt`. Never sort
Sinhala Unicode strings to invent a label order.

First freeze and inspect the split:

```bash
python training/stage3_cnn_pipeline.py \
  --dataset /path/to/dataset \
  --output-dir training/outputs/stage3 \
  --manifest training/splits/split_manifest.csv \
  --seed 42 --create-manifest --prepare-only
```

Commit or archive both `split_manifest.csv` and its `.summary.json` before
training. Reusing the manifest verifies every image hash and fails if the data
changed or identical files crossed split boundaries.

Then train using the frozen split:

```bash
python training/stage3_cnn_pipeline.py \
  --dataset /path/to/dataset \
  --output-dir training/outputs/stage3 \
  --manifest training/splits/split_manifest.csv \
  --seed 42 --epochs 40 --batch-size 32
```

`--allow-subset` is only for a clearly named pilot; it must not be reported as
a 454-class result.

## Evidence produced

- Frozen split CSV, hashes, seed and class/sample counts
- Custom CNN and compact-CNN baseline histories
- Held-out accuracy, balanced accuracy, macro precision/recall/F1, top-2,
  top-3, log loss and 10-bin expected calibration error
- Per-class metrics, prediction table, confusion matrix and calibration plot
- Dynamic-range-quantized TFLite model and Keras/TFLite parity report
- Run manifest with software versions and artifact SHA-256 hashes
- Automatically generated model card with limitations
- Emulator/device runtime benchmark from
  `integration_test/cnn_runtime_benchmark_test.dart`

## Local checks that do not need TensorFlow or the dataset

```bash
python -m unittest discover -s training -p "test_stage3_pipeline.py" -v
python -m py_compile training/stage3_cnn_pipeline.py
```

To reproduce the FlatBuffer inspection without installing full TensorFlow:

```bash
python -m pip install tflite==2.18.0
python training/inspect_tflite_model.py \
  assets/models/sinhala_letter_model.tflite \
  --output training/shipped_model_architecture.json
```

## Thesis reporting rule

Call validation results **validation results** and final frozen-split results
**held-out test results**. Report the mean and variation across multiple seeds
if time permits. The currently cited 94.04% value is not independently
reproducible until its original data split and training record are supplied;
do not relabel it as a test accuracy.
