import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/quiz_attempt.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/services/daily_activity_service.dart';
import 'package:reading_assistant_app/services/student_coaching_service.dart';

void main() {
  group('StudentCoachingService', () {
    test('gives a safe five-day starter plan when evidence is empty', () {
      final report = StudentCoachingService.build(
        grade: 1,
        taskAttempts: const [],
        readingSessions: const [],
        quizAttempts: const [],
        dailyLogs: const [],
        now: DateTime(2026, 9, 24),
      );

      expect(report.trend, CoachingTrend.newLearner);
      expect(report.weeklyPlan, hasLength(5));
      expect(report.weeklyPlan.every((day) => day.minutes >= 5), isTrue);
      expect(report.mistakes, isEmpty);
      expect(report.nextActivity.en, contains('letter'));
    });

    test('identifies repeated item mistakes and skill mastery', () {
      final attempts = [
        _attempt(
          score: 1,
          items: const [
            TaskItemResult(itemId: 'අ', isCorrect: false),
            TaskItemResult(itemId: 'ආ', isCorrect: true),
          ],
          day: 1,
        ),
        _attempt(
          score: 1,
          items: const [
            TaskItemResult(itemId: 'අ', isCorrect: false),
            TaskItemResult(itemId: 'ආ', isCorrect: true),
          ],
          day: 2,
        ),
      ];

      final report = StudentCoachingService.build(
        grade: 1,
        taskAttempts: attempts,
        readingSessions: const [],
        quizAttempts: const [],
        dailyLogs: const [],
        now: DateTime(2026, 9, 24),
      );

      expect(report.mistakes.first.itemId, 'අ');
      expect(report.mistakes.first.mistakes, 2);
      expect(report.mastery.single.level, SkillMasteryLevel.practising);
      expect(report.nextActivityReason.en, contains('අ'));
    });

    test('uses chronological evidence to detect improvement', () {
      final attempts = [
        _attempt(score: 1, total: 5, day: 1),
        _attempt(score: 2, total: 5, day: 2),
        _attempt(score: 4, total: 5, day: 3),
        _attempt(score: 5, total: 5, day: 4),
      ];

      final report = StudentCoachingService.build(
        grade: 1,
        taskAttempts: attempts,
        readingSessions: const [],
        quizAttempts: const [],
        dailyLogs: const [],
        now: DateTime(2026, 9, 24),
      );

      expect(report.trend, CoachingTrend.improving);
      expect(
        report.achievements.map((item) => item.en),
        contains('Growing Stronger'),
      );
    });

    test('distinguishes active days from app-open-only days', () {
      final logs = [
        _log('2026-09-24', activities: 1, opens: 1),
        _log('2026-09-23', activities: 2, opens: 1),
        _log('2026-09-22', activities: 1, opens: 2),
        _log('2026-09-21', activities: 0, opens: 1),
        _log('2026-09-20', activities: 0, opens: 1),
      ];

      final report = StudentCoachingService.build(
        grade: 1,
        taskAttempts: const [],
        readingSessions: const [],
        quizAttempts: const <QuizAttempt>[],
        dailyLogs: logs,
        now: DateTime(2026, 9, 24),
      );

      expect(report.activeDays, 3);
      expect(report.openedOnlyDays, 2);
      expect(report.consistency.en, 'Building consistency');
      expect(
        report.achievements.map((item) => item.en),
        contains('Routine Builder'),
      );
    });
  });
}

TaskAttempt _attempt({
  required int score,
  int total = 2,
  required int day,
  List<TaskItemResult> items = const [],
}) => TaskAttempt(
  taskType: 'letter_matching',
  grade: 1,
  language: 'sinhala',
  score: score,
  total: total,
  completedAt: DateTime(2026, 9, day),
  items: items,
);

DailyActivityLog _log(
  String dateKey, {
  required int activities,
  required int opens,
}) => DailyActivityLog(
  dateKey: dateKey,
  appOpenCount: opens,
  activitiesCompleted: activities,
  taskAttempts: activities,
  readingSessions: 0,
  quizAttempts: 0,
  lastActiveAt: DateTime.parse(dateKey),
);
