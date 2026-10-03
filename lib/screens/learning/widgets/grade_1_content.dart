// lib/screens/learning/widgets/grade_1_content.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grade_content.dart';
import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/bouncy_tap.dart';
import '../../../widgets/task_picture.dart';
import '../../letter_tracing_screen.dart';
import 'letter_detail_screen.dart';
import 'grade1_learning_path_screen.dart';
import 'letter_matching_task_screen.dart';
import 'letter_recognition_task_screen.dart';

class Grade1ContentWidget extends StatefulWidget {
  final String selectedLanguage;
  final String? learningLanguage;
  final bool showHeader;
  const Grade1ContentWidget({
    super.key,
    required this.selectedLanguage,
    this.learningLanguage,
    this.showHeader = true,
  });

  @override
  State<Grade1ContentWidget> createState() => _Grade1ContentWidgetState();
}

class _Grade1ContentWidgetState extends State<Grade1ContentWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool get _isSi => widget.selectedLanguage == 'sinhala';
  String get _contentLanguage =>
      widget.learningLanguage ?? widget.selectedLanguage;
  int _selectedLetterIndex = 0;
  late bool _showEnglish;

  static const _g1Color = Color(0xFFFF6B6B);

  Color _colorFor(int index) => AppColors.kidColorFor(index);

  @override
  void initState() {
    super.initState();
    _showEnglish = _contentLanguage == 'english';
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void didUpdateWidget(covariant Grade1ContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.learningLanguage != widget.learningLanguage) {
      _showEnglish = _contentLanguage == 'english';
      _selectedLetterIndex = 0;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showHeader) _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildLettersTab(),
              _buildWordsTab(),
              _buildTracingTab(),
              _buildTasksTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _g1Color,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSi
                      ? 'ශ්‍රේණිය 1 • අකුරු ගවේෂකයෝ'
                      : 'Grade 1 • Letter Explorers',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isSi
                      ? 'ශ්‍රී ලාංකික සහ ඉංග්‍රීසි අකුරු ඉගෙනගනිමු!'
                      : 'Learn Sinhala & English Letters!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: _g1Color,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: _isSi ? '📖 අකුරු' : '📖 Letters'),
          Tab(text: _isSi ? '📝 වචන' : '📝 Words'),
          Tab(text: _isSi ? '✏️ ලිවීම' : '✏️ Tracing'),
          Tab(text: _isSi ? '🎯 කාර්යයන්' : '🎯 Tasks'),
        ],
      ),
    );
  }

  void _openLetter(List<LetterItem> letters, int index) {
    setState(() => _selectedLetterIndex = index);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterDetailScreen(
          letter: letters[index],
          selectedLanguage: widget.selectedLanguage,
          isEnglish: _showEnglish,
          accentColor: _colorFor(index),
        ),
      ),
    );
  }

  // ── Letters Tab ────────────────────────────────────────────────────────────
  Widget _buildLettersTab() {
    final letters = _showEnglish
        ? Grade1Content.englishLetters
        : Grade1Content.sinhalaLetters;
    return CustomScrollView(
      key: PageStorageKey<String>(
        'grade1-letters-${_showEnglish ? 'english' : 'sinhala'}',
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _buildLetterShowcase(letters[_selectedLetterIndex]),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate((_, i) {
              final selected = i == _selectedLetterIndex;
              final color = _colorFor(i);
              return BouncyTap(
                onTap: () => _openLetter(letters, i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color, width: selected ? 3 : 1.5),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      letters[i].letter,
                      style: _showEnglish
                          ? TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : color,
                            )
                          : GoogleFonts.notoSansSinhala(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : color,
                            ),
                    ),
                  ),
                ),
              );
            }, childCount: letters.length),
          ),
        ),
      ],
    );
  }

  Widget _buildLetterShowcase(LetterItem item) {
    final color = _colorFor(_selectedLetterIndex);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Row(
        children: [
          BouncyTap(
            onTap: () => _openLetter(
              _showEnglish
                  ? Grade1Content.englishLetters
                  : Grade1Content.sinhalaLetters,
              _selectedLetterIndex,
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  item.letter,
                  style: _showEnglish
                      ? const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )
                      : GoogleFonts.notoSansSinhala(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_isSi ? "ශබ්දය" : "Sound"}: "${item.sound}"',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 23)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.exampleWord,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.exampleWordEn.trim().isNotEmpty)
                            Text(
                              item.exampleWordEn,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openLetter(
                    _showEnglish
                        ? Grade1Content.englishLetters
                        : Grade1Content.sinhalaLetters,
                    _selectedLetterIndex,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isSi ? 'තව වචන බලන්න' : 'See more words',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: color),
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

  // ── Words Tab ──────────────────────────────────────────────────────────────
  Widget _buildWordsTab() {
    final words = _showEnglish
        ? Grade1Content.englishLetters
              .map(
                (letter) => VocabWord(
                  wordSi: letter.exampleWord,
                  wordEn: letter.exampleWord,
                  emoji: letter.emoji,
                  sentence: '${letter.letter} is for ${letter.exampleWord}.',
                ),
              )
              .toList()
        : Grade1Content.simpleWords;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1,
      ),
      itemCount: words.length,
      itemBuilder: (_, i) {
        final w = words[i];
        final color = _colorFor(i);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(w.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                w.wordSi,
                style:
                    (_showEnglish
                            ? GoogleFonts.poppins()
                            : GoogleFonts.notoSansSinhala())
                        .copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
              ),
              const SizedBox(height: 6),
              Text(
                w.sentence,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    (_showEnglish
                            ? GoogleFonts.poppins()
                            : GoogleFonts.notoSansSinhala())
                        .copyWith(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tracing Tab ────────────────────────────────────────────────────────────
  Widget _buildTracingTab() {
    final tracingLetters = _showEnglish
        ? Grade1Content.englishLetters.take(4).toList()
        : Grade1Content.sinhalaLetters.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Launch full tracing screen
          BouncyTap(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LetterTracingScreen(
                  selectedLanguage: widget.selectedLanguage,
                  useEnglishLetters: _showEnglish,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('✏️', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSi
                              ? 'සම්පූර්ණ අකුරු ලිවීමේ කාමරය'
                              : 'Full Letter Tracing Studio',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _isSi
                              ? 'ඇඟිල්ලෙන් ඇද ලකුණු දිනන්න!'
                              : 'Trace with your finger & earn stars!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Text('✏️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isSi
                        ? 'කෙටි පුහුණුව සඳහා ඕනෑම අකුරු කාඩ්පතක් ඔබන්න.'
                        : 'Tap any letter card for quick tracing practice.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...tracingLetters.asMap().entries.map(
            (e) => _buildTracingCard(e.value, _colorFor(e.key)),
          ),
        ],
      ),
    );
  }

  Widget _buildTracingCard(LetterItem letter, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BouncyTap(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LetterTracingScreen(
              selectedLanguage: widget.selectedLanguage,
              useEnglishLetters: _showEnglish,
              initialLetter: letter.letter,
            ),
          ),
        ),
        child: Semantics(
          button: true,
          label: _isSi
              ? '${letter.letter} අකුර ලියන්න'
              : 'Practise tracing letter ${letter.letter}',
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.28),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.09),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // A concrete picture clue helps a young child connect the
                // abstract letter with a familiar object before tracing it.
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TaskPicture(
                        word: letter.exampleWord,
                        fallbackEmoji: letter.emoji,
                        size: 80,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            letter.letter,
                            style: _showEnglish
                                ? const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  )
                                : GoogleFonts.notoSansSinhala(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        letter.letter,
                        style: _showEnglish
                            ? TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: color,
                              )
                            : GoogleFonts.notoSansSinhala(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                      ),
                      Text(
                        '${_isSi ? "ශබ්දය" : "Sound"}: ${letter.sound}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${letter.emoji} ${letter.exampleWord}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tasks Tab ──────────────────────────────────────────────────────────────
  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLearningPathCard(),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isSi ? 'අමතර පුහුණුව' : 'Extra Practice',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildTaskCard(
            key: ValueKey('letter_recognition_$_showEnglish'),
            taskType: 'letter_recognition',
            emoji: '🔤',
            titleSi: 'අකුරු හඳුනා ගනිමු',
            titleEn: 'Letter Recognition',
            subtitleSi: 'රූපය බලා නිවැරදි අකුර තෝරන්න!',
            subtitleEn: 'Look at the picture & pick the right letter!',
            gradientColors: const [_g1Color, Color(0xFFFF9F43)],
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LetterRecognitionTaskScreen(
                    selectedLanguage: widget.selectedLanguage,
                    isEnglish: _showEnglish,
                  ),
                ),
              );
              if (mounted) setState(() {}); // refresh best-score after a run
            },
          ),
          const SizedBox(height: 16),
          _buildTaskCard(
            key: ValueKey('letter_matching_$_showEnglish'),
            taskType: 'letter_matching',
            emoji: '🔗',
            titleSi: 'අකුරු ගලපමු',
            titleEn: 'Letter Matching',
            subtitleSi: 'එකම අකුර යා කරන්න!',
            subtitleEn: 'Connect each letter to its match!',
            gradientColors: const [Color(0xFF9C88FF), Color(0xFF54A0FF)],
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LetterMatchingTaskScreen(
                    selectedLanguage: widget.selectedLanguage,
                    isEnglish: _showEnglish,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathCard() {
    return BouncyTap(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Grade1LearningPathScreen(
              selectedLanguage: widget.selectedLanguage,
              isEnglish: _showEnglish,
            ),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B4CF0), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B4CF0).withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 42)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSi ? 'මගේ මට්ටම් 5 මාවත' : 'My 5-Level Learning Path',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _isSi
                        ? 'පහසු සිට අභියෝග දක්වා • ප්‍රගතිය සුරකිමු'
                        : 'Easy to challenge • Track every step',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isSi
                          ? '70% ලබා ඊළඟ මට්ටම අරින්න'
                          : 'Reach 70% to level up',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required Key key,
    required String taskType,
    required String emoji,
    required String titleSi,
    required String titleEn,
    required String subtitleSi,
    required String subtitleEn,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<TaskAttempt?>(
      key: key,
      future: TaskProgressService().getBest(
        taskType: taskType,
        grade: 1,
        language: _showEnglish ? 'english' : 'sinhala',
      ),
      builder: (context, snapshot) {
        final best = snapshot.data;
        return BouncyTap(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSi ? titleSi : titleEn,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isSi ? subtitleSi : subtitleEn,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      if (best != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_isSi ? "හොඳම ලකුණු" : "Best"}: ${best.score}/${best.total} (${best.percentage.round()}%)',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
