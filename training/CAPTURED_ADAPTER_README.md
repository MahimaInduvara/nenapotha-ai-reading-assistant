# ReadBuddy captured-trace adapter (pilot)

This package adapts the retained 455-class open-set CNN to the de-identified
traces captured from the Flutter drawing canvas. It preserves the deployed
`float32 [1,64,64,1] -> float32 [1,455]` contract and label IDs.

## Run on free Google Colab

1. Open `adapt_captured_traces_colab.ipynb` in Google Colab.
2. Select a T4 GPU runtime if one is available.
3. Run all cells and upload `readbuddy_captured_adapter_colab_v2.zip` when
   prompted.
4. Download the generated `readbuddy_captured_adapter_output.zip`.
5. Do **not** replace the Flutter asset unless `deploymentGatePassed` is true.

## Evidence and limitations

- The package contains a deterministic compact replay subset of the original
  train/valid/test directories. The original split boundaries are preserved.
- Captured samples with verified numeric IDs are training data only.
- Captured samples without a verified ID are listed in the report and are not
  forced into an incorrect class.
- All current captured samples belong to one anonymous writer. Consequently,
  `capturedTrainingFit` is not independent accuracy and must not be reported as
  child-generalisation evidence.
- Invalid samples are synthetic because no real invalid samples were captured.
- The adapter is a pilot. A defensible final model needs multiple writers and a
  writer-disjoint captured test set.

The output bundle contains the TFLite model, unchanged numeric class-name
mapping, Keras checkpoint, epoch log, model card, SHA-256 hashes, before/after
regression metrics, and Keras/TFLite parity evidence.
