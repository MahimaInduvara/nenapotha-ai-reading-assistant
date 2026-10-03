import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/student_progress.dart';
import '../../models/task_attempt.dart';
import '../../services/activity_service.dart';
import '../../services/progress_analytics_service.dart';
import '../../services/progress_insight_engine.dart';
import '../../services/storage_service.dart';
import '../../services/task_progress_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/readbuddy_background.dart';

class ProgressScreen extends StatefulWidget {
  final String selectedLanguage;
  final String studentName;
  final int gradeLevel;
  final ValueChanged<int>? onNavigate;

  const ProgressScreen({
    super.key,
    required this.selectedLanguage,
    required this.studentName,
    required this.gradeLevel,
    this.onNavigate,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _primary = AppColors.blue;
  static const _purple = Color(0xFF7258F6);
  static const _green = Color(0xFF35B86B);
  static const _orange = Color(0xFFFF8A4C);

  final _activityService = ActivityService();
  final _taskProgressService = TaskProgressService();

  late StudentProgress _progress;
  ProgressAnalytics _analytics = const ProgressAnalytics.empty();
  List<ActivityFeedItem> _activityFeed = const [];
  late WeeklyInsight _localInsight;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _reloadRequested = false;
  String? _syncWarning;

  bool get _isSinhala => widget.selectedLanguage == 'sinhala';
  @override
  void initState() {
    super.initState();
    _progress = StudentProgress.empty(
      studentId: StorageService().getStudentId() ?? '',
      studentName: widget.studentName,
      gradeLevel: widget.gradeLevel,
    );
    _localInsight = ProgressInsightEngine.generate(const []);
    _taskProgressService.addListener(_onProgressChanged);
    _activityService.addListener(_onProgressChanged);
    _loadProgress(showLoader: true);
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradeLevel != widget.gradeLevel) {
      _loadProgress(showLoader: true);
    }
  }

  @override
  void dispose() {
    _taskProgressService.removeListener(_onProgressChanged);
    _activityService.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (_isRefreshing) {
      _reloadRequested = true;
      return;
    }
    _loadProgress(showLoader: false);
  }

  Future<void> _loadProgress({required bool showLoader}) async {
    if (_isRefreshing) {
      _reloadRequested = true;
      return;
    }
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        if (showLoader) _isLoading = true;
      });
    }

    var progress = StudentProgress.empty(
      studentId: StorageService().getStudentId() ?? '',
      studentName: widget.studentName,
      gradeLevel: widget.gradeLevel,
    );
    var activity = <ActivityFeedItem>[];
    var attempts = <TaskAttempt>[];
    String? warning;

    try {
      attempts = await _taskProgressService.getAttempts();
      activity = attempts.map(_taskFeedItem).toList();
    } catch (_) {
      warning = _isSinhala
          ? 'පුහුණු දත්ත මේ මොහොතේ කියවිය නොහැක.'
          : 'Practice data could not be read right now.';
    }

    final studentId = StorageService().getStudentId();
    if (studentId != null) {
      try {
        final results = await Future.wait([
          _activityService.computeProgress(
            studentId: studentId,
            studentName: widget.studentName,
            gradeLevel: widget.gradeLevel,
          ),
          _activityService.getActivityFeed(studentId),
        ]);
        progress = results[0] as StudentProgress;
        activity = results[1] as List<ActivityFeedItem>;
      } catch (_) {
        warning = _isSinhala
            ? 'කියවීම් සහ ප්‍රශ්නාවලි cloud දත්ත sync නොවීය. උපාංගයේ පුහුණු ප්‍රගතිය පෙන්වයි.'
            : 'Reading and quiz data could not sync. On-device practice progress is still shown.';
      }
    }

    if (!mounted) return;
    final reloadAfterThis = _reloadRequested;
    setState(() {
      _progress = progress;
      _analytics = ProgressAnalytics.fromAttempts(attempts);
      _activityFeed = activity;
      _localInsight = ProgressInsightEngine.generate(attempts);
      _syncWarning = warning;
      _isLoading = false;
      _isRefreshing = false;
      _reloadRequested = false;
    });
    if (reloadAfterThis) {
      Future.microtask(() => _loadProgress(showLoader: false));
    }
  }

  ActivityFeedItem _taskFeedItem(TaskAttempt attempt) {
    final labels = taskTypeLabels[attempt.taskType];
    final shapeValues = attempt.items
        .map((item) => item.shapeSimilarity)
        .whereType<double>()
        .toList(growable: false);
    final traceMatch =
        attempt.taskType == 'letter_tracing' && shapeValues.isNotEmpty
        ? shapeValues.reduce((a, b) => a + b) / shapeValues.length * 100
        : null;
    return ActivityFeedItem(
      taskType: attempt.taskType,
      titleEn: labels?[0] ?? attempt.taskType,
      titleSi: labels?[1] ?? attempt.taskType,
      emoji: labels?[2] ?? '🎯',
      subtitleEn: traceMatch == null
          ? '${attempt.score}/${attempt.total} correct'
          : '${traceMatch.round()}% latest shape match',
      subtitleSi: traceMatch == null
          ? 'නිවැරදි ${attempt.score}/${attempt.total}'
          : 'අලුත්ම හැඩ ගැළපීම ${traceMatch.round()}%',
      percentage: traceMatch ?? attempt.percentage,
      completedAt: attempt.completedAt,
      gradeLevel: attempt.grade,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isSinhala ? 'මගේ ප්‍රගතිය' : 'My Progress',
          style: _headingStyle(fontSize: 21, color: Colors.white),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _isSinhala ? 'නැවුම් කරන්න' : 'Refresh progress',
            onPressed: _isRefreshing
                ? null
                : () => _loadProgress(showLoader: false),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ReadBuddyBackground(
        accent: AppColors.blue,
        secondaryAccent: AppColors.success,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadProgress(showLoader: false),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _buildHeader(),
                    if (_syncWarning != null) ...[
                      const SizedBox(height: 12),
                      _buildSyncWarning(),
                    ],
                    const SizedBox(height: 16),
                    _buildAiCoach(),
                    const SizedBox(height: 24),
                    _sectionTitle(
                      _isSinhala ? 'මගේ ඉගෙනීම' : 'My learning',
                      _isSinhala
                          ? 'මම මෙතෙක් කළ දේ'
                          : 'What I have done so far',
                    ),
                    const SizedBox(height: 12),
                    _buildOverviewGrid(),
                    const SizedBox(height: 12),
                    _buildDetailPanel(
                      emoji: '🎯',
                      title: _isSinhala
                          ? 'පුහුණු කළ යුතු දේ'
                          : 'What to practise',
                      subtitle: _isSinhala
                          ? 'කුසලතා ප්‍රතිඵල බලන්න'
                          : 'Open the skill results',
                      color: _orange,
                      child: _buildSkillBreakdown(),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailPanel(
                      emoji: '🕘',
                      title: _isSinhala ? 'මෑත වැඩ' : 'Recent work',
                      subtitle: _isSinhala
                          ? 'කළ වැඩ ලැයිස්තුව බලන්න'
                          : 'Open the activity list',
                      color: _primary,
                      child: _buildActivityFeed(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailPanel({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          leading: Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(title, style: _headingStyle(fontSize: 14.5)),
          subtitle: Text(
            subtitle,
            style: _bodyStyle(fontSize: 9.5, color: AppColors.textSecondary),
          ),
          iconColor: color,
          collapsedIconColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('📈', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _headingStyle(fontSize: 21, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  _isSinhala
                      ? '${widget.gradeLevel} ශ්‍රේණිය • මෙම සතියේ ක්‍රියාකාරී දින ${_progress.daysActiveThisWeek}'
                      : 'Grade ${widget.gradeLevel} • ${_progress.daysActiveThisWeek} active days this week',
                  style: _bodyStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC56E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: _orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _syncWarning!,
              style: _bodyStyle(fontSize: 11.5, color: Colors.brown[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCoach() {
    final latestTrace = _analytics.latestTraceSimilarity;
    final latestTracePercent = latestTrace == null
        ? null
        : (latestTrace * 100).round();
    final message = latestTracePercent == null
        ? (_isSinhala ? _localInsight.messageSi : _localInsight.messageEn)
        : (_isSinhala
              ? 'ඔබේ අලුත්ම “${_analytics.latestTraceLetter ?? ''}” අකුරු හැඩ ගැළපීම $latestTracePercent%යි — ඉතා හොඳ දියුණුවක්! පැරණි උත්සාහ ඉතිහාසය ලෙස තබාගෙන, මේ ප්‍රතිඵලය ස්ථිර කරගැනීමට තවත් වාර කිහිපයක් පුහුණු වෙමු.'
              : 'Your latest “${_analytics.latestTraceLetter ?? ''}” letter-shape match is $latestTracePercent% — excellent improvement! Older attempts remain as history, so practise a few more rounds to build a reliable trend.');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.09),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ReadBuddyLogo(size: 44),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSinhala ? 'පුහුණු මඟ උපදෙස' : 'Learning Coach tip',
                      style: _headingStyle(fontSize: 17, color: _purple),
                    ),
                    Text(
                      _isSinhala
                          ? 'උපාංගයේ සුරැකුණු පුහුණු දත්ත අනුව'
                          : 'Based on practice saved on this device',
                      style: _bodyStyle(fontSize: 10.5, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(message, style: _bodyStyle(fontSize: 13, height: 1.55)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavigate?.call(2),
                  icon: const Icon(Icons.route_rounded, size: 18),
                  label: Text(_isSinhala ? 'මගේ සැලැස්ම' : 'View my plan'),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => widget.onNavigate?.call(1),
                style: FilledButton.styleFrom(backgroundColor: _purple),
                child: Text(_isSinhala ? 'පුහුණු වෙමු' : 'Practice now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _headingStyle(fontSize: 19)),
        const SizedBox(height: 2),
        Text(subtitle, style: _bodyStyle(fontSize: 11, color: AppColors.grey)),
      ],
    );
  }

  Widget _buildOverviewGrid() {
    final latestTrace = _analytics.latestTraceSimilarity;
    final practiceValue = latestTrace != null
        ? '${(latestTrace * 100).round()}%'
        : _analytics.totalAnswers == 0
        ? '—'
        : '${_analytics.practiceAccuracy.round()}%';
    final quizValue = _progress.totalQuestionsAnswered == 0
        ? '—'
        : '${_progress.overallComprehension.round()}%';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _metricCard(
          icon: '🎯',
          color: _purple,
          value: practiceValue,
          label: latestTrace == null
              ? (_isSinhala ? 'සමස්ත පුහුණුව' : 'Overall practice')
              : (_isSinhala ? 'අලුත්ම ඇඳීම' : 'Latest tracing'),
          detail: latestTrace == null
              ? (_isSinhala
                    ? 'වාර ${_analytics.practiceRounds}'
                    : '${_analytics.practiceRounds} rounds')
              : (_isSinhala
                    ? '${_analytics.latestTraceLetter ?? ''} • සමස්ත ${_analytics.practiceAccuracy.round()}%'
                    : '${_analytics.latestTraceLetter ?? ''} • overall ${_analytics.practiceAccuracy.round()}%'),
        ),
        _metricCard(
          icon: '🧠',
          color: _orange,
          value: quizValue,
          label: _isSinhala ? 'කතා ප්‍රශ්න' : 'Story questions',
          detail: _isSinhala
              ? 'පිළිතුරු ${_progress.totalQuestionsAnswered}'
              : '${_progress.totalQuestionsAnswered} answers',
        ),
        _metricCard(
          icon: '📖',
          color: _green,
          value: '${_progress.storiesCompleted}',
          label: _isSinhala ? 'කියවූ කතා' : 'Stories read',
          detail: _isSinhala
              ? 'මිනිත්තු ${_progress.totalMinutesRead}'
              : '${_progress.totalMinutesRead} minutes',
        ),
        _metricCard(
          icon: '🔥',
          color: _primary,
          value: '${_progress.currentStreak}',
          label: _isSinhala ? 'ඉගෙනුම් දින' : 'Learning streak',
          detail: _isSinhala
              ? 'සතියේ දින ${_progress.daysActiveThisWeek}/7'
              : '${_progress.daysActiveThisWeek}/7 days active',
        ),
      ],
    );
  }

  Widget _metricCard({
    required String icon,
    required Color color,
    required String value,
    required String label,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: _headingStyle(fontSize: 20, color: color)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(fontSize: 9.5, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBreakdown() {
    if (_analytics.skills.isEmpty) {
      return _emptyCard(
        emoji: '🧩',
        message: _isSinhala
            ? 'කුසලතා ප්‍රගතිය බැලීමට ඉගෙනීමේ කාර්යයක් සම්පූර්ණ කරන්න.'
            : 'Complete a learning task to see skill progress.',
        actionLabel: _isSinhala ? 'කාර්යයක් අරඹන්න' : 'Start a task',
      );
    }

    final visibleSkills = _analytics.skills.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: visibleSkills.indexed.map((entry) {
          final index = entry.$1;
          final skill = entry.$2;
          final displayedAccuracy = skill.displayAccuracy;
          final color = _scoreColor(displayedAccuracy);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleSkills.length - 1 ? 0 : 17,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(skill.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSinhala ? skill.titleSi : skill.titleEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _bodyStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            skill.taskType == 'letter_tracing' &&
                                    skill.latestShapeSimilarity != null
                                ? (_isSinhala
                                      ? 'අලුත්ම ගැළපීම • ඉතිහාසයේ සාර්ථක ${skill.correct}/${skill.total}'
                                      : 'Latest match • history ${skill.correct}/${skill.total} passed')
                                : (_isSinhala
                                      ? '${skill.grade} ශ්‍රේණිය • වාර ${skill.rounds} • නිවැරදි ${skill.correct}/${skill.total}'
                                      : 'Grade ${skill.grade} • ${skill.rounds} rounds • ${skill.correct}/${skill.total} correct'),
                            style: _bodyStyle(
                              fontSize: 10,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${displayedAccuracy.round()}%',
                      style: _headingStyle(fontSize: 16, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: displayedAccuracy / 100,
                    minHeight: 7,
                    backgroundColor: color.withValues(alpha: 0.11),
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityFeed() {
    if (_activityFeed.isEmpty) {
      return _emptyCard(
        emoji: '📋',
        message: _isSinhala
            ? 'පළමු ක්‍රියාකාරකම සම්පූර්ණ කළ පසු එය මෙහි පෙන්වයි.'
            : 'Your first completed activity will appear here.',
        actionLabel: _isSinhala ? 'ඉගෙනීම අරඹන්න' : 'Start learning',
      );
    }

    final recent = _activityFeed.take(6).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: recent.indexed.map((entry) {
          final item = entry.$2;
          final percentage = item.percentage;
          final color = percentage == null ? _primary : _scoreColor(percentage);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSinhala ? item.titleSi : item.titleEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _bodyStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${item.gradeLevel == null ? '' : (_isSinhala ? '${item.gradeLevel} ශ්‍රේණිය • ' : 'Grade ${item.gradeLevel} • ')}${_isSinhala ? item.subtitleSi : item.subtitleEn} • ${_formatDate(item.completedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _bodyStyle(
                              fontSize: 10,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (percentage != null)
                      Text(
                        '${percentage.round()}%',
                        style: _headingStyle(fontSize: 15, color: color),
                      ),
                  ],
                ),
              ),
              if (entry.$1 != recent.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.65),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyCard({
    required String emoji,
    required String message,
    required String actionLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _bodyStyle(
              fontSize: 12,
              color: AppColors.grey,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => widget.onNavigate?.call(1),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return _isSinhala ? 'අද' : 'Today';
    if (difference == 1) return _isSinhala ? 'ඊයේ' : 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _scoreColor(double percentage) {
    if (percentage >= 80) return _green;
    if (percentage >= 60) return _orange;
    return const Color(0xFFE85C5C);
  }

  TextStyle _headingStyle({double fontSize = 18, Color? color}) {
    return (_isSinhala
            ? GoogleFonts.notoSansSinhala()
            : const TextStyle(fontFamily: 'Baloo2'))
        .copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.black,
        );
  }

  TextStyle _bodyStyle({
    double fontSize = 13,
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return (_isSinhala ? GoogleFonts.notoSansSinhala() : GoogleFonts.poppins())
        .copyWith(
          fontSize: fontSize,
          color: color ?? AppColors.black,
          fontWeight: fontWeight,
          height: height,
        );
  }
}
