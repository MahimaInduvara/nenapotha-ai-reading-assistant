import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/quiz_attempt.dart';
import '../models/reading_session.dart';
import '../models/student.dart';
import '../models/task_attempt.dart';
import '../services/activity_service.dart';
import '../services/daily_activity_service.dart';
import '../services/progress_analytics_service.dart';
import '../services/student_coaching_record_service.dart';
import '../services/student_coaching_service.dart';
import '../services/task_progress_service.dart';
import '../utils/app_colors.dart';
import 'teacher/widgets/teacher_coaching_panel.dart';

class TeacherStudentProgressScreen extends StatefulWidget {
  final Student student;
  final String selectedLanguage;

  const TeacherStudentProgressScreen({
    super.key,
    required this.student,
    required this.selectedLanguage,
  });

  @override
  State<TeacherStudentProgressScreen> createState() =>
      _TeacherStudentProgressScreenState();
}

class _TeacherStudentProgressScreenState
    extends State<TeacherStudentProgressScreen> {
  final ActivityService _activities = ActivityService();
  final TaskProgressService _taskProgress = TaskProgressService();
  final DailyActivityService _dailyActivity = DailyActivityService();
  final StudentCoachingRecordService _coachingRecords =
      StudentCoachingRecordService();
  List<ReadingSession>? _sessions;
  List<QuizAttempt>? _quizzes;
  List<TaskAttempt>? _taskAttempts;
  List<DailyActivityLog>? _dailyLogs;
  StudentCoachingRecord? _coachingRecord;
  String? _error;

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _sessions = null;
      _quizzes = null;
      _taskAttempts = null;
      _dailyLogs = null;
      _coachingRecord = null;
    });
    try {
      final results = await Future.wait<Object>([
        _activities.getReadingSessions(widget.student.id),
        _activities.getQuizAttempts(widget.student.id),
        _taskProgress.getStudentAttempts(widget.student.id),
        _dailyActivity.getLogs(widget.student.id),
        _coachingRecords.getRecord(widget.student.id),
      ]);
      if (!mounted) return;
      setState(() {
        _sessions = results[0] as List<ReadingSession>;
        _quizzes = results[1] as List<QuizAttempt>;
        _taskAttempts = results[2] as List<TaskAttempt>;
        _dailyLogs = results[3] as List<DailyActivityLog>;
        _coachingRecord = results[4] as StudentCoachingRecord;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          _isSi ? 'සිසු ප්‍රගතිය' : 'Student Progress',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: _isSi ? 'නැවුම් කරන්න' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) {
      return _messageState(
        icon: Icons.cloud_off_rounded,
        title: _isSi ? 'ප්‍රගති දත්ත ලබාගත නොහැක' : 'Could not load progress',
        subtitle: _isSi
            ? 'අන්තර්ජාලය පරීක්ෂා කර නැවත උත්සාහ කරන්න.'
            : 'Check the connection and try again.',
        retry: true,
      );
    }
    if (_sessions == null ||
        _quizzes == null ||
        _taskAttempts == null ||
        _dailyLogs == null ||
        _coachingRecord == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final sessions = _sessions!;
    final quizzes = _quizzes!;
    final taskAttempts = _taskAttempts!;
    final dailyLogs = _dailyLogs!;
    final taskAnalytics = ProgressAnalytics.fromAttempts(
      taskAttempts,
      grade: widget.student.gradeLevel,
    );
    final correct = quizzes.fold<int>(0, (sum, item) => sum + item.score);
    final questions = quizzes.fold<int>(0, (sum, item) => sum + item.total);
    final comprehension = questions == 0 ? null : correct / questions * 100;
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    final lastActive = _lastActive(sessions, quizzes, taskAttempts, dailyLogs);
    final practiceAccuracy = taskAnalytics.totalAnswers == 0
        ? null
        : taskAnalytics.practiceAccuracy;
    final activeDays = _recentLogs(
      dailyLogs,
    ).where((log) => log.hasLearningActivity).length;
    final coachingReport = StudentCoachingService.build(
      grade: widget.student.gradeLevel,
      taskAttempts: taskAttempts,
      readingSessions: sessions,
      quizAttempts: quizzes,
      dailyLogs: dailyLogs,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _studentHeader(lastActive),
          const SizedBox(height: 18),
          _sectionTitle(_isSi ? 'ප්‍රගති සාරාංශය' : 'Progress summary'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.38,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _metric(
                '📚',
                '${sessions.length}',
                _isSi ? 'කියවූ කතා' : 'Stories read',
                AppColors.blue,
              ),
              _metric(
                '🧠',
                comprehension == null ? '—' : '${comprehension.round()}%',
                _isSi ? 'අවබෝධය' : 'Comprehension',
                AppColors.teal,
              ),
              _metric(
                '⏱️',
                _durationLabel(totalSeconds),
                _isSi ? 'කියවූ කාලය' : 'Reading time',
                AppColors.coral,
              ),
              _metric(
                '📅',
                '$activeDays/7',
                _isSi ? 'සක්‍රීය දින' : 'Active days',
                AppColors.primary,
              ),
              _metric(
                '🎯',
                practiceAccuracy == null ? '—' : '${practiceAccuracy.round()}%',
                _isSi ? 'පුහුණු නිවැරදිතාව' : 'Practice accuracy',
                AppColors.success,
              ),
              _metric(
                '✅',
                '${taskAttempts.length}',
                _isSi ? 'සම්පූර්ණ කළ කාර්ය' : 'Tasks completed',
                AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _dailyActivityPanel(dailyLogs, activeDays),
          const SizedBox(height: 20),
          TeacherCoachingPanel(
            studentId: widget.student.id,
            isSinhala: _isSi,
            report: coachingReport,
            initialRecord: _coachingRecord!,
          ),
          const SizedBox(height: 20),
          _sectionTitle(_isSi ? 'කුසලතා විශ්ලේෂණය' : 'Skill analysis'),
          const SizedBox(height: 10),
          if (taskAnalytics.skills.isEmpty)
            _emptyCard(
              _isSi
                  ? 'දරුවා task එකක් සම්පූර්ණ කළ පසු කුසලතා පෙන්වයි.'
                  : 'Skills appear after the child completes a learning task.',
            )
          else
            ...taskAnalytics.skills.map(_skillCard),
          const SizedBox(height: 12),
          _sectionTitle(
            _isSi ? 'මෑත පුහුණු කාර්යයන්' : 'Recent practice tasks',
          ),
          const SizedBox(height: 10),
          if (taskAttempts.isEmpty)
            _emptyCard(
              _isSi
                  ? 'තවම sync කළ පුහුණු කාර්යයන් නැත.'
                  : 'No synced practice tasks yet.',
            )
          else
            ...taskAttempts.take(12).map(_taskCard),
          const SizedBox(height: 20),
          _sectionTitle(_isSi ? 'කියවීමේ ඉතිහාසය' : 'Reading history'),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            _emptyCard(
              _isSi ? 'තවම සම්පූර්ණ කළ කතා නැත.' : 'No completed stories yet.',
            )
          else
            ...sessions.take(8).map(_readingCard),
          const SizedBox(height: 12),
          _sectionTitle(_isSi ? 'ප්‍රශ්නාවලි ප්‍රතිඵල' : 'Quiz results'),
          const SizedBox(height: 10),
          if (quizzes.isEmpty)
            _emptyCard(
              _isSi
                  ? 'තවම සම්පූර්ණ කළ ප්‍රශ්නාවලි නැත.'
                  : 'No completed quizzes yet.',
            )
          else
            ...quizzes.take(8).map(_quizCard),
        ],
      ),
    );
  }

  Widget _studentHeader(DateTime? lastActive) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: AppColors.gradientPrimary,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white,
          child: Text(
            widget.student.avatar,
            style: const TextStyle(fontSize: 30),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.student.name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isSi
                    ? '${widget.student.gradeLevel} ශ්‍රේණිය'
                    : 'Grade ${widget.student.gradeLevel}',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                lastActive == null
                    ? (_isSi ? 'තවම ක්‍රියාකාරකම් නැත' : 'No activity yet')
                    : '${_isSi ? 'අවසන් ක්‍රියාකාරකම' : 'Last active'}: ${DateFormat('d MMM yyyy').format(lastActive)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _metric(String emoji, String value, String label, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _dailyActivityPanel(List<DailyActivityLog> logs, int activeDays) {
    final byDate = {for (final log in logs) log.dateKey: log};
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index)),
    );
    final openedOnly = _recentLogs(
      logs,
    ).where((log) => log.wasOpened && !log.hasLearningActivity).length;
    final noRecord = 7 - activeDays - openedOnly;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isSi ? 'පසුගිය දින 7 භාවිතය' : 'Last 7 days',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$activeDays/7',
                style: GoogleFonts.poppins(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: days.map((day) {
              final log = byDate[_dailyActivity.dateKey(day)];
              final color = log?.hasLearningActivity == true
                  ? AppColors.success
                  : log?.wasOpened == true
                  ? AppColors.warning
                  : AppColors.surfaceMuted;
              final foreground = log == null
                  ? AppColors.textSecondary
                  : Colors.white;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: foreground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: foreground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 12,
            runSpacing: 7,
            children: [
              _legendDot(
                AppColors.success,
                _isSi ? 'වැඩ කළ දින $activeDays' : 'Active $activeDays',
              ),
              _legendDot(
                AppColors.warning,
                _isSi ? 'විවෘත කළ පමණි $openedOnly' : 'Opened only $openedOnly',
              ),
              _legendDot(
                AppColors.surfaceMuted,
                _isSi ? 'වාර්තා නැත $noRecord' : 'No record $noRecord',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isSi
                ? 'අළු පැහැය යෙදුම භාවිතා නොකළ බව හෝ offline sync නොවූ බව අදහස් කළ හැකිය.'
                : 'No record can mean the app was not used or an offline event has not synced yet.',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(text, style: GoogleFonts.poppins(fontSize: 10.5)),
    ],
  );

  Widget _skillCard(SkillProgress skill) {
    final value = skill.displayAccuracy.clamp(0, 100).toDouble();
    final color = value >= 80
        ? AppColors.success
        : value >= 60
        ? AppColors.warning
        : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(skill.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isSi ? skill.titleSi : skill.titleEn,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${value.round()}%',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isSi
                  ? 'වාර ${skill.rounds} • නිවැරදි ${skill.correct}/${skill.total}'
                  : '${skill.rounds} rounds • ${skill.correct}/${skill.total} correct',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(TaskAttempt attempt) {
    final labels = taskTypeLabels[attempt.taskType];
    final similarities = attempt.items
        .map((item) => item.shapeSimilarity)
        .whereType<double>()
        .toList();
    final shape = similarities.isEmpty
        ? null
        : similarities.reduce((a, b) => a + b) / similarities.length * 100;
    final itemNames = attempt.items
        .map((item) => item.itemId)
        .where((item) => item.isNotEmpty)
        .take(4)
        .join(', ');
    return _historyCard(
      emoji: labels?[2] ?? '🎯',
      title: _isSi
          ? (labels?[1] ?? attempt.taskType)
          : (labels?[0] ?? attempt.taskType),
      detail:
          '${attempt.score}/${attempt.total} ${_isSi ? 'නිවැරදි' : 'correct'} • '
          '${shape == null ? '${attempt.percentage.round()}%' : '${shape.round()}% ${_isSi ? 'හැඩ ගැලපීම' : 'shape'}'}'
          '${itemNames.isEmpty ? '' : ' • $itemNames'}',
      date: attempt.completedAt,
      color: AppColors.primary,
    );
  }

  Widget _readingCard(ReadingSession session) => _historyCard(
    emoji: '📖',
    title: _isSi
        ? (session.titleSi.isEmpty ? 'කතා කියවීම' : session.titleSi)
        : (session.titleEn.isEmpty ? 'Story reading' : session.titleEn),
    detail: session.durationSeconds > 0
        ? '${_isSi ? 'සම්පූර්ණයි' : 'Completed'} • ${_durationLabel(session.durationSeconds)}'
        : (_isSi ? 'සම්පූර්ණ කළ කියවීම' : 'Completed reading'),
    date: session.endTime ?? session.startTime,
    color: AppColors.blue,
  );

  Widget _quizCard(QuizAttempt quiz) => _historyCard(
    emoji: '🧠',
    title: _isSi ? 'කියවීමේ ප්‍රශ්නාවලිය' : 'Reading quiz',
    detail:
        '${quiz.score}/${quiz.total} ${_isSi ? 'නිවැරදි' : 'correct'} • ${quiz.percentage.round()}%',
    date: quiz.completedAt,
    color: AppColors.teal,
  );

  Widget _historyCard({
    required String emoji,
    required String title,
    required String detail,
    required DateTime date,
    required Color color,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              Text(
                detail,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          DateFormat('d MMM').format(date),
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _emptyCard(String text) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(color: AppColors.textSecondary),
    ),
  );

  Widget _messageState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool retry,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.danger),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
          if (retry) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_isSi ? 'නැවත උත්සාහ කරන්න' : 'Try again'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
  );

  DateTime? _lastActive(
    List<ReadingSession> sessions,
    List<QuizAttempt> quizzes,
    List<TaskAttempt> taskAttempts,
    List<DailyActivityLog> dailyLogs,
  ) {
    final dates = <DateTime>[
      ...sessions.map((item) => item.endTime ?? item.startTime),
      ...quizzes.map((item) => item.completedAt),
      ...taskAttempts.map((item) => item.completedAt),
      ...dailyLogs.map((item) => item.lastActiveAt).whereType<DateTime>(),
    ]..sort((a, b) => b.compareTo(a));
    return dates.isEmpty ? null : dates.first;
  }

  List<DailyActivityLog> _recentLogs(List<DailyActivityLog> logs) {
    final today = DateTime.now();
    final keys = List.generate(
      7,
      (index) => _dailyActivity.dateKey(
        DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: index)),
      ),
    ).toSet();
    return logs.where((log) => keys.contains(log.dateKey)).toList();
  }

  String _durationLabel(int seconds) {
    if (seconds < 60) return seconds == 0 ? '0 min' : '<1 min';
    return '${seconds ~/ 60} min';
  }
}
