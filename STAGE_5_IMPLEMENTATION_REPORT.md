# Stage 5 Implementation Report — Trace Evaluation Preparation

Date: 31 August 2026  
Scope: Grade 1 tracing for the five independently verified letters: අ, ආ, ක, ග, ස

## Outcome

Stage 5 preparation is implemented without collecting or uploading raw child
handwriting. Each successfully scored tracing check now stores local scalar
evidence: expected letter, predicted label, numeric class ID, output index,
confidence, native inference time, correctness, timestamp, and model version.

The parent/teacher progress screen summarizes:

- total scored tracing attempts;
- local practice accuracy;
- mean model confidence;
- mean native inference time;
- per-letter correct/attempt counts;
- unsupported and low-confidence predictions; and
- expected-versus-predicted confusion counts in the evaluation service.

## Reproducibility

The stored model version is `readbuddy-stage3-cnn-v4-ad082e94`, tied to the
evaluated TFLite SHA-256
`AD082E94B4F80F4B55D265F98C057972107DFD1D5245675CEBC1C56BA0E0B189`.
Legacy task records remain readable because all new evidence fields are
optional.

`TraceEvaluationService.buildSanitizedExport` produces a versioned JSON-ready
map containing the aggregate metrics and de-identified records. It excludes
student IDs and raw trace images. External export or publication of real-child
records still requires supervisor approval and the applicable ethics/guardian
consent process.

## Verification

- `flutter analyze`: no issues.
- `flutter test`: 17 tests passed.
- Android 14 emulator: debug APK built, installed, and launched successfully.
- Tests cover backward-compatible serialization, aggregate accuracy,
  per-letter metrics, confidence, latency, confusion counts, non-tracing task
  exclusion, and privacy fields in the sanitized export.

## How to Produce Local Practice Evidence

1. Open Grade 1 Letter Tracing.
2. Trace one of the five supported letters and tap **Check**.
3. Repeat each letter several times using adult/synthetic test traces during
   development.
4. Open **Progress → On-device Trace Evidence** to view aggregate and
   per-letter results.

## Research Boundary Before Real-Child Testing

Do not describe local practice summaries as field accuracy or learning impact.
Before involving children, confirm the protocol with the supervisor and obtain
institutional/school authorization, guardian consent, child assent, a retention
period, and a writer-grouped analysis plan. The app intentionally stores no raw
trace image in this stage.

Full Grade 1–2 coverage also remains blocked until additional dataset class IDs
are mapped to Sinhala Unicode from an authoritative source and independently
verified. Unverified classes continue to be reported only as `class:<id>` and
cannot be accepted as correct.
