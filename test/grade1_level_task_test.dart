import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/screens/learning/models/grade1_level_task.dart';
import 'package:reading_assistant_app/screens/learning/models/grade_content.dart';

void main() {
  group('Grade 1 learning path', () {
    test('defines five ordered levels from easy to mastery', () {
      expect(Grade1LevelDefinition.levels.length, 5);
      expect(Grade1LevelDefinition.levels.map((item) => item.level), [
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(
        Grade1LevelDefinition.levels
            .map((item) => item.taskType)
            .toSet()
            .length,
        5,
      );
    });

    test('unlocks sequentially only after 70 percent', () {
      expect(Grade1LevelDefinition.isUnlocked(1, const {}), isTrue);
      expect(Grade1LevelDefinition.isUnlocked(2, const {1: 69}), isFalse);
      expect(Grade1LevelDefinition.isUnlocked(2, const {1: 70}), isTrue);
      expect(
        Grade1LevelDefinition.isUnlocked(3, const {1: 100, 2: 69}),
        isFalse,
      );
      expect(
        Grade1LevelDefinition.isUnlocked(3, const {1: 100, 2: 80}),
        isTrue,
      );
    });

    test('every level generates valid questions and answer options', () {
      for (final level in Grade1LevelDefinition.levels) {
        final questions = Grade1LevelTask.generate(
          letters: Grade1Content.sinhalaLetters,
          level: level.level,
          random: Random(42),
        );
        expect(questions.length, level.questionCount);
        for (final question in questions) {
          expect(question.options, contains(question.target));
          expect(question.options.length, level.optionCount);
          expect(
            question.options.map((item) => item.letter).toSet().length,
            level.optionCount,
          );
        }
      }
    });

    test('picture questions never use the neutral placeholder', () {
      final questions = Grade1LevelTask.generate(
        letters: Grade1Content.sinhalaLetters,
        level: 3,
        random: Random(7),
      );
      expect(
        questions.every(
          (question) =>
              question.mode == Grade1QuestionMode.pictureInitial &&
              question.target.emoji != '🔤',
        ),
        isTrue,
      );
    });

    test('hard word questions hide the target first letter', () {
      final questions = Grade1LevelTask.generate(
        letters: Grade1Content.englishLetters,
        level: 4,
        random: Random(9),
      );
      for (final question in questions) {
        expect(question.mode, Grade1QuestionMode.missingInitial);
        expect(question.missingWord, startsWith('___'));
        expect(
          question.missingWord,
          isNot(startsWith('___${question.target.letter}')),
        );
      }
    });

    test('all new levels have progress-feed labels', () {
      for (final level in Grade1LevelDefinition.levels) {
        expect(taskTypeLabels.containsKey(level.taskType), isTrue);
      }
    });
  });
}
