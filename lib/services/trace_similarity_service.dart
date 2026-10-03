import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

/// Compares a learner's traced glyph with a rendered standard glyph.
///
/// Both RGBA images are converted to binary ink masks, cropped to their ink
/// bounds, normalized to the same grid, and compared with a tolerance-aware
/// Dice score. An aligned coverage check prevents a short or straight mark
/// from receiving credit merely because independent scaling made it large.
/// This measures visual shape similarity; it is deliberately kept
/// separate from the CNN's class confidence, which answers a different
/// question ("which letter is this?").
abstract final class TraceSimilarityService {
  static const String version = 'readbuddy-shape-similarity-v6';
  static const double _shapeOnlyCredibilityFloor = 0.75;
  static const double _cnnDisagreementCredibilityFloor = 0.90;
  static const int _gridSize = 64;
  static const int _padding = 6;
  static const int _toleranceRadius = 3;

  /// Rejects rapid back-and-forth pen movement before image classification.
  ///
  /// The letter CNN has no "unknown" class, so every random drawing is mapped
  /// to the nearest known letter. Genuine tracing can contain curves and a few
  /// turns, but repeated near-180-degree reversals and excessive travel inside
  /// a small area are strong observable evidence of a scribble.
  static bool isLikelyScribble(List<List<Offset>> strokes) {
    final meaningful = strokes
        .where((stroke) => stroke.length >= 2)
        .map(_simplifyStroke)
        .where((stroke) => stroke.length >= 2)
        .toList();
    if (meaningful.isEmpty) return false;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var totalLength = 0.0;
    var reversals = 0;
    var sharpTurns = 0;

    for (final stroke in meaningful) {
      for (final point in stroke) {
        minX = math.min(minX, point.dx);
        minY = math.min(minY, point.dy);
        maxX = math.max(maxX, point.dx);
        maxY = math.max(maxY, point.dy);
      }
      for (var i = 1; i < stroke.length; i++) {
        totalLength += (stroke[i] - stroke[i - 1]).distance;
      }
      for (var i = 1; i < stroke.length - 1; i++) {
        final incoming = stroke[i] - stroke[i - 1];
        final outgoing = stroke[i + 1] - stroke[i];
        if (incoming.distance < 3 || outgoing.distance < 3) continue;
        final cosine =
            ((incoming.dx * outgoing.dx) + (incoming.dy * outgoing.dy)) /
            (incoming.distance * outgoing.distance);
        if (cosine < -0.55) {
          reversals++;
        } else if (cosine < -0.10) {
          sharpTurns++;
        }
      }
    }

    final diagonal = math.sqrt(
      math.pow(maxX - minX, 2) + math.pow(maxY - minY, 2),
    );
    if (diagonal < 1) return false;
    final travelRatio = totalLength / diagonal;
    return (reversals >= 3 && travelRatio >= 3.8) ||
        (reversals >= 2 && sharpTurns >= 4 && travelRatio >= 5.0) ||
        travelRatio >= 11.0;
  }

  static List<Offset> _simplifyStroke(List<Offset> stroke) {
    final simplified = <Offset>[stroke.first];
    for (final point in stroke.skip(1)) {
      if ((point - simplified.last).distance >= 4) simplified.add(point);
    }
    if (simplified.last != stroke.last) simplified.add(stroke.last);
    return simplified;
  }

  static double compareRgba({
    required Uint8List learnerRgba,
    required Uint8List standardRgba,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) return 0;
    final expectedLength = width * height * 4;
    if (learnerRgba.lengthInBytes != expectedLength ||
        standardRgba.lengthInBytes != expectedLength) {
      throw ArgumentError('RGBA buffers must match width × height × 4.');
    }

    final learnerRaw = _alphaMask(learnerRgba, width, height);
    final standardRaw = _alphaMask(standardRgba, width, height);
    final learnerRawCount = _count(learnerRaw.pixels);
    final standardRawCount = _count(standardRaw.pixels);
    if (learnerRawCount == 0 || standardRawCount == 0) return 0;

    // Reject dense scribbles and gross overdraw before normalization. A CNN
    // always returns its nearest known class because it has no "unknown"
    // output; a filled or repeatedly-scribbled region must therefore be
    // rejected from observable trace evidence rather than trusted as a
    // letter. Correct tracing uses roughly the same amount and spread of ink
    // as the rendered guide, with generous margins for a child's thick pen.
    final learnerBounds = _inkBounds(learnerRaw);
    final standardBounds = _inkBounds(standardRaw);
    if (learnerBounds == null || standardBounds == null) return 0;
    final inkRatio = learnerRawCount / standardRawCount;
    final boundsAreaRatio = learnerBounds.area / standardBounds.area;
    final learnerAspect = learnerBounds.width / learnerBounds.height;
    final standardAspect = standardBounds.width / standardBounds.height;
    final aspectRatioMismatch = math.max(
      learnerAspect / standardAspect,
      standardAspect / learnerAspect,
    );
    final learnerDensity = learnerRawCount / learnerBounds.area;
    final standardDensity = standardRawCount / standardBounds.area;
    if (inkRatio < 0.18 || inkRatio > 2.15) return 0;
    if (boundsAreaRatio < 0.20 || boundsAreaRatio > 2.20) return 0;
    if (aspectRatioMismatch > 1.80) return 0;
    if (learnerDensity > math.max(0.48, standardDensity * 1.85)) return 0;

    // A single pen line is not a completed Sinhala glyph. Previously each
    // mask was enlarged independently, allowing such a line to score around
    // 50% against letters that contain a long vertical or diagonal segment.
    if (_isNearlyStraight(learnerRaw)) return 0;

    final learner = _normalize(learnerRaw);
    final standard = _normalize(standardRaw);
    final learnerCount = _count(learner);
    final standardCount = _count(standard);
    if (learnerCount == 0 || standardCount == 0) return 0;

    final learnerTolerance = _dilate(learner, _toleranceRadius);
    final standardTolerance = _dilate(standard, _toleranceRadius);

    var learnerNearStandard = 0;
    var standardNearLearner = 0;
    for (var i = 0; i < learner.length; i++) {
      if (learner[i] && standardTolerance[i]) learnerNearStandard++;
      if (standard[i] && learnerTolerance[i]) standardNearLearner++;
    }

    final precision = learnerNearStandard / learnerCount;
    final recall = standardNearLearner / standardCount;
    if (precision + recall == 0) return 0;
    final normalizedDice = 2 * precision * recall / (precision + recall);

    // Because the learner traces over the displayed guide, both raw masks
    // share one coordinate system. Require enough of the real guide to be
    // covered before accepting the scale-normalized shape score.
    final rawTolerance = math.max(2, (math.min(width, height) * 0.04).round());
    final learnerRawTolerance = _dilateMask(learnerRaw, rawTolerance);
    final standardRawTolerance = _dilateMask(standardRaw, rawTolerance);
    var learnerOnGuide = 0;
    var guideCovered = 0;
    for (var i = 0; i < learnerRaw.pixels.length; i++) {
      if (learnerRaw.pixels[i] && standardRawTolerance.pixels[i]) {
        learnerOnGuide++;
      }
      if (standardRaw.pixels[i] && learnerRawTolerance.pixels[i]) {
        guideCovered++;
      }
    }
    final alignedPrecision = learnerOnGuide / learnerRawCount;
    final alignedRecall = guideCovered / standardRawCount;
    if (alignedRecall < 0.30 || alignedPrecision < 0.30) return 0;

    final coverageFactor = math.min(1.0, alignedRecall / 0.75);
    final placementFactor = math.min(1.0, alignedPrecision / 0.65);
    return (normalizedDice * coverageFactor * placementFactor).clamp(0.0, 1.0);
  }

  /// Decides whether an attempt is verified without changing its measured
  /// visual-similarity score.
  ///
  /// Tracing is primarily assessed against the on-screen guide. A matching CNN
  /// identity supports that evidence, but a top-class disagreement cannot be
  /// a hard rejection because the model's held-out accuracy is 88.61% and its
  /// training images are not child traces. In a disagreement, only a strong
  /// guide match survives. The UI must still display [shapeSimilarity] itself;
  /// a classifier disagreement is a verdict, not a second similarity score.
  static bool passesVerification({
    required double shapeSimilarity,
    required bool identityCheckRequired,
    required bool identityMatches,
  }) {
    if (!shapeSimilarity.isFinite) return false;
    final shape = shapeSimilarity.clamp(0.0, 1.0);
    if (shape < _shapeOnlyCredibilityFloor) return false;
    if (identityCheckRequired) {
      return identityMatches || shape >= _cnnDisagreementCredibilityFloor;
    }
    return true;
  }

  /// Converts weak accidental overlap into an honest zero for the learner.
  /// Scores below the minimum credible letter-shape threshold are not useful
  /// as a "matching" percentage: they only mean that some ink crossed the
  /// guide. Strong shape scores remain visible even when the CNN identity
  /// check disagrees, so a good trace is not hidden by classifier uncertainty.
  static double credibleDisplaySimilarity(double shapeSimilarity) {
    if (!shapeSimilarity.isFinite) return 0;
    final shape = shapeSimilarity.clamp(0.0, 1.0);
    return shape >= _shapeOnlyCredibilityFloor ? shape : 0;
  }

  /// Uses the covariance eigenvalues of the learner ink to detect a mark whose
  /// pixels lie almost entirely on one fitted line, regardless of its angle.
  static bool _isNearlyStraight(_InkMask mask) {
    var count = 0;
    var sumX = 0.0;
    var sumY = 0.0;
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (!mask.pixels[(y * mask.width) + x]) continue;
        count++;
        sumX += x;
        sumY += y;
      }
    }
    if (count < 2) return true;

    final meanX = sumX / count;
    final meanY = sumY / count;
    var covarianceX = 0.0;
    var covarianceY = 0.0;
    var covarianceXY = 0.0;
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (!mask.pixels[(y * mask.width) + x]) continue;
        final dx = x - meanX;
        final dy = y - meanY;
        covarianceX += dx * dx;
        covarianceY += dy * dy;
        covarianceXY += dx * dy;
      }
    }
    covarianceX /= count;
    covarianceY /= count;
    covarianceXY /= count;
    final trace = covarianceX + covarianceY;
    if (trace == 0) return true;
    final discriminant = math.sqrt(
      math.max(
        0,
        ((covarianceX - covarianceY) * (covarianceX - covarianceY)) +
            (4 * covarianceXY * covarianceXY),
      ),
    );
    final major = (trace + discriminant) / 2;
    final minor = (trace - discriminant) / 2;
    return major > 0 && (minor / major) < 0.045;
  }

  static _InkMask _alphaMask(Uint8List rgba, int width, int height) {
    final pixels = List<bool>.filled(width * height, false);
    for (var pixel = 0; pixel < pixels.length; pixel++) {
      pixels[pixel] = rgba[(pixel * 4) + 3] >= 32;
    }
    return _InkMask(width, height, pixels);
  }

  static List<bool> _normalize(_InkMask source) {
    var minX = source.width;
    var minY = source.height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (!source.pixels[(y * source.width) + x]) continue;
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }

    final normalized = List<bool>.filled(_gridSize * _gridSize, false);
    if (maxX < minX || maxY < minY) return normalized;

    final inkWidth = math.max(1, maxX - minX + 1);
    final inkHeight = math.max(1, maxY - minY + 1);
    final available = _gridSize - (_padding * 2);
    final scale = math.min(available / inkWidth, available / inkHeight);
    final drawnWidth = inkWidth * scale;
    final drawnHeight = inkHeight * scale;
    final offsetX = (_gridSize - drawnWidth) / 2;
    final offsetY = (_gridSize - drawnHeight) / 2;

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        if (!source.pixels[(y * source.width) + x]) continue;
        final targetX = (offsetX + ((x - minX + 0.5) * scale)).floor();
        final targetY = (offsetY + ((y - minY + 0.5) * scale)).floor();
        if (targetX >= 0 &&
            targetX < _gridSize &&
            targetY >= 0 &&
            targetY < _gridSize) {
          normalized[(targetY * _gridSize) + targetX] = true;
        }
      }
    }
    return normalized;
  }

  static List<bool> _dilate(List<bool> source, int radius) {
    final result = List<bool>.from(source);
    for (var y = 0; y < _gridSize; y++) {
      for (var x = 0; x < _gridSize; x++) {
        if (!source[(y * _gridSize) + x]) continue;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            if ((dx * dx) + (dy * dy) > radius * radius) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < _gridSize && ny >= 0 && ny < _gridSize) {
              result[(ny * _gridSize) + nx] = true;
            }
          }
        }
      }
    }
    return result;
  }

  static _InkMask _dilateMask(_InkMask source, int radius) {
    final result = List<bool>.from(source.pixels);
    final radiusSquared = radius * radius;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (!source.pixels[(y * source.width) + x]) continue;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            if ((dx * dx) + (dy * dy) > radiusSquared) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < source.width && ny >= 0 && ny < source.height) {
              result[(ny * source.width) + nx] = true;
            }
          }
        }
      }
    }
    return _InkMask(source.width, source.height, result);
  }

  static int _count(List<bool> mask) =>
      mask.fold(0, (count, pixel) => pixel ? count + 1 : count);

  static _InkBounds? _inkBounds(_InkMask mask) {
    var minX = mask.width;
    var minY = mask.height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (!mask.pixels[(y * mask.width) + x]) continue;
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
    if (maxX < minX || maxY < minY) return null;
    return _InkBounds(width: maxX - minX + 1, height: maxY - minY + 1);
  }
}

class _InkMask {
  final int width;
  final int height;
  final List<bool> pixels;

  const _InkMask(this.width, this.height, this.pixels);
}

class _InkBounds {
  final int width;
  final int height;

  const _InkBounds({required this.width, required this.height});

  int get area => width * height;
}
