import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/services/reading_level_engine.dart';

void main() {
  group('ReadingLevelEngine recommendations', () {
    test('never crosses the authored Grade 1 boundary', () {
      final stories = ReadingLevelEngine.recommendStoriesForLevel(1);

      expect(stories, isNotEmpty);
      expect(stories.every((story) => story.gradeLevel == 1), isTrue);
    });

    test('never crosses the authored Grade 2 boundary', () {
      final stories = ReadingLevelEngine.recommendStoriesForLevel(2);

      expect(stories, isNotEmpty);
      expect(stories.every((story) => story.gradeLevel == 2), isTrue);
    });

    test('classifier disagreement is exposed for human review', () {
      final stories = ReadingLevelEngine.recommendStoriesForLevel(1);

      expect(stories.any(ReadingLevelEngine.needsDifficultyReview), isTrue);
    });
  });
}
