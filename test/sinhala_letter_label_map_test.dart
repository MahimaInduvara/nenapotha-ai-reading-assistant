import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/services/letter_classifier_service.dart';
import 'package:reading_assistant_app/services/sinhala_letter_label_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SinhalaLetterLabelMap', () {
    test(
      'maps every exposed dataset class ID to the expected Unicode letter',
      () {
        expect(SinhalaLetterLabelMap.supportedClassIdToUnicode, const {
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
        });
      },
    );

    test('validates the shipped 455-entry open-set label asset', () async {
      final raw = await rootBundle.loadString('assets/models/class_names.txt');
      final classIds = SinhalaLetterLabelMap.parseAndValidateClassIds(
        raw
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty),
      );

      expect(classIds, hasLength(455));
      expect(classIds.last, SinhalaLetterLabelMap.unknownClassId);
      for (final entry
          in SinhalaLetterLabelMap.supportedClassIdToUnicode.entries) {
        expect(
          SinhalaLetterLabelMap.classIdAtOutputIndex(classIds, entry.key - 1),
          entry.key,
          reason:
              'Output index ${entry.key - 1} must resolve to ${entry.value}',
        );
      }
    });

    test(
      'rejects incomplete, non-numeric, duplicate, and out-of-range labels',
      () {
        expect(
          () =>
              SinhalaLetterLabelMap.parseAndValidateClassIds(const ['1', '2']),
          throwsFormatException,
        );

        final valid = List.generate(455, (index) => '${index + 1}');
        expect(
          () => SinhalaLetterLabelMap.parseAndValidateClassIds(
            [...valid]..[10] = 'letter-eleven',
          ),
          throwsFormatException,
        );
        expect(
          () => SinhalaLetterLabelMap.parseAndValidateClassIds(
            [...valid]..[10] = '10',
          ),
          throwsFormatException,
        );
        expect(
          () => SinhalaLetterLabelMap.parseAndValidateClassIds(
            [...valid]..[454] = '456',
          ),
          throwsFormatException,
        );
      },
    );

    test('rejects output indexes outside the loaded label list', () {
      expect(
        () => SinhalaLetterLabelMap.classIdAtOutputIndex(const [1, 2], -1),
        throwsRangeError,
      );
      expect(
        () => SinhalaLetterLabelMap.classIdAtOutputIndex(const [1, 2], 2),
        throwsRangeError,
      );
    });
  });

  group('LetterPrediction', () {
    for (final entry
        in SinhalaLetterLabelMap.supportedClassIdToUnicode.entries) {
      test('class ${entry.key} matches exposed letter ${entry.value}', () {
        final prediction = LetterPrediction(
          outputIndex: entry.key - 1,
          classId: entry.key,
          confidence: 0.75,
        );

        expect(prediction.unicodeLetter, entry.value);
        expect(prediction.label, entry.value);
        expect(prediction.isSupported, isTrue);
        expect(
          prediction.matchesExpected(entry.value, minimumConfidence: 0.5),
          isTrue,
        );
      });
    }

    test('requires both the expected letter and the confidence threshold', () {
      const prediction = LetterPrediction(
        outputIndex: 0,
        classId: 1,
        confidence: 0.5,
      );

      expect(prediction.matchesExpected('අ', minimumConfidence: 0.5), isTrue);
      expect(prediction.matchesExpected('ආ', minimumConfidence: 0.5), isFalse);
      expect(prediction.matchesExpected('අ', minimumConfidence: 0.51), isFalse);
    });

    test('does not present an unverified class as a Unicode prediction', () {
      const prediction = LetterPrediction(
        outputIndex: 3,
        classId: 4,
        confidence: 0.99,
      );

      expect(prediction.unicodeLetter, isNull);
      expect(prediction.label, 'class:4');
      expect(prediction.isSupported, isFalse);
      expect(prediction.matchesExpected('ඈ', minimumConfidence: 0.5), isFalse);
    });

    test('presents class 455 as the explicit Unknown prediction', () {
      const prediction = LetterPrediction(
        outputIndex: 454,
        classId: 455,
        confidence: 0.97,
      );

      expect(prediction.unicodeLetter, isNull);
      expect(prediction.label, 'unknown');
      expect(prediction.isUnknown, isTrue);
      expect(prediction.isSupported, isFalse);
      expect(prediction.matchesExpected('අ', minimumConfidence: 0.5), isFalse);
    });

    test('does not fabricate a CNN class for Grade 1 letter ඌ', () {
      expect(
        SinhalaLetterLabelMap.supportedClassIdToUnicode.values,
        isNot(contains('ඌ')),
      );
    });
  });
}
