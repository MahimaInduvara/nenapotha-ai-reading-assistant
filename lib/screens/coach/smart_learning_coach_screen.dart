import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task_attempt.dart';
import '../../services/smart_learning_coach_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_progress_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/readbuddy_background.dart';
import '../learning/widgets/grade1_learning_path_screen.dart';
import '../learning/widgets/grade2_learning_path_screen.dart';
import '../learning/widgets/letter_matching_task_screen.dart';
import '../learning/widgets/letter_recognition_task_screen.dart';
import '../learning/widgets/pillam_fill_task_screen.dart';
import '../learning/widgets/pillam_naming_task_screen.dart';
import '../letter_tracing_screen.dart';

class SmartLearningCoachScreen extends StatefulWidget {
  final String selectedLanguage;
  final String studentName;
  final int gradeLevel;
  final ValueChanged<int>? onNavigate;

  const SmartLearningCoachScreen({
    super.key,
    required this.selectedLanguage,
    required this.studentName,
    required this.gradeLevel,
    this.onNavigate,
  });

  @override
  State<SmartLearningCoachScreen> createState() =>
      _SmartLearningCoachScreenState();
}

class _SmartLearningCoachScreenState extends State<SmartLearningCoachScreen> {
  final _progress = TaskProgressService();
  CoachPlan? _plan;
  bool _loading = true;
  String? _error;

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  @override
  void initState() {
    super.initState();
    _progress.addListener(_handleProgressChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant SmartLearningCoachScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradeLevel != widget.gradeLevel ||
        oldWidget.selectedLanguage != widget.selectedLanguage) {
      _load();
    }
  }

  @override
  void dispose() {
    _progress.removeListener(_handleProgressChanged);
    super.dispose();
  }

  void _handleProgressChanged() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final attempts = await _progress.getAttempts(grade: widget.gradeLevel);
      final plan = SmartLearningCoachService.build(
        attempts: attempts,
        grade: widget.gradeLevel,
      );
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isSi
            ? 'පුහුණු දත්ත දැන් කියවිය නොහැක. නැවත උත්සාහ කරන්න.'
            : 'Practice data could not be read. Please try again.';
      });
    }
  }

  Future<void> _startPractice() async {
    final plan = _plan;
    if (plan == null) return;
    final learningLanguage = StorageService().getLearningLanguage(
      fallback: widget.selectedLanguage,
    );
    final isEnglish = learningLanguage == 'english';
    final Widget destination = switch (plan.focusTaskType) {
      'letter_tracing' => LetterTracingScreen(
        selectedLanguage: widget.selectedLanguage,
        useEnglishLetters: isEnglish,
        initialLetter: plan.weakItem,
      ),
      'letter_recognition' => LetterRecognitionTaskScreen(
        selectedLanguage: widget.selectedLanguage,
        isEnglish: isEnglish,
        gradeLevel: plan.grade,
      ),
      'letter_matching' => LetterMatchingTaskScreen(
        selectedLanguage: widget.selectedLanguage,
        isEnglish: isEnglish,
        gradeLevel: plan.grade,
      ),
      'pillam_fill' => PillamFillTaskScreen(
        selectedLanguage: widget.selectedLanguage,
      ),
      'pillam_naming' => PillamNamingTaskScreen(
        selectedLanguage: widget.selectedLanguage,
      ),
      _ when plan.focusTaskType.startsWith('grade1_level_') =>
        Grade1LearningPathScreen(
          selectedLanguage: widget.selectedLanguage,
          isEnglish: isEnglish,
        ),
      _ when plan.focusTaskType.startsWith('grade2_level_') =>
        Grade2LearningPathScreen(selectedLanguage: widget.selectedLanguage),
      _ => const SizedBox.shrink(),
    };

    if (destination is SizedBox) {
      widget.onNavigate?.call(1);
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => destination));
    await _load(showLoader: false);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ReadBuddyBackground(
        accent: AppColors.primary,
        secondaryAccent: AppColors.teal,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                  sliver: SliverList.list(
                    children: [
                      _header(),
                      const SizedBox(height: 18),
                      if (_loading)
                        const SizedBox(
                          height: 420,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _errorCard()
                      else ...[
                        _hero(_plan!),
                        const SizedBox(height: 18),
                        _evidence(_plan!),
                        const SizedBox(height: 20),
                        _sectionTitle(
                          _isSi ? 'අද පුහුණු සැලැස්ම' : "Today's practice plan",
                          _isSi
                              ? 'පහසු පියවර තුනක් සම්පූර්ණ කරමු'
                              : 'Complete three short steps',
                        ),
                        const SizedBox(height: 11),
                        ..._plan!.recommendedTaskTypes.asMap().entries.map(
                          (entry) => _planStep(
                            entry.key,
                            entry.value,
                            entry.key == _plan!.recommendedTaskTypes.length - 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _startButton(),
                        const SizedBox(height: 20),
                        _researchNote(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      const ReadBuddyLogo(size: 56),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSi ? 'මගේ පුහුණු මඟ' : 'My Learning Coach',
              style: _font(
                size: 21,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _isSi
                  ? 'ඔබේ ප්‍රගතියට ගැළපෙන පුහුණුව'
                  : 'Practice matched to your progress',
              style: _font(size: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F9F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _isSi ? '📱 නොමිලේ' : '📱 Free',
          style: _font(
            size: 10,
            weight: FontWeight.w700,
            color: const Color(0xFF168B60),
          ),
        ),
      ),
    ],
  );

  Widget _hero(CoachPlan plan) {
    final name = widget.studentName.trim();
    final stageText = switch (plan.stage) {
      CoachStage.starting =>
        _isSi
            ? 'අපි පළමු පුහුණුවෙන් පටන් ගමු!'
            : "Let's begin your first practice!",
      CoachStage.support =>
        _isSi
            ? 'මූලික කුසලතා ටිකක් තවත් පුහුණු කරමු.'
            : "Let's strengthen the basics together.",
      CoachStage.growing =>
        _isSi
            ? 'හොඳ ප්‍රගතියක්! දුෂ්කර කොටසට අවධානය දෙමු.'
            : 'Good progress! Now focus on the tricky part.',
      CoachStage.challenge =>
        _isSi
            ? 'විශිෂ්ටයි! ඊළඟ අභියෝගයට සූදානම්.'
            : 'Great work! You are ready for a challenge.',
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSi
                ? '${name.isEmpty ? 'පුංචි යාළුවා' : name} සඳහා අද අවධානය'
                : "${name.isEmpty ? 'Reader' : name}'s focus today",
            style: _font(
              size: 12,
              weight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(plan.focusEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  _isSi ? plan.focusTitleSi : plan.focusTitleEn,
                  style: _font(
                    size: 21,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.weakItem == null
                ? stageText
                : (_isSi
                      ? '“${plan.weakItem}” සඳහා වැඩි පුහුණුවක් අවශ්‍යයි. $stageText'
                      : '“${plan.weakItem}” needs extra practice. $stageText'),
            style: _font(size: 13, height: 1.5, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _evidence(CoachPlan plan) => Row(
    children: [
      _metric(
        '🎯',
        plan.hasEvidence ? '${plan.accuracy.round()}%' : '—',
        _isSi ? 'නිවැරදිභාවය' : 'Accuracy',
        AppColors.coral,
      ),
      const SizedBox(width: 9),
      _metric(
        '✅',
        '${plan.practiceRounds}',
        _isSi ? 'පුහුණු වාර' : 'Rounds',
        AppColors.teal,
      ),
      const SizedBox(width: 9),
      _metric(
        '📅',
        '${plan.recentRounds}',
        _isSi ? 'දින 7 තුළ' : 'Last 7 days',
        AppColors.blue,
      ),
    ],
  );

  Widget _metric(String emoji, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: .22)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                value,
                style: _font(size: 18, weight: FontWeight.w800, color: color),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: _font(size: 9.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _font(size: 19, weight: FontWeight.w800)),
      Text(subtitle, style: _font(size: 11, color: AppColors.textSecondary)),
    ],
  );

  Widget _planStep(int index, String taskType, bool isLast) {
    final labels = taskTypeLabels[taskType];
    final title = _isSi ? (labels?[1] ?? taskType) : (labels?[0] ?? taskType);
    final purpose = switch (index) {
      0 => _isSi ? 'උණුසුම් පුහුණුව' : 'Warm up',
      1 => _isSi ? 'අද ප්‍රධාන අවධානය' : "Today's focus",
      _ => _isSi ? 'අවසාන අභියෝගය' : 'Finish with a challenge',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: _font(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 46, color: AppColors.primarySoft),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${labels?[2] ?? '🎯'} $title',
                  style: _font(size: 14, weight: FontWeight.w700),
                ),
                Text(
                  purpose,
                  style: _font(size: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _startButton() => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _startPractice,
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(_isSi ? 'පුහුණුව අරඹමු' : 'Start my practice'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: _font(size: 14, weight: FontWeight.w800),
      ),
    ),
  );

  Widget _researchNote() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFD97D)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔒', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _isSi
                ? 'මෙම සැලැස්ම සකස් කරන්නේ උපාංගයේ සුරැකුණු සත්‍ය පුහුණු ප්‍රතිඵල අනුවයි. Chatbot හෝ ගෙවීම් API භාවිතා නොකරයි.'
                : 'This plan uses recorded practice results on this device. It does not use a chatbot or paid API.',
            style: _font(
              size: 10.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _errorCard() => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: _font(size: 13)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _load,
            child: Text(_isSi ? 'නැවත උත්සාහ කරන්න' : 'Try again'),
          ),
        ],
      ),
    ),
  );
}
