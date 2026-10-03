# Stage 3 Implementation Report — Reproducible CNN Evaluation and Deployment

Date: 23 August 2026  
Project scope: ReadBuddy AI, Grade 1 and Grade 2 only  
Cost: zero-cost tooling and free Google Colab execution path

## Outcome

Stage 3’s software and research-evidence pipeline is implemented. The shipped
TFLite model was inspected, its exact inference architecture was recovered, a
deterministic 64×64 training/evaluation pipeline and Colab notebook were added,
and real offline inference was benchmarked successfully on the Android 14
emulator.

Training-dependent accuracy and comparison results are intentionally not
claimed yet. The required 454-class dataset and original frozen split are not
available in this workspace, so reporting a new accuracy now would fabricate
evidence. Once the dataset is supplied, the prepared pipeline generates the
remaining held-out results and model card automatically.

## Why each Stage 3 feature exists

| Feature | Research reason | Evidence produced |
|---|---|---|
| Numeric class-folder validation (1–454) | Prevents Unicode sorting or folder-order errors from silently changing labels. | Dataset audit and class-ID list |
| SHA-256 for every image | Makes the exact data snapshot traceable and detects changes after the experiment is frozen. | Split manifest and summary |
| Duplicate grouping | Identical images in train and test inflate results through leakage. All identical bytes stay in one split. | Leakage validation tests |
| Cross-class duplicate rejection | The same image under two labels is a label conflict, not valid augmentation. | Fail-fast data-quality error |
| Seeded train/validation/test split | Makes selection repeatable and separates tuning from final evaluation. | Seed 42 and manifest hash |
| Recovered custom CNN | Reproduces the architecture actually shipped in the app instead of the obsolete 128×128 cloud MobileNet notebook. | FlatBuffer architecture JSON |
| Compact CNN baseline | A research contribution requires evidence that added complexity provides value on the same samples. | `model_comparison.json` |
| Early stopping on validation loss | Reduces overfitting without inspecting the held-out test set during training. | Training-history JSON |
| No flip augmentation | Mirroring can change handwriting structure and could teach the model to accept the error being studied. | Explicit preprocessing record |
| No stochastic augmentation in reproduction v1 | The original augmentation recipe is unknown; adding guessed transformations would weaken faithful reproduction. | Model card limitation |
| Macro precision/recall/F1 and balanced accuracy | Overall accuracy can hide poor minority-class performance in a 454-class problem. | Test metrics and per-class CSV |
| Top-2/top-3 accuracy | Shows whether the correct class remains among close alternatives and supports confusion analysis. | Test metrics JSON |
| Confusion matrix and per-class recall | Identifies exactly which Sinhala shapes need more data or teaching support. | NPY matrix, JSON/CSV reports |
| Log loss and 10-bin calibration error | A confidence score should be evaluated, not assumed to be a probability. | Metrics and calibration plot |
| Same-split baseline comparison | Prevents an unfair comparison caused by different samples or easier splits. | Difference in macro-F1 and balanced accuracy |
| Dynamic-range TFLite export | Keeps inference offline and free while reducing stored weight size. | `.tflite` file and hash |
| Keras/TFLite parity gate | Conversion can alter predictions; at least 98% top-1 agreement is required before deployment. | Parity JSON |
| Tensor contract validation in Flutter | Fails clearly if a future model no longer matches 64×64 grayscale preprocessing or 454 labels. | Runtime integration assertion |
| Warmed emulator latency benchmark | Measures feasibility on the actual Android path and separates native inference from preprocessing. | Raw log and structured benchmark JSON |
| Model card and run manifest | Records intended use, limitations, software versions, hashes and results for reproducibility. | Markdown model card and JSON manifest |

## Exact shipped-model findings

- Asset size: 2,527,776 bytes
- Asset SHA-256: `D982CFD59221CDC40F159B7A53BD144D530A0441F9E797961FE3C619745778F8`
- Input: float32 `[1,64,64,1]`
- Output: float32 `[1,454]`
- Graph: Conv32 → pool → Conv64 → pool → Conv128 → flatten 18,432 →
  dense 128 → dense 454 → softmax
- Operators: 12; tensors: 26
- Large weights: dynamic-range int8 storage; float32 input/output

The original training-only choices and dataset split cannot be recovered from
the inference FlatBuffer. Dropout 0.30, Adam learning rate 0.001, seed 42 and
early stopping are therefore clearly labelled reproduction choices.

## Android benchmark result

Environment: Android 14 `sdk_gphone64_x86_64` emulator, Android x64, Dart 3.10.4  
Method: 5 warm-up runs + 30 measured runs on one synthetic trace PNG

| Measurement | Mean | p50 | p95 |
|---|---:|---:|---:|
| Native TFLite inference | 133.829 ms | 115.911 ms | 162.641 ms |
| Full decode/resize/inference | 140.292 ms | 125.599 ms | 167.795 ms |

Model load time was 494.257 ms. The passing debug integration APK was
131,150,501 bytes with SHA-256
`024EF698F24ADD69959E813742A91A52C75B727F007B867547921FF565F3E120`.
This large debug APK is not a release-size claim. Physical-device benchmarking
remains required before the final thesis.

## Files delivered

- `training/stage3_cnn_pipeline.py` — full deterministic experiment pipeline
- `training/stage3_reproduce_shipped_cnn.ipynb` — free Colab runner
- `training/requirements-stage3.txt` — pinned Python experiment environment
- `training/inspect_tflite_model.py` — repeatable FlatBuffer inspection
- `training/shipped_model_architecture.json` — exact shipped graph evidence
- `training/test_stage3_pipeline.py` — split/hash/leakage regression tests
- `training/SHIPPED_MODEL_CARD.md` — honest current-model record
- `integration_test/cnn_runtime_benchmark_test.dart` — Android benchmark
- `training/device_benchmark_android14_emulator.json` — structured timings and hashes
- `training/stage3_device_benchmark_raw.log` — raw passing test record
- `training/README.md` — execution and thesis-reporting instructions
- `training/legacy_mobilenet_cloud_train.ipynb` and
  `training/LEGACY_MOBILENET_CLOUD_README.md` — preserved obsolete design,
  clearly separated from the shipped model

## Verification completed

- `python -m py_compile` — Stage 3 pipeline and model inspector passed
- Four Python tests — deterministic split, duplicate containment, conflicting
  label rejection and post-freeze mutation detection all passed
- Notebook JSON validation — passed
- `flutter analyze` — no issues
- `flutter test` — all 12 tests passed
- Android integration benchmark — passed on `emulator-5554`

## Remaining execution sequence

1. Obtain the supervisor-approved numeric 1–454 dataset snapshot and record its
   source/licence; do not use student data without ethics and consent approval.
2. In the free Colab notebook, run `--create-manifest --prepare-only` and give
   the summary plus frozen CSV to the supervisor before training.
3. Train the recovered CNN and compact baseline using the same manifest.
4. Retain all automatically generated histories, metrics, per-class reports,
   confusion matrix, calibration plot, model comparison and parity file.
5. Repeat the experiment with additional seeds if Colab time permits and report
   mean plus variation; otherwise state clearly that it is a single seeded run.
6. Replace the bundled model only if label order, held-out metrics, parity and
   supervisor review all pass.
7. Run the benchmark on at least one real low/mid-range Android phone and report
   model load, p50/p95 latency, release APK size and offline behavior.

## Thesis-safe statement

“The deployed 64×64 grayscale CNN architecture was independently recovered
from the bundled TensorFlow Lite FlatBuffer. A deterministic, hash-verified,
duplicate-aware split and same-split baseline evaluation protocol was then
implemented. Deployment feasibility was confirmed on an Android 14 emulator,
where 30 post-warm-up runs produced a median native inference latency of
115.911 ms. These latency values do not constitute recognition-accuracy
evidence; held-out classification metrics remain pending execution on the
supervisor-approved dataset.”
