import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/services/learning_journey_service.dart';

void main() {
  group('LearningJourneyService', () {
    test('starts a new learner at level one', () {
      final result = LearningJourneyService.summarize([null, null, null]);

      expect(result.masteredLevels, 0);
      expect(result.nextLevel, 1);
      expect(result.currentScore, 0);
      expect(result.completion, 0);
      expect(result.isComplete, isFalse);
    });

    test('uses sequential mastery and does not skip a prerequisite', () {
      final result = LearningJourneyService.summarize([85, 62, 100, null]);

      expect(result.masteredLevels, 1);
      expect(result.nextLevel, 2);
      expect(result.currentScore, 62);
      expect(result.completion, 0.25);
    });

    test('recognises a completed learning journey', () {
      final result = LearningJourneyService.summarize([70, 84, 100]);

      expect(result.masteredLevels, 3);
      expect(result.nextLevel, 3);
      expect(result.currentScore, 100);
      expect(result.completion, 1);
      expect(result.isComplete, isTrue);
    });
  });
}
