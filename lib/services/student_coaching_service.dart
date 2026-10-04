import '../models/quiz_attempt.dart';
import '../models/reading_session.dart';
import '../models/task_attempt.dart';
import 'daily_activity_service.dart';
import 'progress_analytics_service.dart';

enum CoachingTrend { newLearner, improving, steady, needsSupport }

enum SkillMasteryLevel { starting, practising, improving, mastered }

class CoachingCopy {
  final String en;
  final String si;

  const CoachingCopy(this.en, this.si);

  String forLanguage(bool isSinhala) => isSinhala ? si : en;
}

class CoachingMistakePattern {
  final String itemId;
  final int attempts;
  final int mistakes;

  const CoachingMistakePattern({
    required this.itemId,
    required this.attempts,
    required this.mistakes,
  });

  double get accuracy =>
      attempts == 0 ? 0 : (attempts - mistakes) / attempts * 100;
}

class CoachingSkillMastery {
  final SkillProgress skill;
  final SkillMasteryLevel level;

  const CoachingSkillMastery({required this.skill, required this.level});
}

class CoachingDay {
  final int day;
  final String emoji;
  final int minutes;
  final CoachingCopy title;
  final CoachingCopy instruction;

  const CoachingDay({
    required this.day,
    required this.emoji,
    required this.minutes,
    required this.title,
    required this.instruction,
  });
}

class StudentCoachingReport {
  final CoachingTrend trend;
  final int activeDays;
  final int openedOnlyDays;
  final CoachingCopy consistency;
  final CoachingCopy nextActivity;
  final CoachingCopy nextActivityReason;
  final CoachingCopy suggestedGoal;
  final CoachingCopy parentGuidance;
  final List<CoachingMistakePattern> mistakes;
  final List<CoachingSkillMastery> mastery;
  final List<CoachingDay> weeklyPlan;
  final List<CoachingCopy> achievements;

  const StudentCoachingReport({
    required this.trend,
    required this.activeDays,
    required this.openedOnlyDays,
    required this.consistency,
    required this.nextActivity,
    required this.nextActivityReason,
    required this.suggestedGoal,
    required this.parentGuidance,
    required this.mistakes,
    required this.mastery,
    required this.weeklyPlan,
    required this.achievements,
  });
}

/// Produces explainable coaching advice from recorded learning evidence.
/// This is deterministic and runs locally from the supplied evidence.
class StudentCoachingService {
  static StudentCoachingReport build({
    required int grade,
    required List<TaskAttempt> taskAttempts,
    required List<ReadingSession> readingSessions,
    required List<QuizAttempt> quizAttempts,
    required List<DailyActivityLog> dailyLogs,
    DateTime? now,
  }) {
    final analytics = ProgressAnalytics.fromAttempts(
      taskAttempts,
      grade: grade,
    );
    final mistakes = _mistakePatterns(taskAttempts, grade);
    final mastery = analytics.skills
        .map(
          (skill) =>
              CoachingSkillMastery(skill: skill, level: _masteryLevel(skill)),
        )
        .toList(growable: false);
    final trend = _trend(taskAttempts, quizAttempts, grade);
    final recentLogs = _recentLogs(dailyLogs, now ?? DateTime.now());
    final activeDays = recentLogs
        .where((log) => log.hasLearningActivity)
        .length;
    final openedOnlyDays = recentLogs
        .where((log) => log.wasOpened && !log.hasLearningActivity)
        .length;
    final comprehension = _quizAccuracy(quizAttempts);
    final focus = analytics.focusSkill;
    final next = _nextActivity(
      grade: grade,
      focus: focus,
      comprehension: comprehension,
      mistakes: mistakes,
    );

    return StudentCoachingReport(
      trend: trend,
      activeDays: activeDays,
      openedOnlyDays: openedOnlyDays,
      consistency: _consistency(activeDays, openedOnlyDays),
      nextActivity: next.$1,
      nextActivityReason: next.$2,
      suggestedGoal: _goal(focus, activeDays),
      parentGuidance: _parentGuidance(focus, mistakes, comprehension),
      mistakes: mistakes,
      mastery: mastery,
      weeklyPlan: _weeklyPlan(
        grade: grade,
        focus: focus,
        mistakes: mistakes,
        comprehension: comprehension,
      ),
      achievements: _achievements(
        trend: trend,
        activeDays: activeDays,
        readingCount: readingSessions.length,
        taskCount: taskAttempts.where((item) => item.grade == grade).length,
        mastery: mastery,
      ),
    );
  }

  static List<CoachingMistakePattern> _mistakePatterns(
    List<TaskAttempt> attempts,
    int grade,
  ) {
    final values = <String, _MutableMistake>{};
    for (final attempt in attempts.where((item) => item.grade == grade)) {
      for (final item in attempt.items.where(
        (item) => item.itemId.trim().isNotEmpty,
      )) {
        final key = item.itemId.trim();
        final value = values.putIfAbsent(key, _MutableMistake.new);
        value.attempts++;
        if (!item.isCorrect) value.mistakes++;
      }
    }
    final result =
        values.entries
            .where((entry) => entry.value.mistakes > 0)
            .map(
              (entry) => CoachingMistakePattern(
                itemId: entry.key,
                attempts: entry.value.attempts,
                mistakes: entry.value.mistakes,
              ),
            )
            .toList()
          ..sort((a, b) {
            final mistakeOrder = b.mistakes.compareTo(a.mistakes);
            return mistakeOrder != 0
                ? mistakeOrder
                : a.accuracy.compareTo(b.accuracy);
          });
    return List.unmodifiable(result.take(5));
  }

  static SkillMasteryLevel _masteryLevel(SkillProgress skill) {
    final accuracy = skill.displayAccuracy;
    if (skill.rounds >= 2 && accuracy >= 85) return SkillMasteryLevel.mastered;
    if (accuracy >= 70) return SkillMasteryLevel.improving;
    if (accuracy >= 50 || skill.rounds >= 2) {
      return SkillMasteryLevel.practising;
    }
    return SkillMasteryLevel.starting;
  }

  static CoachingTrend _trend(
    List<TaskAttempt> tasks,
    List<QuizAttempt> quizzes,
    int grade,
  ) {
    final evidence = <_PerformanceEvidence>[
      ...tasks
          .where((item) => item.grade == grade && item.total > 0)
          .map(
            (item) => _PerformanceEvidence(item.completedAt, item.percentage),
          ),
      ...quizzes
          .where((item) => item.total > 0)
          .map(
            (item) => _PerformanceEvidence(item.completedAt, item.percentage),
          ),
    ]..sort((a, b) => a.when.compareTo(b.when));
    if (evidence.length < 4) return CoachingTrend.newLearner;
    final split = evidence.length ~/ 2;
    final earlier = evidence.take(split).map((item) => item.score).toList();
    final recent = evidence.skip(split).map((item) => item.score).toList();
    final change = _average(recent) - _average(earlier);
    if (change >= 5) return CoachingTrend.improving;
    if (change <= -10) return CoachingTrend.needsSupport;
    return CoachingTrend.steady;
  }

  static double _average(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  static double? _quizAccuracy(List<QuizAttempt> quizzes) {
    final total = quizzes.fold<int>(0, (sum, item) => sum + item.total);
    if (total == 0) return null;
    final correct = quizzes.fold<int>(0, (sum, item) => sum + item.score);
    return correct / total * 100;
  }

  static (CoachingCopy, CoachingCopy) _nextActivity({
    required int grade,
    required SkillProgress? focus,
    required double? comprehension,
    required List<CoachingMistakePattern> mistakes,
  }) {
    if (focus != null && focus.displayAccuracy < 80) {
      final title = CoachingCopy(
        'Practise ${focus.titleEn}',
        '${focus.titleSi} පුහුණු කරන්න',
      );
      final item = mistakes.isEmpty ? null : mistakes.first.itemId;
      final reason = item == null
          ? CoachingCopy(
              'This is the lowest current skill at ${focus.displayAccuracy.round()}%.',
              'දැනට අඩුම කුසලතාව ${focus.displayAccuracy.round()}% යි.',
            )
          : CoachingCopy(
              'Start with “$item”, a frequently missed item, then complete one short round.',
              'නිතර වැරදෙන “$item” සමඟ ආරම්භ කර කෙටි වාරයක් සම්පූර්ණ කරන්න.',
            );
      return (title, reason);
    }
    if (comprehension != null && comprehension < 70) {
      return const (
        CoachingCopy('Reread one short story', 'කෙටි කතාවක් නැවත කියවන්න'),
        CoachingCopy(
          'Comprehension is below 70%; rereading before the quiz supports understanding.',
          'අවබෝධය 70% ට අඩු නිසා ප්‍රශ්නාවලියට පෙර නැවත කියවීම වැදගත්.',
        ),
      );
    }
    return grade == 1
        ? const (
            CoachingCopy(
              'Complete one letter-and-picture task',
              'අකුරු සහ රූප කාර්යයක් කරන්න',
            ),
            CoachingCopy(
              'A short mixed task maintains Grade 1 fluency.',
              'කෙටි මිශ්‍ර කාර්යයක් 1 ශ්‍රේණියේ හැකියාව පවත්වා ගනී.',
            ),
          )
        : const (
            CoachingCopy(
              'Complete one word-building task',
              'වචන ගොඩනැගීමේ කාර්යයක් කරන්න',
            ),
            CoachingCopy(
              'A short word task maintains Grade 2 fluency.',
              'කෙටි වචන කාර්යයක් 2 ශ්‍රේණියේ හැකියාව පවත්වා ගනී.',
            ),
          );
  }

  static CoachingCopy _consistency(int activeDays, int openedOnlyDays) {
    if (activeDays >= 5) {
      return const CoachingCopy('Strong routine', 'ශක්තිමත් දෛනික පුරුද්දක්');
    }
    if (activeDays >= 3) {
      return const CoachingCopy(
        'Building consistency',
        'නිතිපතා පුහුණුව වර්ධනය වෙයි',
      );
    }
    if (openedOnlyDays >= 2) {
      return CoachingCopy(
        'Opened without practice on $openedOnlyDays days',
        'දින $openedOnlyDays කදී පුහුණුවක් නොකර app එක විවෘත කර ඇත',
      );
    }
    return const CoachingCopy(
      'Needs a short daily routine',
      'කෙටි දෛනික පුහුණුවක් අවශ්‍යයි',
    );
  }

  static CoachingCopy _goal(SkillProgress? focus, int activeDays) {
    final targetDays = activeDays >= 5 ? 5 : 4;
    if (focus == null) {
      return CoachingCopy(
        'Complete one learning activity on $targetDays days this week.',
        'මෙම සතියේ දින $targetDays ක් එක් ඉගෙනුම් කාර්යයක් සම්පූර්ණ කරන්න.',
      );
    }
    return CoachingCopy(
      'Practise ${focus.titleEn} on $targetDays days and aim for at least 70%.',
      'දින $targetDays ක් ${focus.titleSi} පුහුණු කර අවම වශයෙන් 70% ක් ලබාගන්න.',
    );
  }

  static CoachingCopy _parentGuidance(
    SkillProgress? focus,
    List<CoachingMistakePattern> mistakes,
    double? comprehension,
  ) {
    if (mistakes.isNotEmpty) {
      final item = mistakes.first.itemId;
      return CoachingCopy(
        'Say “$item” aloud, show it once, and let the child try independently three times. Praise effort before correcting.',
        '“$item” ශබ්දයෙන් කියා එක්වරක් පෙන්වන්න. දරුවාට ස්වාධීනව තුන්වරක් උත්සාහ කිරීමට දෙන්න. නිවැරදි කිරීමට පෙර උත්සාහය අගය කරන්න.',
      );
    }
    if (comprehension != null && comprehension < 70) {
      return const CoachingCopy(
        'After each page, ask: “Who was there?” and “What happened?” Let the child answer in their own words.',
        'සෑම පිටුවකටම පසු “කවුද සිටියේ?” සහ “මොකද වුණේ?” යනුවෙන් අසන්න. දරුවාගේම වචනවලින් පිළිතුරු දීමට ඉඩ දෙන්න.',
      );
    }
    return CoachingCopy(
      'Share a ${focus == null ? 'five-minute story' : 'five-minute ${focus.titleEn} activity'} and finish with specific praise.',
      '${focus == null ? 'මිනිත්තු පහක කතාවක්' : 'මිනිත්තු පහක ${focus.titleSi} කාර්යයක්'} කර නිශ්චිත ප්‍රශංසාවකින් අවසන් කරන්න.',
    );
  }

  static List<CoachingDay> _weeklyPlan({
    required int grade,
    required SkillProgress? focus,
    required List<CoachingMistakePattern> mistakes,
    required double? comprehension,
  }) {
    final focusEn =
        focus?.titleEn ?? (grade == 1 ? 'letter matching' : 'word building');
    final focusSi =
        focus?.titleSi ?? (grade == 1 ? 'අකුරු ගැලපීම' : 'වචන ගොඩනැගීම');
    final difficult = mistakes.isEmpty
        ? null
        : mistakes.take(3).map((item) => item.itemId).join(', ');
    return [
      CoachingDay(
        day: 1,
        emoji: '🎯',
        minutes: 5,
        title: const CoachingCopy('Focus practice', 'ප්‍රමුඛ පුහුණුව'),
        instruction: CoachingCopy(
          'Complete one $focusEn round.',
          '$focusSi එක් වාරයක් සම්පූර්ණ කරන්න.',
        ),
      ),
      CoachingDay(
        day: 2,
        emoji: '🔁',
        minutes: 5,
        title: const CoachingCopy(
          'Correct common mistakes',
          'නිතර වැරදෙන දේ නිවැරදි කරමු',
        ),
        instruction: difficult == null
            ? const CoachingCopy(
                'Repeat the hardest items from Day 1.',
                'පළමු දිනයේ අපහසුම අයිතම නැවත කරන්න.',
              )
            : CoachingCopy(
                'Repeat: $difficult.',
                'නැවත පුහුණු කරන්න: $difficult.',
              ),
      ),
      CoachingDay(
        day: 3,
        emoji: '📖',
        minutes: 8,
        title: const CoachingCopy('Read and talk', 'කියවා කතා කරමු'),
        instruction: CoachingCopy(
          comprehension != null && comprehension < 70
              ? 'Reread a familiar story and answer its questions.'
              : 'Read one short story and discuss its main idea.',
          comprehension != null && comprehension < 70
              ? 'හුරු කතාවක් නැවත කියවා ප්‍රශ්නවලට පිළිතුරු දෙන්න.'
              : 'කෙටි කතාවක් කියවා එහි ප්‍රධාන අදහස කතා කරන්න.',
        ),
      ),
      CoachingDay(
        day: 4,
        emoji: grade == 1 ? '🖼️' : '🧩',
        minutes: 7,
        title: const CoachingCopy('Mixed challenge', 'මිශ්‍ර අභියෝගය'),
        instruction: CoachingCopy(
          grade == 1
              ? 'Complete a picture-to-letter task.'
              : 'Complete a word or sentence-building task.',
          grade == 1
              ? 'රූපයෙන් අකුරට කාර්යයක් කරන්න.'
              : 'වචන හෝ වාක්‍ය ගොඩනැගීමේ කාර්යයක් කරන්න.',
        ),
      ),
      CoachingDay(
        day: 5,
        emoji: '⭐',
        minutes: 5,
        title: const CoachingCopy('Check progress', 'ප්‍රගතිය පරීක්ෂා කරමු'),
        instruction: CoachingCopy(
          'Repeat one $focusEn round and compare the new score.',
          '$focusSi වාරයක් නැවත කර නව ලකුණු සසඳන්න.',
        ),
      ),
    ];
  }

  static List<CoachingCopy> _achievements({
    required CoachingTrend trend,
    required int activeDays,
    required int readingCount,
    required int taskCount,
    required List<CoachingSkillMastery> mastery,
  }) {
    final values = <CoachingCopy>[];
    if (activeDays >= 3) {
      values.add(const CoachingCopy('Routine Builder', 'දෛනික පුරුදු ශූරයා'));
    }
    if (readingCount >= 5) {
      values.add(const CoachingCopy('Story Explorer', 'කතා ගවේෂකයා'));
    }
    if (taskCount >= 5) {
      values.add(const CoachingCopy('Practice Star', 'පුහුණු තරුව'));
    }
    if (trend == CoachingTrend.improving) {
      values.add(const CoachingCopy('Growing Stronger', 'දියුණු වන ශූරයා'));
    }
    if (mastery.any((item) => item.level == SkillMasteryLevel.mastered)) {
      values.add(const CoachingCopy('Skill Master', 'කුසලතා ශූරයා'));
    }
    return List.unmodifiable(values);
  }

  static List<DailyActivityLog> _recentLogs(
    List<DailyActivityLog> logs,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final keys = List.generate(
      7,
      (index) => _dateKey(today.subtract(Duration(days: index))),
    ).toSet();
    return logs
        .where((log) => keys.contains(log.dateKey))
        .toList(growable: false);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _MutableMistake {
  int attempts = 0;
  int mistakes = 0;
}

class _PerformanceEvidence {
  final DateTime when;
  final double score;

  const _PerformanceEvidence(this.when, this.score);
}
