// lib/services/activity_service.dart
// Persists real reading sessions and quiz attempts to Firestore, and
// aggregates them (plus the existing local TaskProgressService data) into a
// real StudentProgress — replacing ProgressDataService.getMockProgress's
// fabricated numbers with whatever the student has actually done. Fields
// with no underlying data source (vocabulary tracking
// accuracy, achievements) are left at honest zero/empty rather than
// invented, matching the "no data yet" pattern already used elsewhere
// (e.g. TeacherDashboardScreen).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reading_session.dart';
import '../models/quiz_attempt.dart';
import '../models/student_progress.dart';
import '../models/task_attempt.dart';
import 'daily_activity_service.dart';
import 'storage_service.dart';
import 'story_data_service.dart';
import 'task_progress_service.dart';

/// One of the student's stories that has a saved session but isn't
/// finished — used by the Home screen's "Continue Reading" section.
class InProgressStory {
  final String storyId;
  final String titleEn;
  final String titleSi;
  final String emoji;
  final double progress; // 0.0-1.0, from ReadingSession.completionRate

  const InProgressStory({
    required this.storyId,
    required this.titleEn,
    required this.titleSi,
    required this.emoji,
    required this.progress,
  });
}

/// A single row in the unified Progress-page activity feed — one common
/// shape across the three heterogeneous sources that previously lived in
/// separate, siloed stat cards: practice-task attempts (SharedPreferences,
/// via TaskProgressService), reading-comprehension quizzes, and completed
/// reading sessions (both Firestore, via ActivityService itself).
class ActivityFeedItem {
  final String taskType; // task type, 'quiz', or 'reading_session'
  final String titleEn;
  final String titleSi;
  final String emoji;
  final String subtitleEn;
  final String subtitleSi;
  final double?
  percentage; // 0-100; null when a pass/fail % isn't meaningful (reading sessions)
  final DateTime completedAt;
  final int? gradeLevel;

  const ActivityFeedItem({
    required this.taskType,
    required this.titleEn,
    required this.titleSi,
    required this.emoji,
    required this.subtitleEn,
    required this.subtitleSi,
    this.percentage,
    required this.completedAt,
    this.gradeLevel,
  });
}

class ActivityService extends ChangeNotifier {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _sessionsRef(String studentId) =>
      _firestore
          .collection('students')
          .doc(studentId)
          .collection('readingSessions');
  CollectionReference<Map<String, dynamic>>? _quizzesRef(String studentId) =>
      _firestore
          .collection('students')
          .doc(studentId)
          .collection('quizAttempts');

  Future<void> saveReadingSession(ReadingSession session) async {
    final studentId = StorageService().getStudentId();
    if (studentId == null) {
      return; // no profile yet (shouldn't happen once past setup)
    }
    await _sessionsRef(studentId)!.add(session.toFirestoreMap());
    await DailyActivityService().recordCompletedActivity('reading');
    notifyListeners();
  }

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    final studentId = StorageService().getStudentId();
    if (studentId == null) return;
    await _quizzesRef(studentId)!.add(attempt.toFirestoreMap());
    await DailyActivityService().recordCompletedActivity('quiz');
    notifyListeners();
  }

  Future<List<ReadingSession>> getReadingSessions(String studentId) async {
    final snapshot = await _sessionsRef(
      studentId,
    )!.orderBy('startTime', descending: true).get();
    return snapshot.docs.map(ReadingSession.fromFirestore).toList();
  }

  Future<List<QuizAttempt>> getQuizAttempts(String studentId) async {
    final snapshot = await _quizzesRef(
      studentId,
    )!.orderBy('completedAt', descending: true).get();
    return snapshot.docs.map(QuizAttempt.fromFirestore).toList();
  }

  /// Stories the student has started but not finished, most recent first.
  ///
  /// NOTE: reading_screen.dart currently only calls saveReadingSession() from
  /// its completion dialog (see _showCompletionDialog/_saveReadingSession),
  /// so every session actually persisted today has completionRate == 1.0 —
  /// this will return an empty list until a mid-story autosave/abandon-
  /// tracking mechanism exists on the reading screen. That's an honest empty
  /// state, not a bug in this method (matches sessionCompletionRate's "no
  /// abandoned-session tracking to compare against" note in computeProgress
  /// above) — written against the real schema now so it starts working the
  /// moment that tracking is added, with no further changes needed here.
  Future<List<InProgressStory>> getInProgressStories(
    String studentId, {
    int limit = 5,
  }) async {
    final sessions = await getReadingSessions(
      studentId,
    ); // already ordered by startTime desc
    final seenStoryIds = <String>{};
    final result = <InProgressStory>[];
    for (final session in sessions) {
      if (!seenStoryIds.add(session.storyId)) {
        continue; // keep only the latest session per story
      }
      if (session.completionRate >= 1.0) {
        continue; // finished — not "in progress"
      }
      final story = StoryDataService.getStoryById(session.storyId);
      result.add(
        InProgressStory(
          storyId: session.storyId,
          titleEn: story?.titleEn ?? session.titleEn,
          titleSi: story?.titleSi ?? session.titleSi,
          emoji: story?.thumbnailUrl ?? '📖',
          progress: session.completionRate,
        ),
      );
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Unified chronological activity feed across all three activity sources
  /// — practice-task attempts, reading quizzes, and completed reading
  /// sessions — most recent first. Replaces the old design of siloing each
  /// source into its own unrelated stat card.
  Future<List<ActivityFeedItem>> getActivityFeed(
    String studentId, {
    int limit = 30,
  }) async {
    final sessions = await getReadingSessions(studentId);
    final quizzes = await getQuizAttempts(studentId);
    final taskAttempts = await TaskProgressService().getAttempts();

    final items = <ActivityFeedItem>[
      ...sessions.map(_feedItemFromReadingSession),
      ...quizzes.map(_feedItemFromQuizAttempt),
      ...taskAttempts.map(_feedItemFromTaskAttempt),
    ]..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return items.take(limit).toList();
  }

  ActivityFeedItem _feedItemFromTaskAttempt(TaskAttempt a) {
    final label = taskTypeLabels[a.taskType];
    return ActivityFeedItem(
      taskType: a.taskType,
      titleEn: label?[0] ?? a.taskType,
      titleSi: label?[1] ?? a.taskType,
      emoji: label?[2] ?? '🎯',
      subtitleEn: '${a.score}/${a.total} correct',
      subtitleSi: 'නිවැරදි ${a.score}/${a.total}',
      percentage: a.percentage,
      completedAt: a.completedAt,
      gradeLevel: a.grade,
    );
  }

  ActivityFeedItem _feedItemFromQuizAttempt(QuizAttempt q) {
    final story = StoryDataService.getStoryById(q.storyId);
    return ActivityFeedItem(
      taskType: 'quiz',
      titleEn: 'Reading Quiz',
      titleSi: 'කියවීමේ ප්‍රශ්නාවලිය',
      emoji: '🧠',
      subtitleEn: '${q.score}/${q.total} correct',
      subtitleSi: 'නිවැරදි ${q.score}/${q.total}',
      percentage: q.percentage,
      completedAt: q.completedAt,
      gradeLevel: story?.gradeLevel,
    );
  }

  ActivityFeedItem _feedItemFromReadingSession(ReadingSession s) {
    final minutes = (s.durationSeconds / 60).ceil();
    return ActivityFeedItem(
      taskType: 'reading_session',
      titleEn: s.titleEn.isNotEmpty ? s.titleEn : 'Story',
      titleSi: s.titleSi.isNotEmpty ? s.titleSi : 'කතාව',
      emoji: '📖',
      subtitleEn: minutes > 0 ? 'Completed · $minutes min' : 'Completed',
      subtitleSi: minutes > 0 ? 'සම්පූර්ණයි · මිනිත්තු $minutes' : 'සම්පූර්ණයි',
      percentage: null,
      completedAt: s.endTime ?? s.startTime,
      gradeLevel: s.gradeLevel,
    );
  }

  /// Builds a real StudentProgress from actual Firestore activity plus the
  /// existing local TaskAttempt history. Every number here is either
  /// genuinely computed or an honest zero — never a placeholder baseline.
  Future<StudentProgress> computeProgress({
    required String studentId,
    required String studentName,
    required int gradeLevel,
  }) async {
    final sessions = await getReadingSessions(studentId);
    final quizzes = await getQuizAttempts(studentId);
    final taskAttempts = await TaskProgressService().getAttempts();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    // ── Reading overview ────────────────────────────────────────────────
    final totalStories = sessions.length;
    final storiesThisMonth = sessions
        .where((s) => s.startTime.isAfter(startOfMonth))
        .length;
    final totalMinutes =
        sessions.fold<int>(0, (a, s) => a + s.durationSeconds) ~/ 60;

    // Distinct activity days across sessions, quizzes, and practice tasks —
    // used for both the streak and the weekly/30-day activity charts.
    final activityDates = <DateTime>{
      ...sessions.map((s) => _dateOnly(s.startTime)),
      ...quizzes.map((q) => _dateOnly(q.completedAt)),
      ...taskAttempts.map((t) => _dateOnly(t.completedAt)),
    };

    final currentStreak = _currentStreak(activityDates, today);
    final longestStreak = _longestStreak(activityDates);
    final daysActiveThisWeek = activityDates
        .where((d) => d.isAfter(today.subtract(const Duration(days: 7))))
        .length;

    // ── Weekly / 30-day charts ──────────────────────────────────────────
    final weeklyData = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final minutes =
          sessions
              .where((s) => _dateOnly(s.startTime) == day)
              .fold<int>(0, (a, s) => a + s.durationSeconds) ~/
          60;
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return WeeklyReadingData(labels[day.weekday - 1], minutes);
    });

    final last30Days = List.generate(30, (i) {
      final day = today.subtract(Duration(days: 29 - i));
      final daySessions = sessions.where((s) => _dateOnly(s.startTime) == day);
      return DailyActivity(
        date: day,
        minutesRead:
            daySessions.fold<int>(0, (a, s) => a + s.durationSeconds) ~/ 60,
        storiesRead: daySessions.length,
      );
    });

    // ── Comprehension (from quiz attempts) ──────────────────────────────
    final questionsAnswered = quizzes.fold<int>(0, (a, q) => a + q.total);
    final questionsCorrect = quizzes.fold<int>(0, (a, q) => a + q.score);
    final overallComprehension = questionsAnswered == 0
        ? 0.0
        : questionsCorrect / questionsAnswered * 100;

    final byType = <String, List<bool>>{};
    for (final q in quizzes) {
      for (final r in q.results) {
        byType.putIfAbsent(r.type, () => []).add(r.isCorrect);
      }
    }
    final comprehensionByType = byType.entries.map((e) {
      final correct = e.value.where((c) => c).length;
      return ComprehensionByType(
        type: e.key,
        typeSi: e.key,
        correct: correct,
        total: e.value.length,
      );
    }).toList();

    final comprehensionTrend = quizzes
        .take(8)
        .toList()
        .reversed
        .map((q) => q.percentage)
        .toList();

    // ── Engagement ───────────────────────────────────────────────────────
    final totalPoints = sessions.fold<int>(0, (a, s) => a + s.pointsEarned);
    final totalStars = sessions.fold<int>(0, (a, s) => a + s.starsEarned);
    final currentLevel = (totalPoints ~/ 500) + 1;
    final nextLevelProgress = (totalPoints % 500) / 500;
    final maxMinutesPerSession = sessions.isEmpty
        ? 0
        : sessions
              .map((s) => s.durationSeconds ~/ 60)
              .reduce((a, b) => a > b ? a : b);

    return StudentProgress(
      studentId: studentId,
      studentName: studentName,
      gradeLevel: gradeLevel,
      totalStoriesAllTime: totalStories,
      totalStoriesThisMonth: storiesThisMonth,
      totalMinutesRead: totalMinutes,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      daysActiveThisWeek: daysActiveThisWeek,
      currentReadingLevel: gradeLevel,
      storiesCompleted: totalStories,
      storiesStarted: totalStories,
      storiesPerWeek: sessions
          .where(
            (s) => s.startTime.isAfter(today.subtract(const Duration(days: 7))),
          )
          .length
          .toDouble(),
      maxMinutesPerSession: maxMinutesPerSession,
      weeklyData: weeklyData,
      last30Days: last30Days,
      overallComprehension: overallComprehension,
      comprehensionByType: comprehensionByType,
      comprehensionTrend: comprehensionTrend,
      totalQuestionsAnswered: questionsAnswered,
      totalQuestionsCorrect: questionsCorrect,
      avgTimePerQuestion:
          0.0, // not tracked — quiz screen doesn't time individual questions
      totalWordsSi: 0, // vocabulary helper doesn't persist saved words yet
      totalWordsEn: 0,
      wordsLearnedThisWeek: 0,
      wordsLearnedThisMonth: 0,
      vocabularyRetentionRate: 0.0,
      wordMasteryPercent: 0.0,
      recentWords: const [],
      needsPracticeWords: const [],
      sessionCompletionRate:
          0.0, // no abandoned-session tracking to compare against
      avgHelpRequestsPerSession: sessions.isEmpty
          ? 0.0
          : sessions.fold<int>(0, (a, s) => a + s.helpRequestsCount) /
                sessions.length,
      totalPoints: totalPoints,
      totalStars: totalStars,
      currentLevel: currentLevel,
      nextLevelProgress: nextLevelProgress,
      achievements: const [], // no achievement-unlock logic implemented yet
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _currentStreak(Set<DateTime> activityDates, DateTime today) {
    var streak = 0;
    var day = today;
    while (activityDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak(Set<DateTime> activityDates) {
    if (activityDates.isEmpty) return 0;
    final sorted = activityDates.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        longest = current > longest ? current : longest;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}
