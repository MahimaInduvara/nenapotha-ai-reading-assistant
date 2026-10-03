# Stage 7 Implementation Report - Physical-Device Pilot

## Status

The physical-device benchmark workflow is implemented and validated. Execution is waiting for a physical Android phone to be connected. No physical-device or participant results have been created.

## Implemented

- Added `tools/run_stage7_physical_pilot.ps1`.
- Detects supported physical Android phones through Flutter.
- Rejects desktop, web, and emulator targets.
- Requires an explicit device ID if multiple phones are attached.
- Runs the existing bundled-CNN integration benchmark with 5 warm-up and 30 measured runs.
- Captures the raw benchmark log and structured JSON result.
- Verifies the bundled TFLite SHA-256 against the evaluated model hash.
- Marks the evidence as synthetic-input runtime data, not recognition accuracy or child-study evidence.
- Added setup, execution, adult/synthetic pilot, and research-ethics instructions.

## Current blocker

`flutter devices` detected Windows, Chrome, and Edge only. Connect and authorize a physical Android phone, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_stage7_physical_pilot.ps1
```

Expected output after a successful run:

- `deliverables/stage7_physical_device/physical_device_benchmark.json`
- `deliverables/stage7_physical_device/physical_benchmark_<timestamp>.log`

## Research boundary

The automated benchmark uses synthetic input and measures runtime performance only. Adult/synthetic tracing attempts are the next technical pilot. Testing children remains prohibited until all required approvals and consent/assent processes are complete.
