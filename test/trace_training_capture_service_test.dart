import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:reading_assistant_app/services/trace_training_capture_service.dart';

void main() {
  group('TraceTrainingCaptureService', () {
    test('sanitizes anonymous writer IDs', () {
      expect(
        TraceTrainingCaptureService.safeWriterId(' Writer 01 '),
        'writer_01',
      );
      expect(
        TraceTrainingCaptureService.safeWriterId('child/name@example.com'),
        'child_name_example_com',
      );
    });

    test('creates stable Unicode target keys', () {
      expect(
        TraceTrainingCaptureService.labelKey('කා', kind: 'combined'),
        'combined_u0d9a_u0dcf',
      );
      expect(
        TraceTrainingCaptureService.labelKey(
          TraceTrainingCaptureService.unknownLabel,
          kind: 'invalid',
        ),
        TraceTrainingCaptureService.unknownLabel,
      );
    });

    test('produces the exact 64x64 CNN input image contract', () {
      final raw = img.Image(width: 128, height: 128, numChannels: 4);
      for (var y = 25; y < 105; y++) {
        for (var x = 56; x < 72; x++) {
          raw.setPixelRgba(x, y, 91, 76, 240, 255);
        }
      }

      final encoded = Uint8List.fromList(img.encodePng(raw));
      final modelInput = TraceTrainingCaptureService.modelInputPng(encoded);
      final decoded = img.decodePng(modelInput);

      expect(decoded, isNotNull);
      expect(decoded!.width, TraceTrainingCaptureService.modelInputSize);
      expect(decoded.height, TraceTrainingCaptureService.modelInputSize);

      var brightPixels = 0;
      for (final pixel in decoded) {
        if (pixel.r > 127) brightPixels++;
      }
      expect(brightPixels, greaterThan(0));
      expect(brightPixels, lessThan(decoded.width * decoded.height));
    });
  });
}
