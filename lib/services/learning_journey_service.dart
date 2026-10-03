class LearningJourneySummary {
  final int totalLevels;
  final int masteredLevels;
  final int nextLevel;
  final double currentScore;

  const LearningJourneySummary({
    required this.totalLevels,
    required this.masteredLevels,
    required this.nextLevel,
    required this.currentScore,
  });

  bool get isComplete => masteredLevels == totalLevels;

  double get completion => totalLevels == 0 ? 0 : masteredLevels / totalLevels;
}

/// Turns persisted level scores into the child's next safe learning step.
/// Mastery is deliberately sequential: a later score cannot skip an earlier
/// prerequisite level in the guided journey.
abstract final class LearningJourneyService {
  static LearningJourneySummary summarize(
    List<double?> percentages, {
    double unlockPercentage = 70,
  }) {
    var mastered = 0;
    for (final percentage in percentages) {
      if ((percentage ?? 0) < unlockPercentage) break;
      mastered++;
    }

    if (percentages.isEmpty) {
      return const LearningJourneySummary(
        totalLevels: 0,
        masteredLevels: 0,
        nextLevel: 0,
        currentScore: 0,
      );
    }

    final complete = mastered == percentages.length;
    final nextIndex = complete ? percentages.length - 1 : mastered;
    return LearningJourneySummary(
      totalLevels: percentages.length,
      masteredLevels: mastered,
      nextLevel: nextIndex + 1,
      currentScore: percentages[nextIndex] ?? 0,
    );
  }
}
