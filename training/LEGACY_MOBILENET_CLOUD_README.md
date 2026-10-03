# Sinhala Letter Recognition — Training → Deploy → App

This is Layer 1's core diagnostic model: given a traced/drawn letter, predict
which Sinhala letter it actually looks like, and how confident the model is.
It's what turns `letter_tracing_screen.dart` from "did the strokes cover a
guide path" (geometric, already working) into "does an AI trained on real
handwriting agree this is the letter it should be."

Three stages, in order:

## 1. Train in Colab

Open `train_letter_classifier.ipynb` in Google Colab (upload it or open from
Drive/GitHub), set the runtime to GPU, and run the cells top to bottom.

You'll need the Kaggle Sinhala Letter dataset in an `ImageFolder` layout
(one subfolder per letter class). The notebook has two ways to pull it in —
Kaggle API or a zip on your Google Drive — pick whichever is easier for you.

Key design choices baked into the notebook (read the markdown cells for the
full reasoning):
- **128×128 input**, not MobileNetV2's default 224×224 — these are letter
  shapes, not photos, and the smaller size keeps the payload light once it's
  going over HTTP as a JSON array.
- **No flip augmentation.** Flipping a letter horizontally/vertically is
  literally the mirror-writing error this project is trying to catch
  elsewhere — augmenting with flips would train the model to ignore it.
- **Normalization is baked into the model graph** (a `Rescaling` layer, not a
  preprocessing step done separately in Python). That means the Cloud
  Function and Flutter side just send raw 0–255 pixel values — there's no
  separate normalization step to keep in sync between training and serving.
- **Frozen-base phase then a light fine-tune phase** — standard transfer
  learning: train the new head first, then unfreeze the last ~30 layers of
  MobileNetV2 with a low learning rate for a bit more accuracy.
- **Confusion analysis at the end** — prints which letter pairs the model
  mixes up most. Worth screenshotting: if the confused pairs line up with
  known diacritic-confusion pairs from your literature review, that's
  independent evidence for your Chapter 4 framing.

The last cell downloads `letter_classifier_export.zip`, containing:
- `tfjs_model/` — the exported TensorFlow.js model (a `model.json` + weight
  shard files)
- `class_names.json` — the ordered list of letter labels the model's output
  indices correspond to (critical — without this the Cloud Function can't
  map a predicted index back to an actual letter)

## 2. Deploy to the Cloud Function

The classifier is served by `classifySinhalaLetter` in `functions/index.js`,
using `@tensorflow/tfjs-node` so it runs in the same Node.js Firebase project
as the existing `chatWithReadBuddy` chat function — no separate Python
service to stand up or pay for.

```bash
# unzip the download from Colab
unzip letter_classifier_export.zip -d functions/model

# functions/model/ should now contain:
#   functions/model/tfjs_model/model.json (+ weight shards)
#   functions/model/class_names.json

cd functions
npm install   # picks up @tensorflow/tfjs-node, already added to package.json
firebase deploy --only functions:classifySinhalaLetter
```

If you deploy before `functions/model/tfjs_model/model.json` exists, the
function returns a clear `failed-precondition` error pointing back here
instead of crashing — the app's UI already handles that gracefully (see
below), so it's safe to ship the app before the model is trained.

## 3. Already wired up on the Flutter side

`lib/services/letter_classifier_service.dart` captures the student's drawn
strokes (via a `RepaintBoundary`, isolated from the guide/grid so the model
only sees the actual drawing), downsizes them to 128×128, and calls
`classifySinhalaLetter`. `letter_tracing_screen.dart` calls it automatically
every time the student taps "Check", alongside the existing geometric
coverage score — you'll see a green/red "🤖" banner under the score bar with
the AI's verdict and confidence.

If the Cloud Function isn't deployed yet (or the call fails for any reason),
that banner just doesn't show up — the geometric score keeps working
standalone, nothing breaks.

## What's still open

- **Mirror-writing classifier** — same transfer-learning recipe, trained on
  a Normal/Reversal/Corrected handwriting dataset instead. Not started.
- **Pronunciation scoring** — phoneme-level comparison, not started; no
  recording UI exists yet either.
- **On-device (TFLite)** — deliberately not done. Cloud-hosted reuses the
  exact pattern already working for Gemini chat; on-device would mean
  learning `tflite_flutter` integration under time pressure for no benefit
  at prototype stage. Good "future work" line for your defense if asked.
