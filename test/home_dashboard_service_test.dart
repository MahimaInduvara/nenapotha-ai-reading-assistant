import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/student_progress.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/services/home_dashboard_service.dart';

void main() {
  StudentProgress emptyProgress() => StudentProgress.empty(
    studentId: 'student-1',
    studentName: 'Nimali',
    gradeLevel: 1,
  );

  TaskAttempt attempt(DateTime completedAt) => TaskAttempt(
    taskType: 'letter_recognition',
    grade: 1,
    language: 'sinhala',
    score: 8,
    total: 10,
    completedAt: completedAt,
  );

  test('today summary counts only attempts completed today', () {
    final now = DateTime(2026, 9, 6, 15);
    final summary = HomeDashboardService.summarize(
      attempts: [
        attempt(now.subtract(const Duration(hours: 1))),
        attempt(now.subtract(const Duration(days: 1))),
      ],
      progress: emptyProgress(),
      now: now,
    );

    expect(summary.completed, 1);
    expect(summary.hasActivity, isTrue);
  });

  test('today summary reports every completed activity without a goal cap', () {
    final now = DateTime(2026, 9, 6, 15);
    final summary = HomeDashboardService.summarize(
      attempts: List.generate(5, (_) => attempt(now)),
      progress: emptyProgress(),
      now: now,
    );

    expect(summary.completed, 5);
    expect(summary.hasActivity, isTrue);
  });
}
