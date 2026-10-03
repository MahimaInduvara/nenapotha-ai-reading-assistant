[CmdletBinding()]
param(
    [string]$DeviceId,
    [string]$OutputDirectory = "deliverables\stage7_physical_device"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$resolvedOutput = Join-Path $projectRoot $OutputDirectory
$modelPath = Join-Path $projectRoot "assets\models\sinhala_letter_model.tflite"
$classNamesPath = Join-Path $projectRoot "assets\models\class_names.txt"
$benchmarkTest = "integration_test\cnn_runtime_benchmark_test.dart"

Set-Location -LiteralPath $projectRoot

$deviceJson = (& flutter devices --machine) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    throw "Unable to query Flutter devices."
}
$devices = @($deviceJson | ConvertFrom-Json)
$physicalAndroidDevices = @(
    $devices | Where-Object {
        $_.isSupported -eq $true -and
        $_.targetPlatform -like "android-*" -and
        $_.emulator -eq $false
    }
)

if ($DeviceId) {
    $selected = $physicalAndroidDevices | Where-Object { $_.id -eq $DeviceId } | Select-Object -First 1
    if (-not $selected) {
        throw "Device '$DeviceId' is not a detected physical Android device."
    }
} elseif ($physicalAndroidDevices.Count -eq 1) {
    $selected = $physicalAndroidDevices[0]
} elseif ($physicalAndroidDevices.Count -eq 0) {
    Write-Host "No physical Android phone detected." -ForegroundColor Yellow
    Write-Host "1. Connect the phone with a data-capable USB cable."
    Write-Host "2. Enable Developer options and USB debugging."
    Write-Host "3. Unlock the phone and accept the RSA debugging prompt."
    Write-Host "4. Run 'flutter devices' and then run this script again."
    exit 2
} else {
    $ids = ($physicalAndroidDevices | ForEach-Object { $_.id }) -join ", "
    throw "Multiple physical Android devices detected ($ids). Re-run with -DeviceId <id>."
}

New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$logPath = Join-Path $resolvedOutput "physical_benchmark_$timestamp.log"

Write-Host "Running benchmark on physical device: $($selected.name) [$($selected.id)]"
& flutter test $benchmarkTest -d $selected.id 2>&1 | Tee-Object -FilePath $logPath
$testExitCode = $LASTEXITCODE
if ($testExitCode -ne 0) {
    throw "Physical-device benchmark failed with exit code $testExitCode. See $logPath"
}

$benchmarkLine = Get-Content -LiteralPath $logPath |
    Where-Object { $_ -match "STAGE3_DEVICE_BENCHMARK_JSON=" } |
    Select-Object -Last 1
if (-not $benchmarkLine) {
    throw "Benchmark JSON marker was not found in $logPath"
}
$benchmarkJson = $benchmarkLine.Substring(
    $benchmarkLine.IndexOf("STAGE3_DEVICE_BENCHMARK_JSON=") + "STAGE3_DEVICE_BENCHMARK_JSON=".Length
)
$benchmark = $benchmarkJson | ConvertFrom-Json

$modelHash = (Get-FileHash -LiteralPath $modelPath -Algorithm SHA256).Hash.ToLowerInvariant()
$classNamesHash = (Get-FileHash -LiteralPath $classNamesPath -Algorithm SHA256).Hash.ToLowerInvariant()
$expectedModelHash = "ad082e94b4f80f4b55d265f98c057972107dfd1d5245675cebc1c56ba0e0b189"
if ($modelHash -ne $expectedModelHash) {
    throw "Bundled model hash changed. Expected $expectedModelHash but found $modelHash."
}

$report = [ordered]@{
    schemaVersion = "readbuddy-stage7-physical-benchmark-v1"
    recordedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    evidenceScope = "Physical Android runtime benchmark using synthetic input; not recognition accuracy or child-study data."
    physicalDevice = $true
    flutterDevice = [ordered]@{
        name = $selected.name
        id = $selected.id
        targetPlatform = $selected.targetPlatform
        sdk = $selected.sdk
        emulator = $selected.emulator
    }
    artifactIdentity = [ordered]@{
        modelPath = "assets/models/sinhala_letter_model.tflite"
        modelSha256 = $modelHash
        classNamesPath = "assets/models/class_names.txt"
        classNamesSha256 = $classNamesHash
    }
    benchmark = $benchmark
    rawLog = (Resolve-Path -LiteralPath $logPath).Path
    testExitCode = $testExitCode
}

$reportPath = Join-Path $resolvedOutput "physical_device_benchmark.json"
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $reportPath -Encoding utf8

Write-Host "Physical-device benchmark passed." -ForegroundColor Green
Write-Host "Report: $reportPath"
Write-Host ("Native inference mean: {0:N2} ms" -f $benchmark.nativeInferenceMilliseconds.mean)
Write-Host ("Native inference p95: {0:N2} ms" -f $benchmark.nativeInferenceMilliseconds.p95)
Write-Host "Model SHA-256: $modelHash"
