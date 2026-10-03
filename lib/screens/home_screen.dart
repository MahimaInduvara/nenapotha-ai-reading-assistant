import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/story.dart';
import '../models/student_progress.dart';
import '../models/task_attempt.dart';
import '../services/activity_service.dart';
import '../services/home_dashboard_service.dart';
import '../services/reading_level_engine.dart';
import '../services/storage_service.dart';
import '../services/task_progress_service.dart';
import '../utils/app_colors.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/readbuddy_background.dart';
import '../widgets/task_picture.dart';
import 'reading_screen.dart';

/// The child's daily starting point. Detailed analytics remain in Progress;
/// Home focuses on the next useful action and the main learning destinations.
class HomeScreen extends StatefulWidget {
  final String selectedLanguage;
  final String studentName;
  final int gradeLevel;
  final void Function(int)? onNavigate;

  const HomeScreen({
    super.key,
    required this.selectedLanguage,
    required this.studentName,
    required this.gradeLevel,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const cardShadow = BoxShadow(
    color: Color(0x130E1B4D),
    blurRadius: 18,
    offset: Offset(0, 7),
  );

  final ActivityService _activities = ActivityService();
  final TaskProgressService _tasks = TaskProgressService();
  late StudentProgress _progress;
  List<TaskAttempt> _attempts = const [];
  late int _learningGrade;
  late String _learningLanguage;
  bool _loading = true;
  bool _refreshing = false;

  bool get _isSi => widget.selectedLanguage == 'sinhala';
  String _copy(String en, String si) => _isSi ? si : en;
  Story? get _story {
    final stories = ReadingLevelEngine.recommendStoriesForLevel(
      widget.gradeLevel,
    );
    return stories.isEmpty ? null : stories.first;
  }

  HomeTodaySummary get _today => HomeDashboardService.summarize(
    attempts: _attempts,
    progress: _progress,
    now: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    _learningGrade = storage.getLearningGrade(fallback: widget.gradeLevel);
    _learningLanguage = storage.getLearningLanguage(
      fallback: widget.selectedLanguage,
    );
    _progress = StudentProgress.empty(
      studentId: storage.getStudentId() ?? '',
      studentName: widget.studentName,
      gradeLevel: widget.gradeLevel,
    );
    _activities.addListener(_onProgressChanged);
    _tasks.addListener(_onProgressChanged);
    _loadData();
  }

  @override
  void dispose() {
    _activities.removeListener(_onProgressChanged);
    _tasks.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() => _loadData(showLoading: false);

  Future<void> _loadData({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading && mounted) setState(() => _loading = true);

    final storage = StorageService();
    final studentId = storage.getStudentId();
    var nextProgress = _progress;
    var nextAttempts = _attempts;
    try {
      nextAttempts = await _tasks.getAttempts(grade: widget.gradeLevel);
    } catch (_) {
      // Retain the last local snapshot if preferences are unavailable.
    }
    if (studentId != null) {
      try {
        nextProgress = await _activities.computeProgress(
          studentId: studentId,
          studentName: widget.studentName,
          gradeLevel: widget.gradeLevel,
        );
      } catch (_) {
        // Home remains usable offline with its last Firestore snapshot.
      }
    }

    _learningGrade = storage.getLearningGrade(fallback: widget.gradeLevel);
    _learningLanguage = storage.getLearningLanguage(
      fallback: widget.selectedLanguage,
    );
    _refreshing = false;
    if (!mounted) return;
    setState(() {
      _progress = nextProgress;
      _attempts = nextAttempts;
      _loading = false;
    });
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

  String _date() {
    final now = DateTime.now();
    if (!_isSi) return DateFormat('EEEE, MMMM d').format(now);
    const days = [
      'සඳුදා',
      'අඟහරුවාදා',
      'බදාදා',
      'බ්‍රහස්පතින්දා',
      'සිකුරාදා',
      'සෙනසුරාදා',
      'ඉරිදා',
    ];
    const months = [
      'ජනවාරි',
      'පෙබරවාරි',
      'මාර්තු',
      'අප්‍රේල්',
      'මැයි',
      'ජූනි',
      'ජූලි',
      'අගෝස්තු',
      'සැප්තැම්බර්',
      'ඔක්තෝබර්',
      'නොවැම්බර්',
      'දෙසැම්බර්',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String get _missionTitle {
    if (_learningGrade == 2) {
      return _copy('Build words like a champion', 'දක්ෂයෙකු මෙන් වචන ගොඩනඟමු');
    }
    return _learningLanguage == 'english'
        ? _copy('Continue your ABC adventure', 'ABC අකුරු ගමන දිගටම යමු')
        : _copy(
            'Continue your Sinhala letter adventure',
            'සිංහල අකුරු ගමන දිගටම යමු',
          );
  }

  String get _missionSubtitle {
    if (_learningGrade == 2) {
      return _copy(
        'Pillam, words and reading — step by step',
        'පිල්ලම්, වචන සහ කියවීම — පියවරෙන් පියවර',
      );
    }
    return _learningLanguage == 'english'
        ? _copy(
            'Look, match and practise English letters',
            'ඉංග්‍රීසි අකුරු බලමු, අසමු, පුහුණු වෙමු',
          )
        : _copy(
            'Look, match and practise Sinhala letters',
            'සිංහල අකුරු බලමු, අසමු, පුහුණු වෙමු',
          );
  }

  String get _missionWord => _learningGrade == 2
      ? 'පොත'
      : (_learningLanguage == 'english' ? 'Apple' : 'අඹ');
  String get _missionEmoji => _learningGrade == 2
      ? '📚'
      : (_learningLanguage == 'english' ? '🍎' : '🥭');

  Future<void> _openStory(Story story) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          storyId: story.id,
          titleSi: story.titleSi,
          titleEn: story.titleEn,
          contentSi: story.contentSi,
          contentEn: story.contentEn,
          gradeLevel: story.gradeLevel,
          selectedLanguage: widget.selectedLanguage,
        ),
      ),
    );
    await _loadData(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ReadBuddyBackground(
        accent: AppColors.coral,
        secondaryAccent: AppColors.sunshine,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _loadData(showLoading: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  sliver: SliverList.list(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildMission(),
                      const SizedBox(height: 22),
                      _section(
                        _copy('Choose an activity', 'ක්‍රියාකාරකමක් තෝරමු'),
                        _copy(
                          'What would you like to do?',
                          'ඔබ දැන් කරන්න කැමති කුමක්ද?',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildChoices(),
                      const SizedBox(height: 22),
                      _section(
                        _copy('Story time', 'කතා වේලාව'),
                        _copy(
                          'A short story picked for your grade',
                          'ඔබේ ශ්‍රේණියට ගැළපෙන කෙටි කතාවක්',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStory(),
                      const SizedBox(height: 22),
                      _buildWeek(),
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

  Widget _buildHeader() {
    final name = widget.studentName.trim();
    return Row(
      children: [
        const ReadBuddyLogo(size: 54),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _copy(
                  'Hello, ${name.isEmpty ? 'Reader' : name}! 👋',
                  'ආයුබෝවන්, ${name.isEmpty ? 'පුංචි යාළුවා' : name}! 👋',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _font(
                  size: 20,
                  weight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_isSi ? 'නැණපොත AI' : 'NenaPotha AI'} · ${_date()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _font(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5D8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE29A)),
          ),
          child: Column(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              Text(
                _isSi
                    ? '${_progress.currentStreak} දින'
                    : '${_progress.currentStreak} day${_progress.currentStreak == 1 ? '' : 's'}',
                style: _font(
                  size: 10,
                  weight: FontWeight.w800,
                  color: const Color(0xFFC46A08),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMission() {
    final today = _today;
    return Container(
      key: const ValueKey('home_learning_mission'),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5948EC), Color(0xFF8865F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: TaskPicture(
                  word: _missionWord,
                  fallbackEmoji: _missionEmoji,
                  size: 72,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pill(
                      _copy("TODAY'S ADVENTURE", 'අද ඉගෙනුම් ගමන'),
                      Colors.white.withValues(alpha: .18),
                      Colors.white,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _missionTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 18,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _missionSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 11,
                        color: Colors.white.withValues(alpha: .82),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4536C8).withValues(alpha: .6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    today.hasActivity
                        ? Icons.auto_awesome_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.sunshine,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    today.hasActivity
                        ? _copy(
                            '${today.completed} ${today.completed == 1 ? 'activity' : 'activities'} completed today 🎉',
                            'අද ක්‍රියාකාරකම් ${today.completed}ක් සම්පූර්ණයි 🎉',
                          )
                        : _copy(
                            'Choose an activity when you are ready',
                            'ඔබ සූදානම් විට ක්‍රියාකාරකමක් තෝරන්න',
                          ),
                    maxLines: 2,
                    style: _font(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('home_continue_learning'),
                  onPressed: () => widget.onNavigate?.call(1),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    minimumSize: const Size(88, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _copy('Start', 'අරඹමු'),
                        style: _font(size: 12, weight: FontWeight.w800),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: _font(
          size: 18,
          weight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: _font(
          size: 11,
          weight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );

  Widget _buildChoices() {
    final story = _story;
    return Row(
      children: [
        Expanded(
          child: _choice(
            key: const ValueKey('home_activity_learn'),
            label: _copy('Learn', 'ඉගෙනීම'),
            caption: _learningGrade == 2
                ? _copy('Words', 'වචන')
                : _copy('Letters', 'අකුරු'),
            color: AppColors.coral,
            picture: TaskPicture(
              word: _missionWord,
              fallbackEmoji: _missionEmoji,
              size: 60,
              borderRadius: BorderRadius.circular(14),
            ),
            onTap: () => widget.onNavigate?.call(1),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _choice(
            key: const ValueKey('home_activity_read'),
            label: _copy('Read', 'කියවීම'),
            caption: _copy('Story', 'කතාව'),
            color: AppColors.teal,
            picture: const TaskPicture(
              word: 'කියවන්න',
              fallbackEmoji: '📖',
              size: 60,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            onTap: story == null
                ? () => widget.onNavigate?.call(1)
                : () => _openStory(story),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _choice(
            key: const ValueKey('home_activity_ai'),
            label: _copy('My Coach', 'පුහුණු මඟ'),
            caption: _copy('My plan', 'මගේ සැලැස්ම'),
            color: AppColors.blue,
            picture: const ReadBuddyLogo(size: 60),
            onTap: () => widget.onNavigate?.call(2),
          ),
        ),
      ],
    );
  }

  Widget _choice({
    required Key key,
    required String label,
    required String caption,
    required Color color,
    required Widget picture,
    required VoidCallback onTap,
  }) => BouncyTap(
    key: key,
    onTap: onTap,
    child: Semantics(
      button: true,
      label: '$label, $caption',
      child: Container(
        height: 142,
        padding: const EdgeInsets.fromLTRB(8, 11, 8, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: color.withValues(alpha: .3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .11),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            picture,
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _font(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _font(size: 10, weight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildStory() {
    final story = _story;
    if (story == null) {
      return _emptyCard(
        _copy('New stories are coming soon.', 'අලුත් කතා ඉක්මනින් එනවා.'),
      );
    }
    final minutes = (story.wordCount / 40).ceil().clamp(1, 99);
    return BouncyTap(
      onTap: () => _openStory(story),
      child: Semantics(
        button: true,
        label: _copy('Read ${story.titleEn}', '${story.titleSi} කියවන්න'),
        child: Container(
          key: const ValueKey('home_featured_story'),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF8),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFFFE1AC)),
            boxShadow: const [cardShadow],
          ),
          child: Row(
            children: [
              Container(
                width: 88,
                height: 98,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE6BE), Color(0xFFFFF6E9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  story.thumbnailUrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _pill(
                          _copy(
                            'Grade ${story.gradeLevel}',
                            '${story.gradeLevel} ශ්‍රේණිය',
                          ),
                          const Color(0xFFEAE8FF),
                          AppColors.primaryDark,
                        ),
                        _pill(
                          _copy('$minutes min', 'මිනිත්තු $minutes'),
                          const Color(0xFFE4F8F4),
                          AppColors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _isSi ? story.titleSi : story.titleEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 17,
                        weight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          _copy('Read now', 'දැන් කියවමු'),
                          style: _font(
                            size: 11,
                            weight: FontWeight.w800,
                            color: AppColors.coral,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.coral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeek() => Container(
    key: const ValueKey('home_weekly_snapshot'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F8FF),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFDCEEFF)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text('🌈', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _copy('Your week', 'ඔබේ සතිය'),
                    style: _font(
                      size: 17,
                      weight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _loading
                        ? _copy(
                            'Updating progress…',
                            'ප්‍රගතිය යාවත්කාලීන කරමින්…',
                          )
                        : _copy('See what you completed', 'ඔබ කළ දේ බලමු'),
                    style: _font(
                      size: 10,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('home_view_progress'),
              onPressed: () => widget.onNavigate?.call(3),
              child: Text(
                _copy('View', 'බලන්න'),
                style: _font(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            _stat(
              '📅',
              '${_progress.daysActiveThisWeek}/7',
              _copy('active days', 'සක්‍රිය දින'),
            ),
            _divider(),
            _stat(
              '📖',
              '${_progress.totalStoriesAllTime}',
              _copy('stories', 'කතා'),
            ),
            _divider(),
            _stat(
              '🎯',
              '${_attempts.length}',
              _copy('practices', 'පුහුණු වාර'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _stat(String emoji, String value, String label) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 3),
            Text(
              value,
              style: _font(
                size: 16,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _font(
            size: 9.5,
            weight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _divider() =>
      Container(width: 1, height: 34, color: const Color(0xFFD4E7F7));

  Widget _pill(String text, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: _font(size: 10, weight: FontWeight.w700, color: foreground),
    ),
  );

  Widget _emptyCard(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [cardShadow],
    ),
    child: Text(text, style: _font(size: 13, color: AppColors.textSecondary)),
  );
}
