import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/services/text_difficulty_classifier.dart';

void main() {
  group('TextDifficultyClassifier', () {
    final classifier = TextDifficultyClassifier();

    test('returns explainable Grade 1 output for a short passage', () {
      final result = classifier.analyze('Cat runs.');

      expect(result.predictedGrade, 1);
      expect(result.wordCount, 2);
      expect(result.averageWordLength, greaterThan(0));
      expect(result.averageSentenceLength, 2);
      expect(result.predictedGradeProbability, inInclusiveRange(0, 1));
    });

    test('returns explainable Grade 2 output for a longer passage', () {
      final result = classifier.analyze(
        'Children carefully explore the beautiful garden and observe '
        'colourful butterflies beside many different flowers.',
      );

      expect(result.predictedGrade, 2);
      expect(result.wordCount, greaterThan(8));
      expect(result.averageWordLength, greaterThan(4));
      expect(result.averageSentenceLength, greaterThan(8));
      expect(result.predictedGradeProbability, inInclusiveRange(0, 1));
    });

    test('legacy grade API agrees with detailed analysis', () {
      const text = 'I see a cat.';

      expect(
        classifier.predictGrade(text),
        classifier.analyze(text).predictedGrade,
      );
    });
  });
}
