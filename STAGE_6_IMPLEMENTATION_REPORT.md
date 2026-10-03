# Stage 6 Implementation Report - Pilot Testing and Final Evaluation

## Status

The reproducible technical-evaluation package is complete. Adult/synthetic pilot execution and any approved child usability study remain pending; no participant results have been fabricated.

## Implemented

- Added `tools/generate_stage6_evaluation_report.py` to consolidate the protected test, model conversion, and Android emulator artifacts.
- Verified the SHA-256 identity of the evaluated, converted, benchmarked, and Flutter-bundled TFLite model.
- Calculated the held-out accuracy and 95% Wilson confidence interval from the confusion matrix.
- Generated publication-ready model comparison, training-history, class-level recall, confusion-pair, and deployment-latency figures.
- Generated exact CSV tables for per-class metrics and top confusion pairs.
- Added a de-identified pilot data template and data dictionary.
- Added a gated pilot protocol covering supervisor review, technical checks, permissions, usability testing, analysis, and progression criteria.
- Added optional analysis of the privacy-preserving Stage 5 JSON export through `--pilot-export`.

## Verified technical result

- Test images: 11,984
- Classes: 454
- Custom CNN top-1 accuracy: 88.61%
- Macro-F1: 88.14%
- Balanced accuracy: 88.11%
- Top-2 accuracy: 92.05%
- Top-3 accuracy: 93.51%
- Keras/TFLite top-1 agreement: 99.0% on 100 parity samples
- Android 14 emulator native inference mean: 83.58 ms
- Android 14 emulator native inference p95: 140.79 ms
- Model SHA-256: `ad082e94b4f80f4b55d265f98c057972107dfd1d5245675cebc1c56ba0e0b189`

## Reproduce

```powershell
python tools\generate_stage6_evaluation_report.py
```

With a sanitized Stage 5 trace export:

```powershell
python tools\generate_stage6_evaluation_report.py --pilot-export path\to\trace_export.json
```

## Research boundary

The 88.61% result is held-out dataset performance. Emulator timings are deployment evidence. Neither is evidence of classroom learning gains or child usability. Child testing requires the supervisor and all applicable ethics, school, guardian-consent, and child-assent approvals before collection.
