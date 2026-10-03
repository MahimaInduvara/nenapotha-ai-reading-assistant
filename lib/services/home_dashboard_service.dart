import '../models/student_progress.dart';
import '../models/task_attempt.dart';

class HomeTodaySummary {
  final int completed;

  const HomeTodaySummary({required this.completed});

  bool get hasActivity => completed > 0;
}

/// Counts only persisted practice attempts and completed reading sessions.
abstract final class HomeDashboardService {
  static HomeTodaySummary summarize({
    required List<TaskAttempt> attempts,
    required StudentProgress progress,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final practiceCount = attempts.where((attempt) {
      final completed = attempt.completedAt.toLocal();
      return completed.year == today.year &&
          completed.month == today.month &&
          completed.day == today.day;
    }).length;
    final readingCount = progress.last30Days
        .where((activity) {
          final date = activity.date.toLocal();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        })
        .fold<int>(0, (total, activity) => total + activity.storiesRead);

    return HomeTodaySummary(completed: practiceCount + readingCount);
  }
}
