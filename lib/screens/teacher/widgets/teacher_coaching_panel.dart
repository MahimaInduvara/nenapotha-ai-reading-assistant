import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/student_coaching_record_service.dart';
import '../../../services/student_coaching_service.dart';
import '../../../utils/app_colors.dart';

class TeacherCoachingPanel extends StatefulWidget {
  final String studentId;
  final bool isSinhala;
  final StudentCoachingReport report;
  final StudentCoachingRecord initialRecord;

  const TeacherCoachingPanel({
    super.key,
    required this.studentId,
    required this.isSinhala,
    required this.report,
    required this.initialRecord,
  });

  @override
  State<TeacherCoachingPanel> createState() => _TeacherCoachingPanelState();
}

class _TeacherCoachingPanelState extends State<TeacherCoachingPanel> {
  final _records = StudentCoachingRecordService();
  late StudentCoachingRecord _record;
  bool _saving = false;

  bool get _isSi => widget.isSinhala;

  @override
  void initState() {
    super.initState();
    _record = widget.initialRecord;
  }

  @override
  void didUpdateWidget(covariant TeacherCoachingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecord.updatedAt != widget.initialRecord.updatedAt ||
        oldWidget.studentId != widget.studentId) {
      _record = widget.initialRecord;
    }
  }

  TextStyle _font({
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) =>
      (_isSi ? GoogleFonts.notoSansSinhala() : GoogleFonts.poppins()).copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSi ? '🎓 පුද්ගලික පුහුණු මඟ' : '🎓 Personal coaching plan',
                style: _font(size: 18, weight: FontWeight.w800),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F9F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _isSi ? 'දත්ත මත' : 'Evidence-based',
                style: _font(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        _statusCard(report),
        const SizedBox(height: 10),
        _nextActivityCard(report),
        if (report.mistakes.isNotEmpty) ...[
          const SizedBox(height: 10),
          _mistakesCard(report),
        ],
        if (report.mastery.isNotEmpty) ...[
          const SizedBox(height: 10),
          _masteryCard(report),
        ],
        const SizedBox(height: 10),
        _weeklyPlanCard(report),
        const SizedBox(height: 10),
        _parentGuidanceCard(report),
        if (report.achievements.isNotEmpty) ...[
          const SizedBox(height: 10),
          _achievementCard(report),
        ],
        const SizedBox(height: 10),
        _teacherRecordCard(report),
      ],
    );
  }

  Widget _statusCard(StudentCoachingReport report) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF5B4CF0), Color(0xFF8B5CF6)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: _statusValue(
            '📈',
            _isSi ? 'ප්‍රගති දිශාව' : 'Progress trend',
            _trendLabel(report.trend),
          ),
        ),
        Container(width: 1, height: 48, color: Colors.white24),
        Expanded(
          child: _statusValue(
            '📅',
            _isSi ? 'පුහුණු පුරුද්ද' : 'Practice routine',
            report.consistency.forLanguage(_isSi),
          ),
        ),
      ],
    ),
  );

  Widget _statusValue(String emoji, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$emoji $label', style: _font(size: 9.5, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _font(size: 12, weight: FontWeight.w800, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _nextActivityCard(StudentCoachingReport report) => _outlinedCard(
    color: AppColors.coral,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBubble('🚀', AppColors.coral),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSi ? 'ඊළඟ හොඳම කාර්යය' : 'Next best activity',
                style: _font(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                report.nextActivity.forLanguage(_isSi),
                style: _font(size: 14, weight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                report.nextActivityReason.forLanguage(_isSi),
                style: _font(
                  size: 10.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mistakesCard(StudentCoachingReport report) => _outlinedCard(
    color: AppColors.danger,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeading(
          '🔎',
          _isSi ? 'නිතර වැරදෙන අයිතම' : 'Repeated mistake patterns',
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: report.mistakes
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${item.itemId} • ${item.mistakes}/${item.attempts} ${_isSi ? 'වැරදි' : 'missed'}',
                    style: _font(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _masteryCard(StudentCoachingReport report) => _outlinedCard(
    color: AppColors.teal,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeading('🌱', _isSi ? 'කුසලතා මට්ටම්' : 'Skill mastery levels'),
        const SizedBox(height: 10),
        ...report.mastery.take(5).map((item) {
          final color = _masteryColor(item.level);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(item.skill.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSi ? item.skill.titleSi : item.skill.titleEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _font(size: 11.5, weight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_masteryLabel(item.level)} • ${item.skill.displayAccuracy.round()}%',
                    style: _font(
                      size: 9.5,
                      weight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );

  Widget _weeklyPlanCard(StudentCoachingReport report) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 13),
        leading: _iconBubble('🗓️', AppColors.primary),
        title: Text(
          _isSi ? 'දින 5 පුහුණු සැලැස්ම' : 'Five-day coaching plan',
          style: _font(size: 13, weight: FontWeight.w800),
        ),
        subtitle: Text(
          _isSi ? 'දිනකට මිනිත්තු 5–8' : '5–8 minutes per day',
          style: _font(size: 9.5, color: AppColors.textSecondary),
        ),
        children: report.weeklyPlan.map(_planDay).toList(),
      ),
    ),
  );

  Widget _planDay(CoachingDay day) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(day.emoji, style: const TextStyle(fontSize: 19)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_isSi ? 'දිනය' : 'Day'} ${day.day} • ${day.title.forLanguage(_isSi)} • ${day.minutes} min',
                style: _font(size: 11, weight: FontWeight.w800),
              ),
              Text(
                day.instruction.forLanguage(_isSi),
                style: _font(
                  size: 10,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _parentGuidanceCard(StudentCoachingReport report) => _outlinedCard(
    color: AppColors.blue,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBubble('🏠', AppColors.blue),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSi ? 'නිවසේ උපකාරය' : 'Guidance for home',
                style: _font(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.parentGuidance.forLanguage(_isSi),
                style: _font(size: 10.5, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _achievementCard(StudentCoachingReport report) => _outlinedCard(
    color: AppColors.sunshine,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeading('🏅', _isSi ? 'ලැබූ ජයග්‍රහණ' : 'Positive achievements'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: report.achievements
              .map(
                (item) => Chip(
                  avatar: const Text('⭐'),
                  label: Text(
                    item.forLanguage(_isSi),
                    style: _font(size: 10, weight: FontWeight.w700),
                  ),
                  backgroundColor: AppColors.sunshine.withValues(alpha: 0.15),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _teacherRecordCard(StudentCoachingReport report) {
    final goal = _record.weeklyGoal.isEmpty
        ? report.suggestedGoal.forLanguage(_isSi)
        : _record.weeklyGoal;
    return _outlinedCard(
      color: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeading(
                  '📝',
                  _isSi ? 'ගුරු ඉලක්කය සහ සටහන' : 'Teacher goal and note',
                ),
              ),
              IconButton.filledTonal(
                onPressed: _saving ? null : () => _editRecord(report),
                tooltip: _isSi ? 'සංස්කරණය කරන්න' : 'Edit coaching record',
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isSi ? 'මෙම සතියේ ඉලක්කය' : 'This week’s goal',
            style: _font(
              size: 9.5,
              weight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
          Text(goal, style: _font(size: 11.5, height: 1.4)),
          const SizedBox(height: 7),
          Text(
            '${_isSi ? 'ඉලක්කගත ක්‍රියාකාරකම්' : 'Target activities'}: ${_record.targetActivitiesPerWeek}/week',
            style: _font(size: 10, color: AppColors.textSecondary),
          ),
          if (_record.teacherNote.isNotEmpty) ...[
            const Divider(height: 19),
            Text(
              _isSi ? 'ගුරු සටහන' : 'Teacher note',
              style: _font(size: 9.5, weight: FontWeight.w700),
            ),
            Text(
              _record.teacherNote,
              style: _font(
                size: 10.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editRecord(StudentCoachingReport report) async {
    final draft = await showDialog<_CoachingDraft>(
      context: context,
      builder: (_) => _CoachingEditorDialog(
        isSinhala: _isSi,
        initialGoal: _record.weeklyGoal.isEmpty
            ? report.suggestedGoal.forLanguage(_isSi)
            : _record.weeklyGoal,
        initialNote: _record.teacherNote,
        initialTarget: _record.targetActivitiesPerWeek,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final saved = await _records.saveRecord(
        studentId: widget.studentId,
        weeklyGoal: draft.goal,
        teacherNote: draft.note,
        targetActivitiesPerWeek: draft.target,
      );
      if (!mounted) return;
      setState(() => _record = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSi ? 'පුහුණු ඉලක්කය සුරැකිණි.' : 'Coaching goal saved.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSi
                ? 'සුරැකීමට නොහැකි විය. අන්තර්ජාලය පරීක්ෂා කරන්න.'
                : 'Could not save. Check the connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _outlinedCard({required Color color, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      );

  Widget _iconBubble(String emoji, Color color) => Container(
    width: 43,
    height: 43,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(emoji, style: const TextStyle(fontSize: 21)),
  );

  Widget _cardHeading(String emoji, String title) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(title, style: _font(size: 13, weight: FontWeight.w800)),
      ),
    ],
  );

  String _trendLabel(CoachingTrend trend) => switch (trend) {
    CoachingTrend.newLearner =>
      _isSi ? 'නව දත්ත එකතු වෙයි' : 'Collecting evidence',
    CoachingTrend.improving => _isSi ? 'දියුණු වෙමින්' : 'Improving',
    CoachingTrend.steady => _isSi ? 'ස්ථාවරයි' : 'Steady',
    CoachingTrend.needsSupport =>
      _isSi ? 'අමතර සහාය අවශ්‍යයි' : 'Needs support',
  };

  String _masteryLabel(SkillMasteryLevel level) => switch (level) {
    SkillMasteryLevel.starting => _isSi ? 'ආරම්භක' : 'Starting',
    SkillMasteryLevel.practising => _isSi ? 'පුහුණු වෙයි' : 'Practising',
    SkillMasteryLevel.improving => _isSi ? 'දියුණු වෙයි' : 'Improving',
    SkillMasteryLevel.mastered => _isSi ? 'ප්‍රගුණයි' : 'Mastered',
  };

  Color _masteryColor(SkillMasteryLevel level) => switch (level) {
    SkillMasteryLevel.starting => AppColors.danger,
    SkillMasteryLevel.practising => AppColors.warning,
    SkillMasteryLevel.improving => AppColors.blue,
    SkillMasteryLevel.mastered => AppColors.success,
  };
}

class _CoachingDraft {
  final String goal;
  final String note;
  final int target;

  const _CoachingDraft(this.goal, this.note, this.target);
}

class _CoachingEditorDialog extends StatefulWidget {
  final bool isSinhala;
  final String initialGoal;
  final String initialNote;
  final int initialTarget;

  const _CoachingEditorDialog({
    required this.isSinhala,
    required this.initialGoal,
    required this.initialNote,
    required this.initialTarget,
  });

  @override
  State<_CoachingEditorDialog> createState() => _CoachingEditorDialogState();
}

class _CoachingEditorDialogState extends State<_CoachingEditorDialog> {
  late final TextEditingController _goalController;
  late final TextEditingController _noteController;
  late int _target;

  bool get _isSi => widget.isSinhala;

  TextStyle _font({double? size, FontWeight? weight}) =>
      (_isSi ? GoogleFonts.notoSansSinhala() : GoogleFonts.poppins()).copyWith(
        fontSize: size,
        fontWeight: weight,
      );

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.initialGoal);
    _noteController = TextEditingController(text: widget.initialNote);
    _target = widget.initialTarget;
  }

  @override
  void dispose() {
    _goalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    title: Text(
      _isSi ? 'පුහුණු ඉලක්කය සකසන්න' : 'Set coaching goal',
      style: _font(size: 17, weight: FontWeight.w800),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _goalController,
            maxLength: 240,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: _isSi ? 'සති ඉලක්කය' : 'Weekly goal',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _isSi ? 'ගුරු සටහන' : 'Teacher note',
              hintText: _isSi
                  ? 'පන්තියේ නිරීක්ෂණයක් ලියන්න'
                  : 'Add a classroom observation',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_isSi ? 'සතියේ ඉලක්කගත ක්‍රියාකාරකම්' : 'Target activities per week'}: $_target',
            style: _font(size: 11.5, weight: FontWeight.w700),
          ),
          Slider(
            value: _target.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_target',
            onChanged: (value) => setState(() => _target = value.round()),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(_isSi ? 'අවලංගු කරන්න' : 'Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _CoachingDraft(_goalController.text, _noteController.text, _target),
        ),
        child: Text(_isSi ? 'සුරකින්න' : 'Save'),
      ),
    ],
  );
}
