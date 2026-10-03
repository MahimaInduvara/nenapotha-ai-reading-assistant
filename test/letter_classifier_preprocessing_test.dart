import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:reading_assistant_app/services/letter_classifier_service.dart';

void main() {
  group('LetterClassifierService preprocessing', () {
    test('transparent app stroke becomes white ink on black', () {
      final drawing = img.Image(width: 8, height: 8, numChannels: 4);
      for (var y = 2; y <= 5; y++) {
        for (var x = 2; x <= 5; x++) {
          drawing.setPixelRgba(x, y, 90, 70, 240, 255);
        }
      }

      final pixels = LetterClassifierService.preprocessForModel(
        img.encodePng(drawing),
      );

      expect(pixels[0], 0);
      expect(pixels[(32 * 64) + 32], greaterThan(0.95));
    });

    test('opaque training-style image keeps its grayscale polarity', () {
      final trainingImage = img.Image(width: 8, height: 8, numChannels: 3);
      for (var y = 2; y <= 5; y++) {
        for (var x = 2; x <= 5; x++) {
          trainingImage.setPixelRgb(x, y, 255, 255, 255);
        }
      }

      final pixels = LetterClassifierService.preprocessForModel(
        img.encodePng(trainingImage),
      );

      expect(pixels[0], 0);
      expect(pixels[(32 * 64) + 32], greaterThan(0.95));
    });

    test('transparent app ink is crop-normalized across canvas sizes', () {
      final smallCanvas = img.Image(width: 12, height: 12, numChannels: 4);
      final largeCanvas = img.Image(width: 30, height: 30, numChannels: 4);
      for (var y = 3; y <= 8; y++) {
        for (var x = 4; x <= 7; x++) {
          smallCanvas.setPixelRgba(x, y, 90, 70, 240, 255);
          largeCanvas.setPixelRgba(x + 11, y + 12, 90, 70, 240, 255);
        }
      }

      final small = LetterClassifierService.preprocessForModel(
        img.encodePng(smallCanvas),
      );
      final large = LetterClassifierService.preprocessForModel(
        img.encodePng(largeCanvas),
      );

      for (var index = 0; index < small.length; index++) {
        expect(large[index], closeTo(small[index], 0.001));
      }
    });
  });
}
