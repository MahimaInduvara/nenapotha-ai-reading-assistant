# ReadBuddy open-set CNN retraining (free Colab T4)

This experiment extends the retained 454-class CNN with class `455`, labelled
`Unknown/Invalid`. It does not overwrite the currently shipped model.

## In the Colab notebook

1. Select **Runtime > Change runtime type > T4 GPU**.
2. Upload `readbuddy_open_set_colab_package.zip` using the Files panel.
3. Run:

```python
!unzip -q /content/readbuddy_open_set_colab_package.zip -d /content/readbuddy_open_set
```

4. Confirm TensorFlow can see the T4:

```python
import tensorflow as tf
print(tf.__version__)
print(tf.config.list_physical_devices('GPU'))
```

5. Start the reproducible fine-tuning run:

```python
!python /content/readbuddy_open_set/open_set_retrain.py \
  --dataset /content/readbuddy_open_set/Dataset454 \
  --base-model /content/readbuddy_open_set/custom_cnn.keras \
  --output-dir /content/readbuddy_open_set_output \
  --seed 42 --batch-size 64 --head-epochs 2 --epochs 12 --patience 3
```

6. Download the evidence and model bundle:

```python
from google.colab import files
files.download('/content/readbuddy_open_set_output.zip')
```

Do not close the tab while a training epoch is running. Colab can disconnect,
so download the output immediately after the final cell finishes.

## Acceptance checks before app integration

- `letterOnlyAccuracy` should not materially regress from the 88.61% baseline.
- `unknownRecall` should be high enough to reject most held-out invalid marks.
- `letterFalseRejectionRate` should remain low.
- `keras_tflite_parity.json` should report near-perfect top-1 agreement.
- Keep the old app model until these checks pass.

Synthetic negatives support an open-set proof of concept. A publication or
real-world deployment must additionally evaluate consented, independently held
out child traces.
