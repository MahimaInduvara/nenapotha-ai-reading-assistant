// lib/services/progress_insight_engine.dart
// Rule-based (no ML model) weekly insight generator for the Progress page.
// Aggregates TaskItemResult data (see task_attempt.dart) to identify the
// single specific letter/pillam a student is struggling with most, falling
// back to a task-type-level comparison, and finally to a celebration when
// nothing stands out as weak. Pure aggregation + thresholds — the "AI" here
// is a set of rules over real logged data, not a trained model.

import '../models/task_attempt.dart';

class WeeklyInsight {
  final String messageEn;
  final String messageSi;
  // The task type to link a "Practice this" button to, if the UI wants one.
  final String? suggestedTaskType;

  const WeeklyInsight({
    required this.messageEn,
    required this.messageSi,
    this.suggestedTaskType,
  });
}

class _Stat {
  final String taskType;
  final String
  label; // itemId for per-item stats, taskType itself for per-type stats
  int total = 0;
  int correct = 0;
  _Stat(this.taskType, this.label);
  double get accuracy => total > 0 ? correct / total : 0;
}

class ProgressInsightEngine {
  // Below this accuracy, a specific letter/pillam is called out by name.
  static const double _weakItemThreshold = 0.7;
  // Below this accuracy, a whole task type is called out (used only when no
  // single item was weak enough on its own to be worth naming).
  static const double _weakTypeThreshold = 0.75;
  // An item/type needs at least this many attempts before its accuracy is
  // trusted enough to call out — one unlucky miss on a single attempt
  // shouldn't be reported as "you struggle with this."
  static const int _minAttemptsForItem = 2;

  /// Generates a short weekly insight from [attempts] (typically
  /// `TaskProgressService().getAttempts()`). Prefers the last 7 days; falls
  /// back to full history when the week has too little data to be
  /// meaningful (fewer than 3 attempts).
  static WeeklyInsight generate(List<TaskAttempt> attempts) {
    if (attempts.isEmpty) {
      return const WeeklyInsight(
        messageEn: "Complete a practice task to get your first insight! 🌟",
        messageSi: "ඔබේ පළමු තීක්ෂණාවලෝකනය ලබාගැනීමට පුහුණු කාර්යයක් කරන්න! 🌟",
      );
    }

    final weekCutoff = DateTime.now().subtract(const Duration(days: 7));
    var recent = attempts
        .where((a) => a.completedAt.isAfter(weekCutoff))
        .toList();
    if (recent.length < 3) {
      recent = attempts; // too sparse this week — use full history instead
    }

    // ── Per-item accuracy (taskType + itemId) ─────────────────────────────
    final itemStats = <String, _Stat>{};
    for (final a in recent) {
      for (final item in a.items) {
        final key = '${a.taskType}::${item.itemId}';
        final stat = itemStats.putIfAbsent(
          key,
          () => _Stat(a.taskType, item.itemId),
        );
        stat.total++;
        if (item.isCorrect) stat.correct++;
      }
    }

    final weakItems =
        itemStats.values.where((s) => s.total >= _minAttemptsForItem).toList()
          ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    if (weakItems.isNotEmpty && weakItems.first.accuracy < _weakItemThreshold) {
      final w = weakItems.first;
      final label = taskTypeLabels[w.taskType];
      final taskNameEn = label?[0] ?? w.taskType;
      final taskNameSi = label?[1] ?? w.taskType;
      final pct = (w.accuracy * 100).round();
      return WeeklyInsight(
        messageEn:
            'You\'re finding "${w.label}" tricky in $taskNameEn — $pct% correct so far. '
            'A bit more practice there should help! 💪',
        messageSi:
            '$taskNameSi හි "${w.label}" ටිකක් අපහසුයි — දැනට $pct% නිවැරදියි. '
            'ටිකක් තවත් පුහුණු වෙමු! 💪',
        suggestedTaskType: w.taskType,
      );
    }

    // ── No single item stood out — compare whole task types instead ──────
    final typeStats = <String, _Stat>{};
    for (final a in recent) {
      final stat = typeStats.putIfAbsent(
        a.taskType,
        () => _Stat(a.taskType, a.taskType),
      );
      stat.total += a.total;
      stat.correct += a.score;
    }
    final byAccuracyAsc = typeStats.values.toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    if (byAccuracyAsc.isNotEmpty &&
        byAccuracyAsc.first.accuracy < _weakTypeThreshold) {
      final w = byAccuracyAsc.first;
      final label = taskTypeLabels[w.taskType];
      final taskNameEn = label?[0] ?? w.taskType;
      final taskNameSi = label?[1] ?? w.taskType;
      final pct = (w.accuracy * 100).round();
      return WeeklyInsight(
        messageEn:
            '$taskNameEn is your toughest area this week at $pct% — try a few more rounds! 🎯',
        messageSi:
            '$taskNameSi මෙම සතියේ දුෂ්කරම කාර්යයයි ($pct%) — තව ටිකක් පුහුණු වෙන්න! 🎯',
        suggestedTaskType: w.taskType,
      );
    }

    // ── Nothing weak — celebrate the strongest area instead ──────────────
    final byAccuracyDesc = typeStats.values.toList()
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));
    final best = byAccuracyDesc.first;
    final bestLabel = taskTypeLabels[best.taskType];
    return WeeklyInsight(
      messageEn:
          'Great week! You\'re doing especially well with '
          '${bestLabel?[0] ?? best.taskType} 🌟. Keep it up!',
      messageSi:
          'විශිෂ්ට සතියක්! ${bestLabel?[1] ?? best.taskType} හි ඔබ විශේෂයෙන් '
          'හොඳින් කරගෙන යනවා 🌟. දිගටම කරගෙන යන්න!',
    );
  }
}
