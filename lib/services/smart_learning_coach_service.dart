import '../models/task_attempt.dart';
import 'progress_analytics_service.dart';

enum CoachStage { starting, support, growing, challenge }

class CoachPlan {
  final int grade;
  final CoachStage stage;
  final int practiceRounds;
  final int recentRounds;
  final int correctAnswers;
  final int totalAnswers;
  final double accuracy;
  final String focusTaskType;
  final String? weakItem;
  final double? weakItemAccuracy;
  final List<String> recommendedTaskTypes;

  const CoachPlan({
    required this.grade,
    required this.stage,
    required this.practiceRounds,
    required this.recentRounds,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.accuracy,
    required this.focusTaskType,
    required this.weakItem,
    required this.weakItemAccuracy,
    required this.recommendedTaskTypes,
  });

  bool get hasEvidence => practiceRounds > 0 && totalAnswers > 0;

  String get focusTitleEn => taskTypeLabels[focusTaskType]?[0] ?? focusTaskType;
  String get focusTitleSi => taskTypeLabels[focusTaskType]?[1] ?? focusTaskType;
  String get focusEmoji => taskTypeLabels[focusTaskType]?[2] ?? '🎯';
}

class SmartLearningCoachService {
  static const _grade1Path = [
    'grade1_level_1',
    'grade1_level_2',
    'grade1_level_3',
    'grade1_level_4',
    'grade1_level_5',
  ];
  static const _grade2Path = [
    'grade2_level_1',
    'grade2_level_2',
    'grade2_level_3',
    'grade2_level_4',
    'grade2_level_5',
    'grade2_level_6',
  ];

  static CoachPlan build({
    required Iterable<TaskAttempt> attempts,
    required int grade,
    DateTime? now,
  }) {
    final relevant =
        attempts.where((attempt) => attempt.grade == grade).toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final analytics = ProgressAnalytics.fromAttempts(relevant, grade: grade);
    final path = grade == 2 ? _grade2Path : _grade1Path;
    final fallback = path.first;
    final analyticsFocus = analytics.focusSkill?.taskType ?? fallback;
    final accuracy = analytics.practiceAccuracy;
    final stage = analytics.skills.isEmpty
        ? CoachStage.starting
        : accuracy < 60
        ? CoachStage.support
        : accuracy < 80
        ? CoachStage.growing
        : CoachStage.challenge;

    final itemStats = <String, _ItemStat>{};
    for (final attempt in relevant.take(30)) {
      for (final item in attempt.items) {
        final key = '${attempt.taskType}::${item.itemId}';
        final stat = itemStats.putIfAbsent(
          key,
          () => _ItemStat(attempt.taskType, item.itemId),
        );
        stat.total++;
        if (item.isCorrect) stat.correct++;
      }
    }
    final trustedItems =
        itemStats.values.where((item) => item.total >= 2).toList()
          ..sort((a, b) {
            final result = a.accuracy.compareTo(b.accuracy);
            return result != 0 ? result : b.total.compareTo(a.total);
          });
    final weak = trustedItems.isNotEmpty && trustedItems.first.accuracy < .7
        ? trustedItems.first
        : null;

    final focus = weak?.taskType ?? analyticsFocus;
    final focusIndex = path.indexOf(focus);
    final normalizedFocus = focusIndex == -1 ? fallback : focus;
    final normalizedIndex = path.indexOf(normalizedFocus);
    final next = path[(normalizedIndex + 1).clamp(0, path.length - 1)];
    final warmUp = path[normalizedIndex == 0 ? 0 : normalizedIndex - 1];
    final recommendations = stage == CoachStage.starting
        ? path.take(3).toList()
        : stage == CoachStage.challenge
        ? <String>[focus, next, path.last]
        : <String>[warmUp, focus, focus];

    final today = now ?? DateTime.now();
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));

    return CoachPlan(
      grade: grade,
      stage: stage,
      practiceRounds: analytics.practiceRounds,
      recentRounds: relevant
          .where((attempt) => !attempt.completedAt.isBefore(weekStart))
          .length,
      correctAnswers: analytics.correctAnswers,
      totalAnswers: analytics.totalAnswers,
      accuracy: accuracy,
      focusTaskType: focus,
      weakItem: weak?.itemId,
      weakItemAccuracy: weak == null ? null : weak.accuracy * 100,
      recommendedTaskTypes: List.unmodifiable(recommendations),
    );
  }
}

class _ItemStat {
  final String taskType;
  final String itemId;
  int correct = 0;
  int total = 0;

  _ItemStat(this.taskType, this.itemId);

  double get accuracy => total == 0 ? 0 : correct / total;
}
