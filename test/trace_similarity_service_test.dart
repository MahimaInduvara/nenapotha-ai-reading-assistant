import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/services/trace_similarity_service.dart';

Uint8List _rgba(int width, int height, Iterable<(int, int)> points) {
  final bytes = Uint8List(width * height * 4);
  for (final (x, y) in points) {
    bytes[((y * width + x) * 4) + 3] = 255;
  }
  return bytes;
}

void main() {
  group('TraceSimilarityService', () {
    const width = 20;
    const height = 20;
    final lShape = <(int, int)>[
      for (var y = 3; y <= 16; y++) (5, y),
      for (var x = 5; x <= 15; x++) (x, 16),
    ];

    test('returns a perfect score for the same normalized shape', () {
      final image = _rgba(width, height, lShape);
      final score = TraceSimilarityService.compareRgba(
        learnerRgba: image,
        standardRgba: image,
        width: width,
        height: height,
      );
      expect(score, 1);
    });

    test('normalizes position before comparing shapes', () {
      final shifted = lShape.map((point) => (point.$1 + 2, point.$2 - 1));
      final score = TraceSimilarityService.compareRgba(
        learnerRgba: _rgba(width, height, shifted),
        standardRgba: _rgba(width, height, lShape),
        width: width,
        height: height,
      );
      expect(score, greaterThan(0.95));
    });

    test('scores a different shape lower and rejects empty ink', () {
      final horizontal = <(int, int)>[for (var x = 2; x <= 17; x++) (x, 10)];
      final different = TraceSimilarityService.compareRgba(
        learnerRgba: _rgba(width, height, horizontal),
        standardRgba: _rgba(width, height, lShape),
        width: width,
        height: height,
      );
      final empty = TraceSimilarityService.compareRgba(
        learnerRgba: Uint8List(width * height * 4),
        standardRgba: _rgba(width, height, lShape),
        width: width,
        height: height,
      );
      expect(different, lessThan(0.7));
      expect(empty, 0);
    });

    test('rejects a single straight line as zero similarity', () {
      final diagonal = <(int, int)>[
        for (var y = 2; y <= 17; y++)
          for (var thickness = -1; thickness <= 1; thickness++)
            ((y ~/ 2) + 4 + thickness, y),
      ];
      final score = TraceSimilarityService.compareRgba(
        learnerRgba: _rgba(width, height, diagonal),
        standardRgba: _rgba(width, height, lShape),
        width: width,
        height: height,
      );
      expect(score, 0);
    });

    test('rejects an incomplete letter segment as zero similarity', () {
      final shortSegment = <(int, int)>[for (var y = 10; y <= 16; y++) (5, y)];
      final score = TraceSimilarityService.compareRgba(
        learnerRgba: _rgba(width, height, shortSegment),
        standardRgba: _rgba(width, height, lShape),
        width: width,
        height: height,
      );
      expect(score, 0);
    });

    test('rejects a dense scribble that fills and overlaps the guide', () {
      final denseScribble = <(int, int)>[
        for (var y = 2; y <= 18; y++)
          for (var x = 2; x <= 18; x++) (x, y),
      ];
      final score = TraceSimilarityService.compareRgba(
        learnerRgba: _rgba(width, height, denseScribble),
        standardRgba: _rgba(width, height, lShape),
        width: width,
        height: height,
      );
      expect(score, 0);
    });

    test('detects a repeated back-and-forth scribble gesture', () {
      final scribble = <Offset>[
        const Offset(4, 4),
        const Offset(16, 36),
        const Offset(7, 9),
        const Offset(18, 39),
        const Offset(8, 12),
        const Offset(20, 42),
        const Offset(9, 15),
        const Offset(21, 44),
      ];
      expect(TraceSimilarityService.isLikelyScribble([scribble]), isTrue);
    });

    test('does not reject a deliberate curved letter-like gesture', () {
      final curve = <Offset>[
        const Offset(5, 5),
        const Offset(12, 3),
        const Offset(20, 6),
        const Offset(25, 13),
        const Offset(24, 22),
        const Offset(18, 29),
        const Offset(10, 30),
        const Offset(5, 25),
        const Offset(4, 17),
      ];
      expect(TraceSimilarityService.isLikelyScribble([curve]), isFalse);
    });

    test('shows weak accidental overlap as zero percent', () {
      expect(TraceSimilarityService.credibleDisplaySimilarity(0.32), 0);
      expect(TraceSimilarityService.credibleDisplaySimilarity(0.54), 0);
      expect(TraceSimilarityService.credibleDisplaySimilarity(0.74), 0);
    });

    test('keeps a credible shape score visible', () {
      expect(TraceSimilarityService.credibleDisplaySimilarity(0.83), 0.83);
    });

    test('83 percent overlap is not verified when CNN disagrees', () {
      final verified = TraceSimilarityService.passesVerification(
        shapeSimilarity: 0.83,
        identityCheckRequired: true,
        identityMatches: false,
      );
      expect(verified, isFalse);
    });

    test('strong guide match survives an unreliable CNN disagreement', () {
      final verified = TraceSimilarityService.passesVerification(
        shapeSimilarity: 0.94,
        identityCheckRequired: true,
        identityMatches: false,
      );
      expect(verified, isTrue);
    });

    test('confirmed CNN identity still requires enough shape similarity', () {
      final verified = TraceSimilarityService.passesVerification(
        shapeSimilarity: 0.72,
        identityCheckRequired: true,
        identityMatches: true,
      );
      expect(verified, isFalse);
    });

    test('shape-only checking rejects weak accidental overlap', () {
      final rejected = TraceSimilarityService.passesVerification(
        shapeSimilarity: 0.58,
        identityCheckRequired: false,
        identityMatches: false,
      );
      final accepted = TraceSimilarityService.passesVerification(
        shapeSimilarity: 0.80,
        identityCheckRequired: false,
        identityMatches: false,
      );
      expect(rejected, isFalse);
      expect(accepted, isTrue);
    });
  });
}
