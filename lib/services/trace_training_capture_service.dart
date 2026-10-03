import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'letter_classifier_service.dart';

class TraceTrainingSample {
  final String sampleId;
  final String label;
  final String kind;
  final String writerId;
  final int? currentModelClassId;
  final DateTime createdAt;
  final String rawPath;
  final String modelInputPath;

  const TraceTrainingSample({
    required this.sampleId,
    required this.label,
    required this.kind,
    required this.writerId,
    required this.currentModelClassId,
    required this.createdAt,
    required this.rawPath,
    required this.modelInputPath,
  });

  Map<String, Object?> toJson() => {
    'sampleId': sampleId,
    'label': label,
    'kind': kind,
    'writerId': writerId,
    'currentModelClassId': currentModelClassId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'rawPath': rawPath,
    'modelInputPath': modelInputPath,
    'inputContract': '64x64 grayscale white ink on black',
    'captureVersion': TraceTrainingCaptureService.version,
  };
}

/// Debug-only research data capture for adapting the CNN to real app traces.
///
/// No child name, account ID, or profile data is stored. The researcher must
/// use an anonymous writer code and obtain the required consent before asking
/// another person to contribute handwriting samples.
class TraceTrainingCaptureService {
  static const String version = 'readbuddy-trace-capture-v1';
  static const int modelInputSize = 64;
  static const String unknownLabel = '__unknown__';

  Directory? _root;

  Future<Directory> datasetRoot() async {
    final existing = _root;
    if (existing != null) return existing;

    Directory base;
    try {
      base =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } catch (_) {
      base = await getApplicationDocumentsDirectory();
    }
    final root = Directory('${base.path}/readbuddy_trace_dataset');
    await root.create(recursive: true);
    _root = root;
    return root;
  }

  Future<TraceTrainingSample> saveSample({
    required Uint8List rawPng,
    required String label,
    required String kind,
    required String writerId,
    int? currentModelClassId,
  }) async {
    if (rawPng.isEmpty) throw ArgumentError('rawPng cannot be empty.');
    final safeWriter = safeWriterId(writerId);
    if (safeWriter.isEmpty) {
      throw ArgumentError('Enter an anonymous writer code first.');
    }

    final root = await datasetRoot();
    final targetKey = labelKey(label, kind: kind);
    final now = DateTime.now().toUtc();
    final stamp = now.toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
    final sampleId = '${safeWriter}_${targetKey}_$stamp';

    final rawDir = Directory('${root.path}/raw/$targetKey');
    final inputDir = Directory('${root.path}/model_input/$targetKey');
    final metadataDir = Directory('${root.path}/metadata/$targetKey');
    await Future.wait([
      rawDir.create(recursive: true),
      inputDir.create(recursive: true),
      metadataDir.create(recursive: true),
    ]);

    final rawFile = File('${rawDir.path}/$sampleId.png');
    final inputFile = File('${inputDir.path}/$sampleId.png');
    final metadataFile = File('${metadataDir.path}/$sampleId.json');
    await rawFile.writeAsBytes(rawPng, flush: true);
    await inputFile.writeAsBytes(modelInputPng(rawPng), flush: true);

    final sample = TraceTrainingSample(
      sampleId: sampleId,
      label: label,
      kind: kind,
      writerId: safeWriter,
      currentModelClassId: currentModelClassId,
      createdAt: now,
      rawPath: 'raw/$targetKey/$sampleId.png',
      modelInputPath: 'model_input/$targetKey/$sampleId.png',
    );
    final jsonLine = jsonEncode(sample.toJson());
    await metadataFile.writeAsString('$jsonLine\n', flush: true);
    await File(
      '${root.path}/manifest.jsonl',
    ).writeAsString('$jsonLine\n', mode: FileMode.append, flush: true);
    return sample;
  }

  Future<Map<String, int>> sampleCounts() async {
    final root = await datasetRoot();
    final inputRoot = Directory('${root.path}/model_input');
    if (!await inputRoot.exists()) return const {};
    final counts = <String, int>{};
    await for (final entity in inputRoot.list(followLinks: false)) {
      if (entity is! Directory) continue;
      var count = 0;
      await for (final sample in entity.list(followLinks: false)) {
        if (sample is File && sample.path.toLowerCase().endsWith('.png')) {
          count++;
        }
      }
      counts[_basename(entity.path)] = count;
    }
    return counts;
  }

  static Uint8List modelInputPng(Uint8List rawPng) {
    final pixels = LetterClassifierService.preprocessForModel(rawPng);
    final output = img.Image(
      width: modelInputSize,
      height: modelInputSize,
      numChannels: 3,
    );
    for (var y = 0; y < modelInputSize; y++) {
      for (var x = 0; x < modelInputSize; x++) {
        final value = (pixels[(y * modelInputSize) + x].clamp(0.0, 1.0) * 255)
            .round();
        output.setPixelRgb(x, y, value, value, value);
      }
    }
    return Uint8List.fromList(img.encodePng(output));
  }

  static String safeWriterId(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static String labelKey(String label, {required String kind}) {
    if (label == unknownLabel || kind == 'invalid') return unknownLabel;
    final codepoints = label.runes
        .map((value) => 'u${value.toRadixString(16).padLeft(4, '0')}')
        .join('_');
    return '${kind}_$codepoints';
  }

  static String _basename(String path) =>
      path.replaceAll('\\', '/').split('/').last;
}
