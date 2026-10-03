import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:reading_assistant_app/services/letter_classifier_service.dart';

Uint8List _syntheticTracePng() {
  final canvas = img.Image(width: 128, height: 128, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  for (var y = 18; y < 110; y++) {
    final x = 34 + ((y - 18) * 42 ~/ 92);
    for (var thickness = -4; thickness <= 4; thickness++) {
      final pixelX = x + thickness;
      if (pixelX >= 0 && pixelX < canvas.width) {
        canvas.setPixelRgb(pixelX, y, 0, 0, 0);
      }
    }
  }
  for (var x = 32; x < 94; x++) {
    for (var thickness = -4; thickness <= 4; thickness++) {
      canvas.setPixelRgb(x, 70 + thickness, 0, 0, 0);
    }
  }
  return Uint8List.fromList(img.encodePng(canvas));
}

double _percentile(List<int> sortedMicros, double fraction) {
  final index = ((sortedMicros.length - 1) * fraction).round();
  return sortedMicros[index] / 1000.0;
}

double _meanMilliseconds(List<int> micros) =>
    micros.reduce((left, right) => left + right) / micros.length / 1000.0;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('benchmarks bundled CNN on the Android runtime', (tester) async {
    const warmupRuns = 5;
    const measuredRuns = 30;
    final service = LetterClassifierService();
    final loadStopwatch = Stopwatch()..start();
    await service.loadModel();
    loadStopwatch.stop();

    final runtimeInfo = service.runtimeInfo;
    expect(runtimeInfo, isNotNull);
    expect(runtimeInfo!.inputShape, [1, 64, 64, 1]);
    expect(runtimeInfo.inputType, 'float32');
    expect(runtimeInfo.outputShape, [1, 455]);
    expect(runtimeInfo.outputType, 'float32');
    expect(runtimeInfo.classCount, 455);

    final input = _syntheticTracePng();
    for (var run = 0; run < warmupRuns; run++) {
      await service.predict(input);
    }

    final endToEndMicros = <int>[];
    final nativeMicros = <int>[];
    LetterPrediction? lastPrediction;
    for (var run = 0; run < measuredRuns; run++) {
      final stopwatch = Stopwatch()..start();
      lastPrediction = await service.predict(input);
      stopwatch.stop();
      endToEndMicros.add(stopwatch.elapsedMicroseconds);
      nativeMicros.add(service.lastInferenceDuration!.inMicroseconds);
    }
    endToEndMicros.sort();
    nativeMicros.sort();

    expect(lastPrediction, isNotNull);
    expect(lastPrediction!.classId, inInclusiveRange(1, 455));
    expect(lastPrediction.confidence, inInclusiveRange(0.0, 1.0));

    final report = <String, dynamic>{
      'benchmark': 'ReadBuddy bundled CNN emulator/device runtime',
      'input': 'synthetic 128x128 black trace on white PNG; not accuracy data',
      'warmupRuns': warmupRuns,
      'measuredRuns': measuredRuns,
      'modelLoadMilliseconds': loadStopwatch.elapsedMicroseconds / 1000.0,
      'nativeInferenceMilliseconds': {
        'mean': _meanMilliseconds(nativeMicros),
        'p50': _percentile(nativeMicros, 0.50),
        'p95': _percentile(nativeMicros, 0.95),
        'minimum': nativeMicros.first / 1000.0,
        'maximum': nativeMicros.last / 1000.0,
      },
      'endToEndMilliseconds': {
        'mean': _meanMilliseconds(endToEndMicros),
        'p50': _percentile(endToEndMicros, 0.50),
        'p95': _percentile(endToEndMicros, 0.95),
        'minimum': endToEndMicros.first / 1000.0,
        'maximum': endToEndMicros.last / 1000.0,
      },
      'runtime': {
        'operatingSystem': Platform.operatingSystem,
        'operatingSystemVersion': Platform.operatingSystemVersion,
        'dartVersion': Platform.version,
      },
      'model': runtimeInfo.toJson(),
      'lastPrediction': {
        'classId': lastPrediction.classId,
        'outputIndex': lastPrediction.outputIndex,
        'confidence': lastPrediction.confidence,
      },
    };
    binding.reportData = report;
    debugPrint('STAGE3_DEVICE_BENCHMARK_JSON=${jsonEncode(report)}');
    service.dispose();
  });
}
