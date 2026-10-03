import '../models/task_attempt.dart';

class SkillProgress {
  final String taskType;
  final int grade;
  final String titleEn;
  final String titleSi;
  final String emoji;
  final int rounds;
  final int correct;
  final int total;
  final double? latestShapeSimilarity;

  const SkillProgress({
    required this.taskType,
    required this.grade,
    required this.titleEn,
    required this.titleSi,
    required this.emoji,
    required this.rounds,
    required this.correct,
    required this.total,
    this.latestShapeSimilarity,
  });

  double get accuracy => total == 0 ? 0 : correct / total * 100;
  double get displayAccuracy =>
      taskType == 'letter_tracing' && latestShapeSimilarity != null
      ? latestShapeSimilarity! * 100
      : accuracy;
}

class ProgressAnalytics {
  final int practiceRounds;
  final int correctAnswers;
  final int totalAnswers;
  final List<SkillProgress> skills;
  final double? latestTraceSimilarity;
  final String? latestTraceLetter;

  const ProgressAnalytics({
    required this.practiceRounds,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.skills,
    this.latestTraceSimilarity,
    this.latestTraceLetter,
  });

  const ProgressAnalytics.empty()
    : practiceRounds = 0,
      correctAnswers = 0,
      totalAnswers = 0,
      skills = const [],
      latestTraceSimilarity = null,
      latestTraceLetter = null;

  double get practiceAccuracy =>
      totalAnswers == 0 ? 0 : correctAnswers / totalAnswers * 100;

  SkillProgress? get focusSkill => skills.isEmpty ? null : skills.first;

  factory ProgressAnalytics.fromAttempts(
    Iterable<TaskAttempt> attempts, {
    int? grade,
  }) {
    final relevant = attempts
        .where((attempt) => grade == null || attempt.grade == grade)
        .toList();
    final aggregates = <String, _MutableSkillProgress>{};

    var correct = 0;
    var total = 0;
    DateTime? latestTraceAt;
    double? latestTraceSimilarity;
    String? latestTraceLetter;
    for (final attempt in relevant) {
      correct += attempt.score;
      total += attempt.total;
      final aggregate = aggregates.putIfAbsent(
        '${attempt.grade}:${attempt.taskType}',
        () => _MutableSkillProgress(attempt.taskType, attempt.grade),
      );
      aggregate.rounds++;
      aggregate.correct += attempt.score;
      aggregate.total += attempt.total;
      final shapeValues = attempt.items
          .map((item) => item.shapeSimilarity)
          .whereType<double>()
          .toList(growable: false);
      final attemptShape = shapeValues.isEmpty
          ? null
          : shapeValues.reduce((a, b) => a + b) / shapeValues.length;
      if (aggregate.latestAt == null ||
          attempt.completedAt.isAfter(aggregate.latestAt!)) {
        aggregate.latestAt = attempt.completedAt;
        aggregate.latestShapeSimilarity = attemptShape;
      }
      if (attempt.taskType == 'letter_tracing' &&
          attemptShape != null &&
          (latestTraceAt == null ||
              attempt.completedAt.isAfter(latestTraceAt))) {
        latestTraceAt = attempt.completedAt;
        latestTraceSimilarity = attemptShape;
        latestTraceLetter = attempt.items.isEmpty
            ? null
            : attempt.items.first.itemId;
      }
    }

    final skills =
        aggregates.values.map((aggregate) {
          final labels = taskTypeLabels[aggregate.taskType];
          return SkillProgress(
            taskType: aggregate.taskType,
            grade: aggregate.grade,
            titleEn: labels?[0] ?? aggregate.taskType,
            titleSi: labels?[1] ?? aggregate.taskType,
            emoji: labels?[2] ?? '🎯',
            rounds: aggregate.rounds,
            correct: aggregate.correct,
            total: aggregate.total,
            latestShapeSimilarity: aggregate.latestShapeSimilarity,
          );
        }).toList()..sort((a, b) {
          final accuracyOrder = a.accuracy.compareTo(b.accuracy);
          if (accuracyOrder != 0) return accuracyOrder;
          return b.rounds.compareTo(a.rounds);
        });

    return ProgressAnalytics(
      practiceRounds: relevant.length,
      correctAnswers: correct,
      totalAnswers: total,
      skills: List.unmodifiable(skills),
      latestTraceSimilarity: latestTraceSimilarity,
      latestTraceLetter: latestTraceLetter,
    );
  }
}

class _MutableSkillProgress {
  final String taskType;
  final int grade;
  int rounds = 0;
  int correct = 0;
  int total = 0;
  DateTime? latestAt;
  double? latestShapeSimilarity;

  _MutableSkillProgress(this.taskType, this.grade);
}
