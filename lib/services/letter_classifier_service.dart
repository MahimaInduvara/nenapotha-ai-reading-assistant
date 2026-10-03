// lib/services/letter_classifier_service.dart
// On-device Sinhala letter classifier. Inference stays completely offline.
// Preprocessing must match training: 64×64 grayscale float32 scaled to [0,1].

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'sinhala_letter_label_map.dart';

class LetterPrediction {
  final int outputIndex;
  final int classId;
  final double confidence;

  const LetterPrediction({
    required this.outputIndex,
    required this.classId,
    required this.confidence,
  });

  String? get unicodeLetter => SinhalaLetterLabelMap.unicodeForClassId(classId);

  bool get isUnknown => classId == SinhalaLetterLabelMap.unknownClassId;

  bool get isSupported => unicodeLetter != null;

  String get label => isUnknown ? 'unknown' : unicodeLetter ?? 'class:$classId';

  bool matchesExpected(
    String expectedLetter, {
    required double minimumConfidence,
  }) => unicodeLetter == expectedLetter && confidence >= minimumConfidence;

  @override
  String toString() =>
      '$label [class $classId, output $outputIndex] '
      '(${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Runtime evidence exposed for the Stage 3 on-device benchmark.
class LetterModelRuntimeInfo {
  final String inputName;
  final List<int> inputShape;
  final String inputType;
  final String outputName;
  final List<int> outputShape;
  final String outputType;
  final int classCount;

  const LetterModelRuntimeInfo({
    required this.inputName,
    required this.inputShape,
    required this.inputType,
    required this.outputName,
    required this.outputShape,
    required this.outputType,
    required this.classCount,
  });

  Map<String, Object> toJson() => {
    'inputName': inputName,
    'inputShape': inputShape,
    'inputType': inputType,
    'outputName': outputName,
    'outputShape': outputShape,
    'outputType': outputType,
    'classCount': classCount,
  };
}

class LetterClassifierService {
  static const String modelVersion =
      'readbuddy-captured-adapter-pilot-v2-6d3303f1-alpha-crop-v2';
  static const String _modelAsset = 'assets/models/sinhala_letter_model.tflite';
  static const String _classNamesAsset = 'assets/models/class_names.txt';
  static const int _inputSize = 64;
  static const int _channels = 1;
  static const List<int> _expectedInputShape = [1, 64, 64, 1];

  Interpreter? _interpreter;
  List<int> _classIds = [];
  LetterModelRuntimeInfo? _runtimeInfo;
  Duration? _lastInferenceDuration;

  bool get isLoaded => _interpreter != null && _classIds.isNotEmpty;

  LetterModelRuntimeInfo? get runtimeInfo => _runtimeInfo;

  /// Native `interpreter.run` time only; image decoding and preprocessing are
  /// deliberately excluded. The integration benchmark records both values.
  Duration? get lastInferenceDuration => _lastInferenceDuration;

  static bool _sameShape(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  /// Loads assets and fails early if tensor shape/type or label cardinality
  /// differs from the preprocessing contract used by this app.
  Future<void> loadModel() async {
    final interpreter = await Interpreter.fromAsset(_modelAsset);
    try {
      final raw = await rootBundle.loadString(_classNamesAsset);
      final classIds = SinhalaLetterLabelMap.parseAndValidateClassIds(
        raw
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty),
      );

      final input = interpreter.getInputTensor(0);
      final output = interpreter.getOutputTensor(0);
      if (!_sameShape(input.shape, _expectedInputShape)) {
        throw StateError(
          'Expected model input $_expectedInputShape but found ${input.shape}.',
        );
      }
      if (input.type != TensorType.float32) {
        throw StateError(
          'Expected float32 model input but found ${input.type}.',
        );
      }
      if (output.type != TensorType.float32 ||
          output.shape.length != 2 ||
          output.shape.first != 1) {
        throw StateError(
          'Expected float32 model output [1, classes] but found '
          '${output.type} ${output.shape}.',
        );
      }
      final outputClassCount = output.shape.last;
      if (outputClassCount != classIds.length) {
        throw StateError(
          'Model has $outputClassCount outputs but the label asset has '
          '${classIds.length} entries.',
        );
      }

      _interpreter = interpreter;
      _classIds = classIds;
      _runtimeInfo = LetterModelRuntimeInfo(
        inputName: input.name,
        inputShape: List.unmodifiable(input.shape),
        inputType: input.type.name,
        outputName: output.name,
        outputShape: List.unmodifiable(output.shape),
        outputType: output.type.name,
        classCount: classIds.length,
      );
    } catch (_) {
      interpreter.close();
      rethrow;
    }
  }

  Future<LetterPrediction> predict(Uint8List imageBytes) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError(
        'LetterClassifierService.loadModel() must be called before predict().',
      );
    }

    final pixels = preprocessForModel(imageBytes);

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) => List.filled(_channels, pixels[(y * _inputSize) + x]),
        ),
      ),
    );
    final output = List.generate(1, (_) => List.filled(_classIds.length, 0.0));

    final stopwatch = Stopwatch()..start();
    interpreter.run(input, output);
    stopwatch.stop();
    _lastInferenceDuration = stopwatch.elapsed;

    final scores = output[0];
    var bestIndex = 0;
    var bestScore = scores[0];
    for (var index = 1; index < scores.length; index++) {
      if (scores[index] > bestScore) {
        bestScore = scores[index];
        bestIndex = index;
      }
    }

    final classId = SinhalaLetterLabelMap.classIdAtOutputIndex(
      _classIds,
      bestIndex,
    );
    return LetterPrediction(
      outputIndex: bestIndex,
      classId: classId,
      confidence: bestScore.toDouble(),
    );
  }

  /// Converts either a training-style opaque image or the app's transparent
  /// drawing layer to the model's white-ink-on-black input convention.
  ///
  /// Training samples are opaque grayscale files, so their luminance is used.
  /// The tracing canvas is transparent outside the child's stroke; for that
  /// input its alpha channel is the ink mask. This avoids the old polarity
  /// error where dark-purple ink on a white background was sent to a model
  /// trained on white handwriting over black.
  static Float32List preprocessForModel(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Could not decode imageBytes as an image.');
    }
    var useAlphaAsInk = false;
    for (final pixel in decoded) {
      if (pixel.a < 254) {
        useAlphaAsInk = true;
        break;
      }
    }
    final normalizedSource = useAlphaAsInk
        ? _cropAndCenterAlphaInk(decoded)
        : decoded;
    final resized = img.copyResize(
      normalizedSource,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.average,
    );

    final grayscale = useAlphaAsInk ? null : img.grayscale(resized);
    final result = Float32List(_inputSize * _inputSize);
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final value = useAlphaAsInk
            ? resized.getPixel(x, y).a
            : grayscale!.getPixel(x, y).r;
        result[(y * _inputSize) + x] = value / 255.0;
      }
    }
    return result;
  }

  /// Training glyphs are already tightly framed. App drawings are captured
  /// from a much larger transparent canvas, so crop the real ink, preserve a
  /// small margin, and center it in a square before the 64x64 resize.
  static img.Image _cropAndCenterAlphaInk(img.Image source) {
    var minX = source.width;
    var minY = source.height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (source.getPixel(x, y).a < 16) continue;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < minX || maxY < minY) return source;

    final inkWidth = maxX - minX + 1;
    final inkHeight = maxY - minY + 1;
    final longestSide = math.max(inkWidth, inkHeight);
    final padding = math.max(2, (longestSide * 0.12).round());
    final squareSide = longestSide + (padding * 2);
    final centered = img.Image(
      width: squareSide,
      height: squareSide,
      numChannels: 4,
    );
    final offsetX = padding + ((longestSide - inkWidth) ~/ 2);
    final offsetY = padding + ((longestSide - inkHeight) ~/ 2);
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final alpha = source.getPixel(x, y).a;
        if (alpha == 0) continue;
        centered.setPixelRgba(
          offsetX + (x - minX),
          offsetY + (y - minY),
          255,
          255,
          255,
          alpha,
        );
      }
    }
    return centered;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _classIds = [];
    _runtimeInfo = null;
    _lastInferenceDuration = null;
  }
}
