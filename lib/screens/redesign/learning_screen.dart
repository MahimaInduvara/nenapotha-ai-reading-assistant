import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/task_attempt.dart';
import '../../services/learning_journey_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_progress_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bouncy_tap.dart';
import '../../widgets/readbuddy_background.dart';
import '../learning/models/grade1_level_task.dart';
import '../learning/models/grade2_level_task.dart';
import '../learning/widgets/grade1_learning_path_screen.dart';
import '../learning/widgets/grade2_learning_path_screen.dart';
import '../learning/widgets/grade_1_content.dart';
import '../learning/widgets/grade_2_content.dart';

class LearningScreen extends StatefulWidget {
  final String selectedLanguage;
  final int gradeLevel;
  final String studentName;

  const LearningScreen({
    super.key,
    required this.selectedLanguage,
    required this.gradeLevel,
    required this.studentName,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final TaskProgressService _progressService = TaskProgressService();
  final Map<int, TaskAttempt?> _best = {};
  late int _activeGrade;
  late String _learningLanguage;
  bool _journeyLoading = true;

  bool get _isSi => widget.selectedLanguage == 'sinhala';
  Color get _gradeColor => _activeGrade == 1 ? AppColors.coral : AppColors.teal;
  int get _totalLevels => _activeGrade == 1
      ? Grade1LevelDefinition.levels.length
      : Grade2LevelDefinition.levels.length;

  LearningJourneySummary get _journey => LearningJourneyService.summarize(
    List.generate(_totalLevels, (index) => _best[index + 1]?.percentage),
  );

  @override
  void initState() {
    super.initState();
    _activeGrade = StorageService().getLearningGrade(
      fallback: widget.gradeLevel,
    );
    _learningLanguage = StorageService().getLearningLanguage(
      fallback: widget.selectedLanguage,
    );
    _progressService.addListener(_handleProgressChanged);
    _loadJourney();
  }

  @override
  void didUpdateWidget(covariant LearningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLanguage != widget.selectedLanguage) {
      _loadJourney();
    }
  }

  @override
  void dispose() {
    _progressService.removeListener(_handleProgressChanged);
    super.dispose();
  }

  void _handleProgressChanged() => _loadJourney(showLoading: false);

  Future<void> _selectGrade(int grade) async {
    if (_activeGrade == grade) return;
    setState(() {
      _activeGrade = grade;
      _best.clear();
      _journeyLoading = true;
    });
    await StorageService().setLearningGrade(grade);
    await _loadJourney();
  }

  Future<void> _selectLearningLanguage(String language) async {
    if (_learningLanguage == language) return;
    setState(() {
      _learningLanguage = language;
      _best.clear();
      _journeyLoading = true;
    });
    await StorageService().setLearningLanguage(language);
    await _loadJourney();
  }

  Future<void> _loadJourney({bool showLoading = true}) async {
    final requestedGrade = _activeGrade;
    final requestedLearningLanguage = _learningLanguage;
    if (showLoading && mounted) setState(() => _journeyLoading = true);
    final definitions = requestedGrade == 1
        ? Grade1LevelDefinition.levels
              .map((level) => (level.level, level.taskType))
              .toList()
        : Grade2LevelDefinition.levels
              .map((level) => (level.level, level.taskType))
              .toList();
    final results = await Future.wait(
      definitions.map(
        (item) => _progressService.getBest(
          taskType: item.$2,
          grade: requestedGrade,
          language: requestedGrade == 1 ? requestedLearningLanguage : 'sinhala',
        ),
      ),
    );
    if (!mounted ||
        requestedGrade != _activeGrade ||
        requestedLearningLanguage != _learningLanguage) {
      return;
    }
    setState(() {
      _best
        ..clear()
        ..addEntries(
          List.generate(
            definitions.length,
            (index) => MapEntry(definitions[index].$1, results[index]),
          ),
        );
      _journeyLoading = false;
    });
  }

  String get _nextTitle {
    final level = _journey.nextLevel;
    if (_activeGrade == 1) {
      final definition = Grade1LevelDefinition.byLevel(level);
      return _isSi ? definition.titleSi : definition.titleEn;
    }
    final definition = Grade2LevelDefinition.levels[level - 1];
    return _isSi ? definition.titleSi : definition.titleEn;
  }

  String get _nextEmoji => _activeGrade == 1
      ? Grade1LevelDefinition.byLevel(_journey.nextLevel).emoji
      : Grade2LevelDefinition.levels[_journey.nextLevel - 1].emoji;

  Future<void> _openLearningPath() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _activeGrade == 1
            ? Grade1LearningPathScreen(
                selectedLanguage: widget.selectedLanguage,
                isEnglish: _learningLanguage == 'english',
              )
            : Grade2LearningPathScreen(
                selectedLanguage: widget.selectedLanguage,
              ),
      ),
    );
    await _loadJourney(showLoading: false);
  }

  TextStyle _font({double? size, FontWeight? weight, Color? color}) =>
      (_isSi ? GoogleFonts.notoSansSinhala() : GoogleFonts.poppins()).copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ReadBuddyBackground(
        accent: AppColors.teal,
        secondaryAccent: AppColors.sunshine,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: Column(
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 10),
                    _buildGradeSelector(),
                    if (_activeGrade == 1) ...[
                      const SizedBox(height: 8),
                      _buildLearningLanguageSelector(),
                    ],
                    const SizedBox(height: 10),
                    _buildMissionCard(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.94),
                        const Color(0xFFF5FFFD).withValues(alpha: 0.94),
                        const Color(0xFFFFF8F1).withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _activeGrade == 1
                        ? Grade1ContentWidget(
                            key: ValueKey(
                              'grade1-${widget.selectedLanguage}-$_learningLanguage',
                            ),
                            selectedLanguage: widget.selectedLanguage,
                            learningLanguage: _learningLanguage,
                            showHeader: false,
                          )
                        : Grade2ContentWidget(
                            key: ValueKey('grade2-${widget.selectedLanguage}'),
                            selectedLanguage: widget.selectedLanguage,
                            showHeader: false,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final firstName = widget.studentName.trim().split(' ').first;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.gradientCool,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text('📚', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSi ? 'ඉගෙනුම් ලෝකය' : 'Learning Adventure',
                style: _font(
                  size: 20,
                  weight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _isSi
                    ? '$firstName, අදත් අලුත් දෙයක් ඉගෙනගමු!'
                    : 'Hi $firstName, ready for today’s mission?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _font(size: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.sunshine.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            '⭐ ${_journey.masteredLevels}',
            style: _font(
              size: 12,
              weight: FontWeight.w800,
              color: const Color(0xFF9A6500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _gradeOption(
            grade: 1,
            icon: '⭐',
            title: _isSi ? '1 ශ්‍රේණිය' : 'Grade 1',
            subtitle: _learningLanguage == 'sinhala'
                ? (_isSi ? 'සිංහල අකුරු' : 'Sinhala Letters')
                : (_isSi ? 'ඉංග්‍රීසි අකුරු' : 'English Letters'),
            color: AppColors.coral,
          ),
          _gradeOption(
            grade: 2,
            icon: '🌟',
            title: _isSi ? '2 ශ්‍රේණිය' : 'Grade 2',
            subtitle: _isSi ? 'සිංහල කියවීම' : 'Sinhala Reading',
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningLanguageSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Text(
            _isSi ? 'අකුරු ඉගෙනගන්න:' : 'Learn letters in:',
            style: _font(
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _learningLanguageOption(
              language: 'sinhala',
              symbol: 'අ',
              label: 'සිංහල',
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _learningLanguageOption(
              language: 'english',
              symbol: 'A',
              label: 'English',
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _learningLanguageOption({
    required String language,
    required String symbol,
    required String label,
    required Color color,
  }) {
    final selected = _learningLanguage == language;
    final labelStyle = language == 'sinhala'
        ? GoogleFonts.notoSansSinhala()
        : GoogleFonts.poppins();
    return Semantics(
      button: true,
      selected: selected,
      label: language == 'sinhala'
          ? 'Learn Sinhala letters'
          : 'Learn English letters',
      child: InkWell(
        onTap: () => _selectLearningLanguage(language),
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symbol,
                style: labelStyle.copyWith(
                  color: selected ? Colors.white : color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    if (_journeyLoading) {
      return Container(
        height: 104,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _gradeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: CircularProgressIndicator(color: _gradeColor),
      );
    }
    final journey = _journey;
    final completed = journey.isComplete;
    return BouncyTap(
      onTap: _openLearningPath,
      child: Semantics(
        button: true,
        label: _isSi
            ? 'ඊළඟ ඉගෙනුම් මට්ටම විවෘත කරන්න'
            : 'Open next learning level',
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _gradeColor,
                Color.lerp(_gradeColor, AppColors.primary, 0.45)!,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _gradeColor.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  completed ? '🏆' : _nextEmoji,
                  style: const TextStyle(fontSize: 27),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed
                          ? (_isSi
                                ? 'නැවත පුහුණු වෙමු'
                                : 'Keep your skills strong')
                          : (_isSi
                                ? 'අද මෙහෙයුම • මට්ටම ${journey.nextLevel}'
                                : 'TODAY’S MISSION • LEVEL ${journey.nextLevel}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 10,
                        weight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _nextTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 15,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: journey.completion,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.sunshine,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isSi
                          ? 'මට්ටම් ${journey.masteredLevels}/${journey.totalLevels} සම්පූර්ණයි'
                          : '${journey.masteredLevels}/${journey.totalLevels} levels mastered',
                      style: _font(size: 9, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: _gradeColor,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradeOption({
    required int grade,
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final selected = _activeGrade == grade;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: '$title $subtitle',
        child: InkWell(
          onTap: () => _selectGrade(grade),
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _font(
                          size: 12,
                          weight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _font(
                          size: 9,
                          color: selected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
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
}
