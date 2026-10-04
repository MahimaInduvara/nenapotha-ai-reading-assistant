# NenaPotha AI

NenaPotha AI is a bilingual Flutter learning assistant for Grade 1 and Grade 2 primary-school learners. It combines picture-supported literacy activities, Sinhala letter tracing, graded stories and comprehension, deterministic learning guidance, learner progress analytics, and guardian/teacher-linked evidence views.

This repository contains the final-year research artifact for the project **“Design and Development of an AI-Enhanced Bilingual Reading and Comprehension Assistant for Grade 1 and Grade 2 Primary School Students.”**

## Main features

- Independent Sinhala/English interface and learning-language controls
- Grade 1 letters, words, pictures, matching, stories, and tracing
- Grade 2 pillam, word construction, progressive tasks, stories, and comprehension
- On-device 455-output open-set Sinhala handwriting CNN
- Explicit Unknown/Invalid prediction plus shape-quality checks
- Interpretable Grade 1/Grade 2 text-difficulty review signal
- Deterministic My Coach recommendations based on recorded practice evidence
- Learner progress, daily activity, guardian ownership, student codes, and linked-teacher analysis
- No child-facing chatbot, speech recognition, text-to-speech, or paid generative API

## Research evidence

- Open-set test samples: 11,296
- Overall accuracy: 98.46%
- Letter-only accuracy: 98.51%
- Macro-F1: 98.73%
- Unknown recall: 97.00%
- Invalid false-acceptance rate: 3.00%
- TensorFlow Lite top-1 parity: 100/100 registered samples
- Android 14 emulator native inference: 81.24 ms mean, 92.92 ms p95 over 30 runs
- Flutter static analysis: no issues
- Flutter unit/widget tests: 130 passed

These are technical results. No ethics-approved child learning-effectiveness trial was completed, so the repository does not claim improved literacy outcomes or writer-independent child accuracy.

## Project structure

```text
lib/screens/          Learner, learning, tracing, progress, profile, and teacher UI
lib/services/         CNN inference, quiz generation, coaching, progress, and persistence
assets/models/        Deployed TensorFlow Lite model and ordered class labels
training/             Reproducible preparation, evaluation, adaptation, and benchmark records
test/                 Flutter unit and widget regression tests
integration_test/     Android model-loading and inference benchmark
firestore.rules       Role-aware Firestore access controls
tools/                Research evidence and thesis-generation utilities
```

## Run locally

1. Install a stable Flutter SDK and Android Studio/SDK.
2. Configure an Android emulator or connected device.
3. For a different Firebase project, generate local configuration with the FlutterFire CLI and deploy the tested Firestore rules.
4. Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Security and privacy

- Raw handwriting images are not required in synchronized progress records.
- Guardian ownership and teacher links are enforced through Firestore rules.
- Environment secrets, private keys, raw datasets, captured handwriting, build outputs, and thesis deliverables are excluded from version control.
- Firebase client configuration identifies the application but does not grant administrative access; production deployments must retain secure Authentication and Firestore rules.

## Model identity

- `assets/models/sinhala_letter_model.tflite`
  - SHA-256: `6D3303F14329E72ADA074C1A5C2974506778EA2681E1F4F3704655A44973565C`
- `assets/models/class_names.txt`
  - SHA-256: `7A4E0269FB58F039EBDC247C0A6EEC76764D82351467DA4D98F93D3378935B91`

## Author

L. M. I. Silva — Student ID 28277  
BSc (Hons) Software Engineering, Faculty of Computing, NSBM Green University  
Principal Supervisor: Mr. Anton Jayakody
