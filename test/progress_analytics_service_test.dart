import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/services/progress_analytics_service.dart';

void main() {
  test('progress analytics combines every current-grade task type', () {
    final now = DateTime(2026, 9, 6);
    final analytics = ProgressAnalytics.fromAttempts([
      TaskAttempt(
        taskType: 'letter_recognition',
        grade: 1,
        language: 'sinhala',
        score: 8,
        total: 10,
        completedAt: now,
      ),
      TaskAttempt(
        taskType: 'letter_matching',
        grade: 1,
        language: 'english',
        score: 3,
        total: 5,
        completedAt: now,
      ),
      TaskAttempt(
        taskType: 'grade2_level_1',
        grade: 2,
        language: 'sinhala',
        score: 10,
        total: 10,
        completedAt: now,
      ),
    ], grade: 1);

    expect(analytics.practiceRounds, 2);
    expect(analytics.correctAnswers, 11);
    expect(analytics.totalAnswers, 15);
    expect(analytics.skills, hasLength(2));
    expect(analytics.focusSkill?.taskType, 'letter_matching');
    expect(analytics.practiceAccuracy, closeTo(73.33, 0.01));
  });

  test('progress analytics has an honest empty state', () {
    final analytics = ProgressAnalytics.fromAttempts(const [], grade: 2);

    expect(analytics.practiceRounds, 0);
    expect(analytics.practiceAccuracy, 0);
    expect(analytics.focusSkill, isNull);
  });

  test('unfiltered analytics connects Grade 1 and Grade 2 activity', () {
    final now = DateTime(2026, 9, 6);
    final analytics = ProgressAnalytics.fromAttempts([
      TaskAttempt(
        taskType: 'grade1_level_1',
        grade: 1,
        language: 'english',
        score: 4,
        total: 5,
        completedAt: now,
      ),
      TaskAttempt(
        taskType: 'grade2_level_1',
        grade: 2,
        language: 'sinhala',
        score: 8,
        total: 10,
        completedAt: now,
      ),
    ]);

    expect(analytics.practiceRounds, 2);
    expect(analytics.skills.map((skill) => skill.grade).toSet(), {1, 2});
  });

  test('latest tracing similarity is separate from historical pass rate', () {
    final now = DateTime(2026, 9, 22);
    final analytics = ProgressAnalytics.fromAttempts([
      TaskAttempt(
        taskType: 'letter_tracing',
        grade: 1,
        language: 'sinhala',
        score: 0,
        total: 1,
        completedAt: now.subtract(const Duration(days: 1)),
        items: const [
          TaskItemResult(itemId: 'අ', isCorrect: false, shapeSimilarity: .22),
        ],
      ),
      TaskAttempt(
        taskType: 'letter_tracing',
        grade: 1,
        language: 'sinhala',
        score: 1,
        total: 1,
        completedAt: now,
        items: const [
          TaskItemResult(itemId: 'ආ', isCorrect: true, shapeSimilarity: .98),
        ],
      ),
    ], grade: 1);

    final tracing = analytics.skills.single;
    expect(tracing.accuracy, 50);
    expect(tracing.displayAccuracy, 98);
    expect(analytics.latestTraceSimilarity, .98);
    expect(analytics.latestTraceLetter, 'ආ');
  });
}
