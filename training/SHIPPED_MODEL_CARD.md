# ReadBuddy Sinhala Letter CNN Model Card

Pipeline version: `readbuddy-stage3-cnn-v4`  
Created: 2026-08-30 12:26:13 +0530  
Intended scope: Sinhala handwriting research and the five exposed Grade 1 tracing letters.  
Not intended for clinical diagnosis, high-stakes assessment, or unsupported Grade 3 claims.

## Data

- Dataset root supplied by operator: `training\datasets\sinhala_letter_454\Dataset454`
- Frozen manifest SHA-256: `1342dee4954eab8dfc4c5c59d667efa6ef6dc99104bd35a3989489d24b726da7`
- Seed: `42`
- Samples: 79788
- Classes: 454
- Split counts: `{'test': 11984, 'train': 55820, 'validation': 11984}`
- Duplicate bytes are kept within one split; cross-class duplicate bytes cause failure.

## Preprocessing

- Decode as one grayscale channel.
- Resize to 64×64 with antialiasing.
- Scale pixel values to `[0,1]`.
- No horizontal or vertical flips.

## Architecture

`Conv32(3×3 valid) → MaxPool2 → Conv64(3×3 valid) → MaxPool2 → Conv128(3×3 valid) → Flatten(18,432) → Dense128 → Dropout(0.3) → Dense(454)/Softmax`

The inference dimensions match the shipped TFLite FlatBuffer. The original training-time dropout and optimizer state were not recoverable; they are explicit choices in this reproduction.

## Training

- Optimizer: Adam, learning rate `0.001`
- Loss: sparse categorical cross-entropy
- Maximum epochs: `40`
- Batch size: `64`
- Early stopping monitors validation loss and restores best weights.

## Held-out test results

Custom CNN: `{"accuracy": 0.8860981308411215, "balancedAccuracy": 0.8811315363239457, "expectedCalibrationError10Bins": 0.051527672447264215, "logLoss": 0.7319226067103745, "macroF1": 0.8814452186481908, "macroPrecision": 0.8886217946334989, "macroRecall": 0.8811315363239457, "model": "custom_cnn", "testSamples": 11984, "top2Accuracy": 0.920477303070761, "top3Accuracy": 0.9350801068090788}`

Compact baseline: `{"accuracy": 0.0025033377837116156, "balancedAccuracy": 0.0022026431718061676, "expectedCalibrationError10Bins": 5.006275882071592e-05, "logLoss": 6.111751258416748, "macroF1": 1.1000382079937577e-05, "macroPrecision": 5.513959876016774e-06, "macroRecall": 0.0022026431718061676, "model": "compact_cnn_baseline", "testSamples": 11984, "top2Accuracy": 0.004923230974632844, "top3Accuracy": 0.007343124165554072}`

## Conversion parity

`{"hostEndToEndMillisecondsPerSample": 1.1153260001447052, "inputDtype": "<class 'numpy.float32'>", "inputShape": [1, 64, 64, 1], "maximumAbsoluteProbabilityDifference": 0.08337920904159546, "meanAbsoluteProbabilityDifference": 2.7619642423815094e-05, "outputDtype": "<class 'numpy.float32'>", "outputShape": [1, 454], "samples": 100, "tfliteBytes": 2527920, "tfliteSha256": "ad082e94b4f80f4b55d265f98c057972107dfd1d5245675cebc1c56ba0e0b189", "top1Agreement": 0.99}`

## Limitations

- Performance applies only to the frozen test manifest and must not be generalized to children's traces without a separately approved child-trace evaluation.
- The numeric-ID-to-Unicode mapping is independently verified in the application only for අ, ආ, ක, ග and ස.
- Confidence is a model score; calibration metrics must be reviewed before interpreting it probabilistically.
- Dataset licensing, consent and demographic coverage must be checked before redistribution or field deployment.
