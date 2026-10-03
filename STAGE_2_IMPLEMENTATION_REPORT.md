# ReadBuddy AI — Stage 2 CNN-to-Application Integration Report

Date: 23 August 2026  
Scope: Five Grade 1 tracing letters — අ, ආ, ක, ග and ස  
Cost: Zero paid services

## Outcome

The Stage 2 software integration is complete. The application no longer compares a numeric CNN label such as `1` directly with a Unicode letter such as `අ`. It now follows one traceable path:

`TFLite output index → numeric dataset class ID → verified Sinhala Unicode → confidence rule → UI verdict → stored attempt`

Flutter analysis passes, all 12 automated tests pass, and a fresh debug APK was built, installed and launched on the Pixel 6 API 34 emulator.

Five empirical handwriting samples and a short demonstration video remain evidence-collection tasks. They must use real traces; they should not be simulated or reported as model-accuracy evidence without observation.

## Verified exposed mapping

| TFLite output index | Dataset class ID | Unicode letter | App scope |
|---:|---:|---|---|
| 0 | 1 | අ | Grade 1 tracing |
| 1 | 2 | ආ | Grade 1 tracing |
| 11 | 12 | ක | Grade 1 tracing |
| 24 | 25 | ග | Grade 1 tracing |
| 249 | 250 | ස | Grade 1 tracing |

The class-ID-to-Unicode values were recovered from the public GUI notebook associated with the Sathira L. Amal “Sinhala Letter 454” dataset:

- Dataset page: https://www.kaggle.com/datasets/sathiralamal/sinhala-letter-454
- Mapping notebook: https://github.com/LasinduViduranga/sinhala-character-recognition-ml/blob/main/GUI%20for%20character%20recognition%20model.ipynb

The project’s `class_names.txt` establishes the local output-index-to-numeric-ID sequence and contains 454 unique IDs from 1 to 454. Stage 2 treats only the five table entries above as application-verified Unicode mappings.

## Implementation changes

### Versioned mapping

`lib/services/sinhala_letter_label_map.dart` is the single source of truth for the five exposed mappings. It records mapping version `sinhala-letter-454-exposed-v1`, the 454-class boundary and the external source.

### Strict model-label validation

`LetterClassifierService.loadModel()` now rejects:

- a label count other than 454;
- non-numeric class IDs;
- IDs below 1 or above 454;
- duplicate class IDs; and
- disagreement between the TFLite output dimension and label-file length.

The interpreter is closed if validation fails, preventing a partially loaded classifier from being used.

### Explicit prediction identity

`LetterPrediction` now retains:

- zero-based TFLite output index;
- one-based dataset class ID;
- mapped Unicode letter when verified; and
- top-1 model confidence.

An unverified class is displayed/stored safely as `class:<ID>` rather than being presented as a Sinhala Unicode prediction.

### Consistent scoring and storage

The tracing screen uses `LetterPrediction.matchesExpected()` for its decision. A pass requires both:

1. the mapped Unicode letter equals the current target; and
2. model confidence is at least 0.50.

The same prediction and pass/fail result are stored in `TaskItemResult`, preventing the screen and progress history from disagreeing.

### Honest failure handling

Geometric guide coverage can no longer mark an attempt correct when the CNN is loading, unavailable or fails. In those cases the app clearly states that automatic recognition is unavailable or failed, and the attempt is neither scored nor saved.

The visible percentage is now labelled **Model confidence**. It is not described as handwriting accuracy, pronunciation accuracy or probability that the child is correct.

## Automated verification

Command results on 23 August 2026:

| Gate | Result |
|---|---|
| `flutter analyze` | PASS — no issues found |
| `flutter test` | PASS — 12 tests |
| Shipped label asset | PASS — 454 unique numeric class IDs |
| Five exposed ID mappings | PASS — all five deterministic cases |
| Confidence threshold | PASS — match and threshold both required |
| Unsupported class handling | PASS — no unverified Unicode result |
| Invalid label count/value/duplicate/range | PASS — rejected |
| Invalid output indexes | PASS — rejected |
| Existing language-selection smoke test | PASS |

## Android runtime evidence

- Emulator: Pixel 6 API 34 (`emulator-5554`)
- Build result: `assembleDebug` completed successfully
- Installation result: debug APK installed successfully
- Launch result: Flutter process started successfully; Android PID was `27985` at capture time
- Fresh APK time: 23 August 2026 10:51:35 (Asia/Colombo)
- APK size: 134,085,384 bytes
- APK SHA-256: `E3D29BAD1D680CD5F4A72B53D285D1CE83E4600AD298ECBF899A0D8CB1C9E57E`
- Runtime screenshot: `stage2_running.png` (1080 × 2400)

## Frozen artifact hashes

| Artifact | SHA-256 |
|---|---|
| `assets/models/sinhala_letter_model.tflite` | `D982CFD59221CDC40F159B7A53BD144D530A0441F9E797961FE3C619745778F8` |
| `assets/models/class_names.txt` | `2A342F008D58C0E0C1A2798BEDF51A6C18FBBBC72D576EC5037741447D411D2C` |
| `lib/services/sinhala_letter_label_map.dart` | `BDA00893657D9620A203D4A7EC6AC4B41C243917DC1A6BC3BBFFF8E136024C95` |

These hashes were captured after the final Stage 2 formatting and passing test run. Regenerate them only if any listed artifact changes.

## Research limitation and Stage 3 boundary

The notebook currently stored at `training/train_letter_classifier.ipynb` describes a 128×128 RGB MobileNetV2 model exported to TensorFlow.js. It does not reproduce the shipped 64×64 grayscale TFLite model. Therefore:

- it is not valid evidence for how the shipped model was trained;
- approximately 94% must remain described as reference-data validation accuracy, not child-trace or test accuracy;
- the complete 454-output ordering must not be claimed as independently reproduced from the shipped model’s missing training pipeline; and
- model accuracy on children’s traces remains unknown until suitable approved samples are evaluated.

Recovering or recreating the exact training pipeline, freezing data splits, reporting proper test metrics and benchmarking device inference belong to Stage 3.

## Stage 2 decision

- Numeric-ID-to-Unicode software mapping: **PASS**
- Five deterministic mapping tests: **PASS**
- UI/scoring/storage path: **PASS by implementation and automated decision tests**
- Failure-mode wording and no-fallback scoring: **PASS**
- Fresh Android build/install/launch: **PASS**
- Five real trace observations and screen video: **EVIDENCE COLLECTION PENDING**
- Full shipped-model reproducibility: **STAGE 3 REQUIRED**

Stage 2 development is complete. Before thesis submission, collect the five real trace observations and video, and attach them to this report without changing or inflating the model-performance claim.
