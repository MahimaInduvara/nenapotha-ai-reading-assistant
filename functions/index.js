// functions/index.js
// Legacy server-side Sinhala letter classifier.
// Conversational answers now use Firebase AI Logic directly from Flutter.
// There is no callable chatbot function, Gemini key, or Secret Manager setup.

const functions = require('firebase-functions');
const fs = require('fs');
const path = require('path');
const tf = require('@tensorflow/tfjs-node');

// ── Sinhala Letter Classifier ────────────────────────────────────────────────
// Model trained via transfer learning (MobileNetV2) — see training/train_letter_classifier.ipynb.
// Must match IMG_SIZE from that notebook exactly, since the model's input shape is fixed at export time.
const IMG_SIZE = 128;
const MODEL_DIR = path.join(__dirname, 'model', 'tfjs_model');
const CLASS_NAMES_PATH = path.join(__dirname, 'model', 'class_names.json');

let modelPromise = null;

/** Loads the TFJS model once per Cloud Function instance and caches it across warm invocations. */
function getModel() {
  if (!modelPromise) {
    modelPromise = tf.loadLayersModel(`file://${path.join(MODEL_DIR, 'model.json')}`);
  }
  return modelPromise;
}

exports.classifySinhalaLetter = functions
  .runWith({ memory: '1GB', timeoutSeconds: 30 })
  .https.onCall(async (data, context) => {
    if (!fs.existsSync(path.join(MODEL_DIR, 'model.json'))) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Letter classifier model is not deployed yet — see training/README.md.'
      );
    }

    const { pixels, expectedLetter } = data;
    const expectedLength = IMG_SIZE * IMG_SIZE * 3;
    if (!Array.isArray(pixels) || pixels.length !== expectedLength) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `pixels must be a flat array of ${expectedLength} numbers (${IMG_SIZE}x${IMG_SIZE} RGB, 0-255 range).`
      );
    }

    const classNames = require(CLASS_NAMES_PATH);
    const model = await getModel();

    const input = tf.tensor4d(pixels, [1, IMG_SIZE, IMG_SIZE, 3]);
    const prediction = model.predict(input);
    const scores = await prediction.data();
    input.dispose();
    prediction.dispose();

    const ranked = Array.from(scores)
      .map((confidence, i) => ({ letter: classNames[i], confidence }))
      .sort((a, b) => b.confidence - a.confidence);

    const top = ranked[0];
    const expectedMatch = expectedLetter ? ranked.find((r) => r.letter === expectedLetter) : null;

    return {
      predictedLetter: top.letter,
      confidence: top.confidence,
      isCorrect: expectedLetter ? top.letter === expectedLetter : null,
      expectedConfidence: expectedMatch ? expectedMatch.confidence : null,
      topPredictions: ranked.slice(0, 3),
    };
  });
