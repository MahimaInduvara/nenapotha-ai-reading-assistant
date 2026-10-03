/// Verified class-ID mapping for the Sinhala letters and Grade 2 quick-
/// practice syllables exposed by the app and present in the original
/// 454-class dataset used by the tracing model.
///
/// The open-set model has 455 outputs. IDs 1–454 retain the source dataset's
/// ordering and ID 455 is the explicitly trained Unknown/Invalid class.
/// `assets/models/class_names.txt` maps each zero-based output index to its ID.
/// The numeric-ID-to-Unicode values below come from the public GUI notebook
/// associated with Sathira L. Amal's "Sinhala Letter 454" dataset:
/// https://github.com/LasinduViduranga/sinhala-character-recognition-ml/
/// blob/main/GUI%20for%20character%20recognition%20model.ipynb
///
/// The Grade 1 catalog also contains ඌ, but the source dataset has no ඌ base
/// class. It therefore uses visual shape similarity without a fabricated CNN
/// label. Only compound characters whose source IDs have been verified are
/// exposed; all other classes remain deliberately unmapped.
abstract final class SinhalaLetterLabelMap {
  static const int sourceLetterClassCount = 454;
  static const int unknownClassId = 455;
  static const int modelClassCount = 455;
  static const String version = 'sinhala-letter-455-open-set-grade1-v1';

  static const Map<int, String> supportedClassIdToUnicode = {
    1: 'අ',
    2: 'ආ',
    3: 'ඇ',
    5: 'ඉ',
    6: 'ඊ',
    7: 'උ',
    8: 'එ',
    10: 'ඔ',
    12: 'ක',
    13: 'කා',
    14: 'කැ',
    15: 'කෑ',
    16: 'කි',
    17: 'කී',
    18: 'කු',
    19: 'කූ',
    20: 'ක්',
    25: 'ග',
    38: 'ච',
    51: 'ජ',
    64: 'ට',
    77: 'ඩ',
    93: 'ත',
    105: 'ද',
    120: 'න',
    134: 'ප',
    149: 'බ',
    164: 'ම',
    179: 'ය',
    190: 'ර',
    198: 'ල',
    208: 'ව',
    250: 'ස',
    264: 'හ',
  };

  static String? unicodeForClassId(int classId) =>
      supportedClassIdToUnicode[classId];

  static List<int> parseAndValidateClassIds(
    Iterable<String> rawLabels, {
    int expectedCount = modelClassCount,
  }) {
    final labels = rawLabels.toList(growable: false);
    if (labels.length != expectedCount) {
      throw FormatException(
        'Expected $expectedCount model labels, found ${labels.length}.',
      );
    }

    final classIds = <int>[];
    final seen = <int>{};
    for (var outputIndex = 0; outputIndex < labels.length; outputIndex++) {
      final raw = labels[outputIndex].trim();
      final classId = int.tryParse(raw);
      if (classId == null || classId < 1 || classId > modelClassCount) {
        throw FormatException(
          'Invalid class ID "$raw" at output index $outputIndex.',
        );
      }
      if (!seen.add(classId)) {
        throw FormatException('Duplicate class ID $classId.');
      }
      classIds.add(classId);
    }
    return List.unmodifiable(classIds);
  }

  static int classIdAtOutputIndex(List<int> classIds, int outputIndex) {
    if (outputIndex < 0 || outputIndex >= classIds.length) {
      throw RangeError.index(outputIndex, classIds, 'outputIndex');
    }
    return classIds[outputIndex];
  }
}
