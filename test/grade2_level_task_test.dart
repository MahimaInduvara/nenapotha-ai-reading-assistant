import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/screens/learning/models/grade2_level_task.dart';
import 'package:reading_assistant_app/screens/learning/models/grade_content.dart';

void main() {
  group('Grade 2 advanced learning path', () {
    test('defines six ordered levels from pillam to mastery', () {
      expect(Grade2LevelDefinition.levels, hasLength(6));
      expect(
        Grade2LevelDefinition.levels.map((level) => level.level),
        orderedEquals([1, 2, 3, 4, 5, 6]),
      );
      expect(
        Grade2LevelDefinition.levels.map((level) => level.taskType).toSet(),
        hasLength(6),
      );
    });

    test('unlocks sequentially only after 70 percent', () {
      expect(Grade2LevelDefinition.isUnlocked(1, {}), isTrue);
      expect(Grade2LevelDefinition.isUnlocked(2, {}), isFalse);
      expect(Grade2LevelDefinition.isUnlocked(2, {1: 69.9}), isFalse);
      expect(Grade2LevelDefinition.isUnlocked(2, {1: 70}), isTrue);
      expect(
        Grade2LevelDefinition.isUnlocked(4, {1: 100, 2: 100, 3: 70}),
        isTrue,
      );
    });

    test('every level generates valid distinct answer options', () {
      for (final level in Grade2LevelDefinition.levels) {
        final questions = Grade2LevelTask.generate(
          level: level.level,
          random: Random(40 + level.level),
        );
        expect(questions, hasLength(level.questionCount));
        for (final question in questions) {
          expect(question.options, hasLength(level.optionCount));
          expect(question.options.toSet(), hasLength(level.optionCount));
          expect(question.options, contains(question.answer));
          expect(question.itemId, isNotEmpty);
        }
      }
    });

    test('levels increase through five distinct literacy skills', () {
      final expected = [
        Grade2QuestionMode.identifyPillam,
        Grade2QuestionMode.completePillam,
        Grade2QuestionMode.pictureWord,
        Grade2QuestionMode.completeSentence,
        Grade2QuestionMode.comprehension,
      ];
      for (var level = 1; level <= 5; level++) {
        final questions = Grade2LevelTask.generate(
          level: level,
          random: Random(level),
        );
        expect(
          questions.every((item) => item.mode == expected[level - 1]),
          isTrue,
        );
      }
    });

    test(
      'sentence questions hide the answer and keep meaningful source text',
      () {
        final questions = Grade2LevelTask.generate(level: 4, random: Random(4));
        for (final question in questions) {
          expect(question.display, contains('_____'));
          expect(question.display, isNot(contains(question.answer)));
          expect(
            Grade2Content.words.any(
              (word) =>
                  word.wordSi == question.answer &&
                  word.sentence.replaceFirst(word.wordSi, '_____') ==
                      question.display,
            ),
            isTrue,
          );
        }
      },
    );

    test('reading questions use the authored Grade 2 sentences', () {
      final questions = Grade2LevelTask.generate(level: 5, random: Random(5));
      expect(
        questions.every(
          (item) => Grade2Content.sentences.any(
            (sentence) => item.display.startsWith(sentence),
          ),
        ),
        isTrue,
      );
    });

    test('champion challenge mixes every skill type', () {
      final questions = Grade2LevelTask.generate(level: 6, random: Random(6));
      expect(
        questions.map((item) => item.mode).toSet(),
        containsAll(Grade2QuestionMode.values),
      );
    });

    test('all new task types have progress-feed labels', () {
      for (final level in Grade2LevelDefinition.levels) {
        expect(taskTypeLabels.containsKey(level.taskType), isTrue);
      }
    });
  });
}
