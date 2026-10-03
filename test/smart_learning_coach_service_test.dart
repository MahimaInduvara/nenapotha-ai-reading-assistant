import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/services/smart_learning_coach_service.dart';

void main() {
  final now = DateTime(2026, 9, 22, 12);

  TaskAttempt attempt({
    required String type,
    required int grade,
    required int score,
    required int total,
    List<TaskItemResult> items = const [],
    DateTime? completedAt,
  }) => TaskAttempt(
    taskType: type,
    grade: grade,
    language: 'sinhala',
    score: score,
    total: total,
    completedAt: completedAt ?? now,
    items: items,
  );

  test('new learner receives a safe three-step starter plan', () {
    final plan = SmartLearningCoachService.build(
      attempts: const [],
      grade: 1,
      now: now,
    );

    expect(plan.stage, CoachStage.starting);
    expect(plan.hasEvidence, isFalse);
    expect(plan.focusTaskType, 'grade1_level_1');
    expect(plan.recommendedTaskTypes, [
      'grade1_level_1',
      'grade1_level_2',
      'grade1_level_3',
    ]);
  });

  test('coach identifies a repeatedly weak item from recorded evidence', () {
    final plan = SmartLearningCoachService.build(
      grade: 1,
      now: now,
      attempts: [
        attempt(
          type: 'letter_recognition',
          grade: 1,
          score: 1,
          total: 2,
          items: const [
            TaskItemResult(itemId: 'අ', isCorrect: false),
            TaskItemResult(itemId: 'ආ', isCorrect: true),
          ],
        ),
        attempt(
          type: 'letter_recognition',
          grade: 1,
          score: 1,
          total: 2,
          items: const [
            TaskItemResult(itemId: 'අ', isCorrect: false),
            TaskItemResult(itemId: 'ආ', isCorrect: true),
          ],
        ),
      ],
    );

    expect(plan.stage, CoachStage.support);
    expect(plan.focusTaskType, 'letter_recognition');
    expect(plan.weakItem, 'අ');
    expect(plan.weakItemAccuracy, 0);
    expect(plan.recommendedTaskTypes, contains('letter_recognition'));
  });

  test('grade filtering prevents another grade from changing the plan', () {
    final plan = SmartLearningCoachService.build(
      grade: 2,
      now: now,
      attempts: [
        attempt(type: 'grade1_level_1', grade: 1, score: 0, total: 10),
        attempt(type: 'grade2_level_1', grade: 2, score: 9, total: 10),
      ],
    );

    expect(plan.practiceRounds, 1);
    expect(plan.accuracy, 90);
    expect(plan.stage, CoachStage.challenge);
    expect(plan.focusTaskType, 'grade2_level_1');
  });

  test('coach reports only rounds completed in the last seven days', () {
    final plan = SmartLearningCoachService.build(
      grade: 1,
      now: now,
      attempts: [
        attempt(
          type: 'grade1_level_1',
          grade: 1,
          score: 8,
          total: 10,
          completedAt: now.subtract(const Duration(days: 2)),
        ),
        attempt(
          type: 'grade1_level_1',
          grade: 1,
          score: 8,
          total: 10,
          completedAt: now.subtract(const Duration(days: 8)),
        ),
      ],
    );

    expect(plan.practiceRounds, 2);
    expect(plan.recentRounds, 1);
  });
}
