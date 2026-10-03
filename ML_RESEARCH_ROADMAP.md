# ML Research Roadmap — ReadBuddy AI

This is a plan for extending the ML/research side of the project beyond the
current single letter-recognition model. It builds directly on
`training/README.md` (which already flags mirror-writing detection,
pronunciation scoring, and on-device inference as open items) and on the
existing `classifySinhalaLetter` Cloud Function pipeline
(`training/train_letter_classifier.ipynb` → `functions/index.js` →
`lib/services/letter_classifier_service.dart`).

Everything here is scoped for a final-year thesis: each section calls out
what it gives you for **Chapter 4 (Results)** or **Chapter 5
(Discussion/Future Work)**, since "does this produce a defensible number or
figure" is the real constraint, not just "is this a good ML idea."

---

## 0. Current state (baseline)

- One model: MobileNetV2 transfer learning, 128×128 input, frozen-base →
  fine-tune, trained on the Kaggle Sinhala Letter dataset.
- Evaluation is a single train/val split (`validation_split=0.15`) — **no
  held-out test set**, so the reported accuracy is technically a validation
  metric, not a generalization estimate.
- Evaluation output is just overall accuracy + a printed list of the top
  15 confused `(true, predicted)` pairs. No per-class precision/recall,
  no confidence calibration, no visualization.
- Predictions made in production (via `classifySinhalaLetter`) are **not
  logged anywhere** — every inference is thrown away after the response is
  returned. There is no way to know today how the model performs on real
  children's drawings vs. the Kaggle dataset it was trained on.
- No model versioning — `functions/model/` just holds whatever was last
  unzipped there, with no record of which notebook run / hyperparameters /
  dataset version produced it.

These four gaps are the highest-leverage things to fix before adding new
models, because they're what turn "I trained a model" into "here is
evidence my model works," which is what a thesis committee actually asks
about.

---

## 1. Rigorous evaluation framework (do this first)

**Why first:** every other section below produces a model or a claim that
needs to be measured by *something*. Build the ruler before building more
things to measure.

- **Add a real held-out test set.** Split into train/val/test (e.g.
  70/15/15) instead of train/val only. Val is for early stopping / choosing
  when to stop fine-tuning; test is only touched once, at the end, for the
  number that goes in the thesis.
- **Per-class precision/recall/F1**, plus macro-F1 and weighted-F1
  (`sklearn.metrics.classification_report`). Overall accuracy hides classes
  that are doing badly if the dataset is imbalanced across letters — worth
  checking directly.
- **Confusion matrix heatmap** (not just a printed top-15 list) —
  `sklearn.metrics.ConfusionMatrixDisplay` or seaborn. This is the
  screenshot-for-the-thesis artifact the README already anticipates; a
  heatmap makes diacritic-confusion clusters visually obvious in a way a
  text list doesn't.
- **Top-k accuracy** (top-2, top-3) — relevant here specifically because
  the Cloud Function already returns `topPredictions` (top 3) to the app.
  If top-1 is mediocre but top-3 is strong, that's a legitimate finding
  ("the model usually has the right answer in its top 3, suggesting X").
- **Confidence calibration.** The app shows the model's confidence number
  directly to students/teachers (`expectedConfidence`, the 🤖 banner). A
  reliability diagram (predicted confidence vs. actual accuracy, binned)
  tells you whether "90% confident" actually means "right 90% of the
  time" — often it doesn't for transfer-learning models, and if not, that's
  worth reporting rather than presenting confidence as if it were a
  calibrated probability.
- **Grad-CAM explainability.** Overlay which pixels of a drawn letter drove
  the prediction. For education research this is a strong Chapter 4/5
  artifact: you can show *why* the model confused two letters (e.g. it
  focused on a diacritic mark) rather than just *that* it confused them.

**Effort:** ~1 notebook session. All additions to the existing evaluation
cell in `train_letter_classifier.ipynb` (section 7) — no changes to
`functions/index.js` or the app needed.

---

## 2. Field-accuracy logging (lab data vs. real data)

**Why:** the model is trained on the Kaggle dataset (adult-collected,
presumably stylus/mouse-drawn reference letters). The app's actual input is
children's fingertip/mouse drawings on a canvas mid-lesson. Those are not
the same distribution, and right now there's no way to measure the gap.

- **Log every classification call** in `classifySinhalaLetter`
  (`functions/index.js`) to a new Firestore collection, e.g.
  `letterClassifications`: predicted letter, expected letter, confidence,
  full ranked list, timestamp, gradeLevel, and an anonymized/hashed student
  ref (not the raw student doc, to keep this low-sensitivity). This is the
  same "log what the model saw for later analysis" pattern already used for
  unmatched chat questions (`qaUnmatched` in the same file) — consistent
  with the codebase's existing approach.
- **Periodically export and score against ground truth.** Since
  `expectedLetter` is already passed in from the tracing screen, you get
  *free* ground-truth labels on every real classification — no separate
  annotation effort needed. Compute field accuracy the same way you compute
  validation accuracy, then compare the two directly: "Kaggle validation
  accuracy: X% vs. in-app field accuracy: Y%" is a strong, honest Chapter 4
  result about generalization gap.
- **Build a "hard examples" queue.** Low-confidence or expected≠predicted
  cases, flagged automatically, become candidate examples for a future
  fine-tuning round on real in-app data — i.e. the beginning of an active
  learning loop, and a legitimate "future work" section.
- **Privacy note:** since this touches real children's data, keep the
  logged record minimal (no raw images unless you add explicit
  parent/teacher consent for that — see the pixel array is already
  ephemeral today, and it's worth deciding deliberately whether to persist
  it or only persist the scalar outcome).

**Effort:** small Cloud Function change (add one `db.collection(...).add()`
call) + a follow-up analysis notebook/script that reads the collection.

---

## 3. New diagnostic models (the two items already flagged as "not started")

### 3a. Mirror-writing / letter-reversal classifier
- Same transfer-learning recipe as the letter classifier, but trained on a
  Normal / Reversed / Corrected handwriting dataset instead of per-letter
  classes. This is a distinct and pedagogically important signal from "is
  this the right letter" — reversal patterns are a commonly cited
  early-dyslexia indicator in the literature, which is presumably part of
  your lit review already.
- Reuse almost the entire pipeline: same notebook structure, same
  128×128/no-flip-augmentation reasoning (in fact *more* important here,
  since flips are literally the label you're trying to detect — the
  existing "no flip augmentation" comment in the notebook explains exactly
  why), same TFJS export → Cloud Function → Flutter service pattern as
  `letter_classifier_service.dart`.
- Smallest new-model effort in this roadmap because the infrastructure
  (Cloud Function hosting pattern, TFJS loading, Flutter capture-and-send
  code) already exists and just needs to be duplicated/parameterized rather
  than built from scratch.

### 3b. Pronunciation / fluency scoring model
- Bigger lift — no recording UI exists yet (the app currently uses
  `speech_to_text` for STT input elsewhere, but not for a scored recording
  flow). Needs: a recording screen, reference audio/phoneme alignment, and
  a scoring model or rubric.
- Two viable approaches depending on remaining time budget:
  1. **Lightweight first**: use `speech_to_text`'s transcript vs. expected
     text (edit distance / word-level accuracy) as a proxy score — no new
     model needed, just a scoring function. Gets `pronunciationSi` /
     `pronunciationEn` in `student_progress.dart` filled with real data
     (currently hardcoded to `accuracy: 0.0` in `activity_service.dart`).
  2. **Research-grade**: phoneme-level comparison (e.g. forced alignment
     via a pretrained ASR model, comparing phoneme timing/confidence
     against a reference). Substantially more work; only worth it if
     pronunciation is a core research question rather than a supporting
     feature.
- Recommend starting with (1) to get a working, measurable feature, and
  treating (2) as a stretch goal / future-work item if time allows —
  mirrors the same "ship the honest simple thing, flag the fancy version as
  future work" pattern already used for the letter classifier's on-device
  question.

---

## 4. Model comparison / ablation study

A thesis benefits from showing *why* MobileNetV2 was the right call, not
just that it works. Cheap to add once section 1's evaluation harness
exists, since it's the same metrics run against different variants:

- **Architecture comparison**: MobileNetV2 vs. a small custom CNN trained
  from scratch vs. EfficientNet-Lite/MobileNetV3. Compare accuracy, model
  size, and inference latency (relevant since this runs as a Cloud Function
  with a cold-start/timeout budget — `timeoutSeconds: 30` in
  `functions/index.js`).
- **Augmentation ablation**: with vs. without rotation/zoom/contrast
  augmentation, and (as a deliberate negative control matching the
  project's own reasoning) with vs. without flip augmentation — you already
  have the hypothesis ("flips hurt because they teach the model to ignore
  the mirror-writing signal"); this turns it from an assumption stated in a
  comment into a measured result.
- **Frozen-base-only vs. fine-tuned**: the notebook already does both
  phases sequentially but only reports final accuracy. Reporting
  phase-1-only vs. phase-1+2 accuracy side by side quantifies what
  fine-tuning actually bought you.
- **Statistical significance**: for any "model A vs. model B" claim on the
  same test set, a McNemar's test (not just eyeballing accuracy deltas) is
  standard practice and an easy addition (`statsmodels.stats.contingency_tables.mcnemar`).

**Effort:** mostly re-running the same notebook with different config cells
once section 1 exists; the marginal cost per variant is low.

---

## 5. Subgroup / fairness analysis

Worth doing given the target population is children across multiple grade
levels:

- Stratify accuracy by **grade level** (1–5, already tracked throughout the
  app — `gradeLevel` is passed into the classifier call already).
- Stratify by **input device type** if determinable (touchscreen vs.
  mouse/trackpad) — drawing dynamics differ a lot between the two, and the
  Kaggle training data likely reflects one mode more than the other.
- If the field-logging from section 2 is in place, this is just a
  `groupby` on the logged collection — near-zero additional engineering
  once that exists.

---

## 6. Model versioning & deployment hygiene

Small but improves reproducibility, which reviewers/examiners do check:

- Add a `model_card.json` alongside `class_names.json` in each export:
  training date, dataset version/size, hyperparameters, phase-1 and
  phase-2 epoch counts, final test-set metrics from section 1. One extra
  cell at the end of the notebook.
- Keep exported model zips named/dated (`letter_classifier_v1_2026-08.zip`)
  rather than overwriting `functions/model/` in place, so you can roll back
  or diff between versions if a retrain regresses accuracy.

---

## 7. On-device (TFLite) — as a benchmark, not a rebuild

`training/README.md` already explains why on-device was deliberately
skipped for the shipping app (time pressure, no benefit at prototype
stage). That reasoning still holds for the product — but as a **research
side-experiment** it's cheap to add now that section 1's harness exists:
export the same trained model to TFLite and benchmark inference
latency/size against the current Cloud Function round-trip. This gives you
a real number for the "future work: on-device inference" line instead of
an assumption, without committing to actually integrating `tflite_flutter`
into the app.

---

## Suggested priority order

1. **Section 1** (evaluation framework) — prerequisite for everything else,
   ~1 session.
2. **Section 2** (field-accuracy logging) — cheap, starts collecting real
   data immediately so you're not blocked later waiting for volume.
3. **Section 3a** (mirror-writing classifier) — highest research value per
   unit effort, reuses existing infrastructure almost entirely.
4. **Section 4** (ablation study) — once section 1 exists, mostly free.
5. **Section 6** (model cards/versioning) — do alongside 3a so the new
   model starts with proper records from day one.
6. **Section 5** (subgroup analysis) — after section 2 has accumulated some
   field data.
7. **Section 3b** (pronunciation scoring) — start with the lightweight
   transcript-diff version if time is short.
8. **Section 7** (TFLite benchmark) — lowest priority, nice-to-have future-
   work evidence.

## Explicitly out of scope here

This roadmap only covers the ML/model side. Consent flows for logging real
children's drawings/audio, IRB/ethics-committee paperwork, and the
statistical write-up for the thesis itself are separate concerns not
addressed above — flag them to your supervisor if section 2 or 3b's data
collection would need formal consent beyond what's already in place for the
app.
