// lib/models/student_progress.dart

class DailyActivity {
  final DateTime date;
  final int minutesRead;
  final int storiesRead;
  const DailyActivity({
    required this.date,
    required this.minutesRead,
    required this.storiesRead,
  });
}

class WeeklyReadingData {
  final String dayLabel;
  final int minutes;
  const WeeklyReadingData(this.dayLabel, this.minutes);
}

class ComprehensionByType {
  final String type;
  final String typeSi;
  final int correct;
  final int total;
  double get percentage => total > 0 ? correct / total * 100 : 0;
  const ComprehensionByType({
    required this.type,
    required this.typeSi,
    required this.correct,
    required this.total,
  });
}

class VocabularyWord {
  final String wordEn;
  final String wordSi;
  final String category;
  final int practiceCount;
  final double masteryLevel; // 0.0-1.0
  final DateTime learnedDate;
  const VocabularyWord({
    required this.wordEn,
    required this.wordSi,
    required this.category,
    required this.practiceCount,
    required this.masteryLevel,
    required this.learnedDate,
  });
}

class Achievement {
  final String id;
  final String title;
  final String titleSi;
  final String description;
  final String descSi;
  final String emoji;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final String
  category; // 'reading','comprehension','vocabulary','streak','time'
  const Achievement({
    required this.id,
    required this.title,
    required this.titleSi,
    required this.description,
    required this.descSi,
    required this.emoji,
    required this.isUnlocked,
    this.unlockedDate,
    required this.category,
  });
}

class StudentProgress {
  final String studentId;
  final String studentName;
  final int gradeLevel;

  // ── Reading Overview ──────────────────────────────────────────────────────
  final int totalStoriesAllTime;
  final int totalStoriesThisMonth;
  final int totalMinutesRead;
  final int currentStreak;
  final int longestStreak;
  final int daysActiveThisWeek;

  // ── Reading Progress ──────────────────────────────────────────────────────
  final int currentReadingLevel;
  final int storiesCompleted;
  final int storiesStarted;
  final double storiesPerWeek;
  final int maxMinutesPerSession;
  final List<WeeklyReadingData> weeklyData;
  final List<DailyActivity> last30Days;

  // ── Comprehension ─────────────────────────────────────────────────────────
  final double overallComprehension;
  final List<ComprehensionByType> comprehensionByType;
  final List<double> comprehensionTrend; // last 8 scores
  final int totalQuestionsAnswered;
  final int totalQuestionsCorrect;
  final double avgTimePerQuestion; // seconds

  // ── Vocabulary ────────────────────────────────────────────────────────────
  final int totalWordsSi;
  final int totalWordsEn;
  final int wordsLearnedThisWeek;
  final int wordsLearnedThisMonth;
  final double vocabularyRetentionRate;
  final double wordMasteryPercent;
  final List<VocabularyWord> recentWords;
  final List<VocabularyWord> needsPracticeWords;

  // ── Engagement ────────────────────────────────────────────────────────────
  final double sessionCompletionRate;
  final double avgHelpRequestsPerSession;
  final int totalPoints;
  final int totalStars;
  final int currentLevel;
  final double nextLevelProgress;

  // ── Achievements ──────────────────────────────────────────────────────────
  final List<Achievement> achievements;

  const StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.gradeLevel,
    required this.totalStoriesAllTime,
    required this.totalStoriesThisMonth,
    required this.totalMinutesRead,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysActiveThisWeek,
    required this.currentReadingLevel,
    required this.storiesCompleted,
    required this.storiesStarted,
    required this.storiesPerWeek,
    required this.maxMinutesPerSession,
    required this.weeklyData,
    required this.last30Days,
    required this.overallComprehension,
    required this.comprehensionByType,
    required this.comprehensionTrend,
    required this.totalQuestionsAnswered,
    required this.totalQuestionsCorrect,
    required this.avgTimePerQuestion,
    required this.totalWordsSi,
    required this.totalWordsEn,
    required this.wordsLearnedThisWeek,
    required this.wordsLearnedThisMonth,
    required this.vocabularyRetentionRate,
    required this.wordMasteryPercent,
    required this.recentWords,
    required this.needsPracticeWords,
    required this.sessionCompletionRate,
    required this.avgHelpRequestsPerSession,
    required this.totalPoints,
    required this.totalStars,
    required this.currentLevel,
    required this.nextLevelProgress,
    required this.achievements,
  });

  int get totalVocabulary => totalWordsSi + totalWordsEn;
  int get achievementsUnlocked =>
      achievements.where((a) => a.isUnlocked).length;

  /// All-zero/empty state, used as the synchronous initial value while the
  /// real (async, Firestore-backed) progress loads — never shown as if it
  /// were real data, just avoids a null-check dance in every screen that
  /// displays progress.
  factory StudentProgress.empty({
    required String studentId,
    required String studentName,
    required int gradeLevel,
  }) {
    return StudentProgress(
      studentId: studentId,
      studentName: studentName,
      gradeLevel: gradeLevel,
      totalStoriesAllTime: 0,
      totalStoriesThisMonth: 0,
      totalMinutesRead: 0,
      currentStreak: 0,
      longestStreak: 0,
      daysActiveThisWeek: 0,
      currentReadingLevel: gradeLevel,
      storiesCompleted: 0,
      storiesStarted: 0,
      storiesPerWeek: 0.0,
      maxMinutesPerSession: 0,
      weeklyData: const [],
      last30Days: const [],
      overallComprehension: 0.0,
      comprehensionByType: const [],
      comprehensionTrend: const [],
      totalQuestionsAnswered: 0,
      totalQuestionsCorrect: 0,
      avgTimePerQuestion: 0.0,
      totalWordsSi: 0,
      totalWordsEn: 0,
      wordsLearnedThisWeek: 0,
      wordsLearnedThisMonth: 0,
      vocabularyRetentionRate: 0.0,
      wordMasteryPercent: 0.0,
      recentWords: const [],
      needsPracticeWords: const [],
      sessionCompletionRate: 0.0,
      avgHelpRequestsPerSession: 0.0,
      totalPoints: 0,
      totalStars: 0,
      currentLevel: 1,
      nextLevelProgress: 0.0,
      achievements: const [],
    );
  }
}
