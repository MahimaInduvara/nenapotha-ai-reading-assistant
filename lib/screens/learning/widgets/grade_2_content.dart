// lib/screens/learning/widgets/grade_2_content.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grade_content.dart';
import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../widgets/bouncy_tap.dart';
import '../../../widgets/task_picture.dart';
import '../../letter_tracing_screen.dart';
import 'pillam_fill_task_screen.dart';
import 'pillam_naming_task_screen.dart';
import 'grade2_learning_path_screen.dart';

class Grade2ContentWidget extends StatefulWidget {
  final String selectedLanguage;
  final bool showHeader;
  const Grade2ContentWidget({
    super.key,
    required this.selectedLanguage,
    this.showHeader = true,
  });

  @override
  State<Grade2ContentWidget> createState() => _Grade2ContentWidgetState();
}

class _Grade2ContentWidgetState extends State<Grade2ContentWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final ScrollController _pillamScrollController = ScrollController();
  final GlobalKey _pillamShowcaseKey = GlobalKey();
  bool get _isSi => widget.selectedLanguage == 'sinhala';
  int _selectedPillamIndex = 0;
  bool _showBonus = false;

  String _exampleSyllable(PillamItem item) => 'ක${item.pillam}';
  String _displayPillam(PillamItem item) => '◌${item.pillam}';

  static const _pillamColors = <Color>[
    Color(0xFF18AFA7),
    Color(0xFFFF8A5B),
    Color(0xFF5B7CFA),
    Color(0xFF9B51E0),
    Color(0xFFFF5D8F),
    Color(0xFF42B95D),
  ];

  static const _g2Color = Color(0xFF4ECDC4);

  Color _pillamColor(PillamItem item) {
    final index = Grade2Content.pillam.indexOf(item);
    return _pillamColors[index % _pillamColors.length];
  }

  void _movePillam(int direction) {
    final core = Grade2Content.pillam
        .where((item) => item.category == 'core')
        .toList();
    final current = core.indexOf(Grade2Content.pillam[_selectedPillamIndex]);
    final next = (current + direction + core.length) % core.length;
    setState(
      () => _selectedPillamIndex = Grade2Content.pillam.indexOf(core[next]),
    );
  }

  void _selectPillam(int absoluteIndex, PillamItem pillam) {
    if (_selectedPillamIndex != absoluteIndex) {
      setState(() => _selectedPillamIndex = absoluteIndex);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final showcaseContext = _pillamShowcaseKey.currentContext;
      if (!mounted || showcaseContext == null) return;
      Scrollable.ensureVisible(
        showcaseContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _pillamScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showHeader) _buildHeader(),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            indicatorColor: _g2Color,
            indicatorWeight: 3,
            labelColor: _g2Color,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: _isSi ? '📖 පිල්ලම්' : '📖 Pillam'),
              Tab(text: _isSi ? '📝 වචන' : '📝 Words'),
              Tab(text: _isSi ? '✏️ ලිවීම' : '✏️ Tracing'),
              Tab(text: _isSi ? '🎯 කාර්යයන්' : '🎯 Tasks'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildPillamTab(),
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
        color: _g2Color,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Text('🌟', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSi
                      ? 'ශ්‍රේණිය 2 • වචන නිර්මාතෘ'
                      : 'Grade 2 • Word Builders',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isSi
                      ? 'පිල්ලම් සහ වචන ගොඩනෙමු!'
                      : 'Learn Pillam & Build Words!',
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

  // ── Pillam Tab ─────────────────────────────────────────────────────────────
  Widget _buildPillamTab() {
    final core = Grade2Content.pillam
        .where((p) => p.category == 'core')
        .toList();
    final bonus = Grade2Content.pillam
        .where((p) => p.category == 'bonus')
        .toList();
    final selected = Grade2Content.pillam[_selectedPillamIndex];

    return SingleChildScrollView(
      key: const ValueKey('pillam_tab_scroll'),
      controller: _pillamScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildIntroCard(),
          const SizedBox(height: 16),
          _buildPillamShowcase(selected),
          const SizedBox(height: 20),
          _buildSectionLabel(_isSi ? '🌟 මූලික පිල්ලම්' : '🌟 Core Pillam'),
          const SizedBox(height: 8),
          _buildPillamGrid(core),
          const SizedBox(height: 20),
          _buildBonusToggle(),
          if (_showBonus) ...[
            const SizedBox(height: 12),
            _buildSectionLabel(
              _isSi ? '🎓 උසස් පිල්ලම්' : '🎓 Advanced Pillam',
            ),
            const SizedBox(height: 4),
            Text(
              _isSi
                  ? 'සංස්කෘත වචනවලින් ආ දුර්ලභ ලකුණු — දැනගැනීමට රසවත්!'
                  : 'Rarer signs borrowed from Sanskrit words — fun to know, not required yet!',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            _buildPillamGrid(bonus),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _g2Color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _g2Color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👀', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSi
                      ? 'රූපයෙන් පිල්ලම ඉගෙන ගනිමු!'
                      : 'Learn each Pillam with a picture!',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF26324B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isSi
                      ? 'කාඩ්පතක් තෝරන්න • රූපය බලන්න • උදාහරණය කියවන්න'
                      : 'Choose a card • See the picture • Read the example',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildBonusToggle() {
    return BouncyTap(
      onTap: () => setState(() => _showBonus = !_showBonus),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showBonus
                  ? (_isSi
                        ? '🎓 උසස් පිල්ලම් සඟවන්න'
                        : '🎓 Hide Advanced Pillam')
                  : (_isSi
                        ? '🎓 උසස් පිල්ලම් පෙන්වන්න'
                        : '🎓 Show Advanced Pillam'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.amber.shade900,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _showBonus
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: Colors.amber.shade900,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillamGrid(List<PillamItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 176,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final absoluteIndex = Grade2Content.pillam.indexOf(p);
        final selected = absoluteIndex == _selectedPillamIndex;
        final color = _pillamColor(p);
        final example = p.examples.first;
        return Semantics(
          button: true,
          selected: selected,
          label: '${p.nameSi}. ක යෙදුම ${_exampleSyllable(p)}',
          child: GestureDetector(
            onTap: () => _selectPillam(absoluteIndex, p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.10) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? color : color.withValues(alpha: 0.20),
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? color.withValues(alpha: 0.24)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: selected ? 9 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TaskPicture(
                            word: example,
                            fallbackEmoji: '🖼️',
                            size: 58,
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _exampleSyllable(p),
                                style: GoogleFonts.notoSansSinhala(
                                  fontSize: 31,
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${_displayPillam(p)}  •  ${p.soundSi}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.notoSansSinhala(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.nameSi,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 12,
                      height: 1.25,
                      color: const Color(0xFF26324B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: selected ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            example,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillamShowcase(PillamItem p) {
    final color = _pillamColor(p);
    final example = p.examples.first;
    return Container(
      key: _pillamShowcaseKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _showcaseArrow(
                icon: Icons.chevron_left_rounded,
                color: color,
                onTap: () => _movePillam(-1),
                semanticLabel: _isSi ? 'පෙර පිල්ලම' : 'Previous pillam',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TaskPicture(
                    word: example,
                    fallbackEmoji: '🖼️',
                    size: 116,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      p.nameSi,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF26324B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _exampleSyllable(p),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_isSi ? "ශබ්දය" : "Sound"}: ${_isSi ? p.soundSi : p.soundEn}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _showcaseArrow(
                icon: Icons.chevron_right_rounded,
                color: color,
                onTap: () => _movePillam(1),
                semanticLabel: _isSi ? 'ඊළඟ පිල්ලම' : 'Next pillam',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _isSi ? 'අකුර ගොඩනගමු' : 'Build the sound',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'ක  +  ${_displayPillam(p)}  =  ${_exampleSyllable(p)}',
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 25,
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${_isSi ? "උදාහරණය" : "Example"}: $example',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _showcaseArrow({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }

  // ── Words Tab ──────────────────────────────────────────────────────────────
  Widget _buildWordsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: Grade2Content.words.length,
      itemBuilder: (_, i) {
        final w = Grade2Content.words[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(w.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                w.wordSi,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _g2Color,
                ),
              ),
              Text(
                w.wordEn,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                w.sentence,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tracing Tab ────────────────────────────────────────────────────────────
  Widget _buildTracingTab() {
    final tracingPillam = Grade2Content.pillam
        .where((p) => p.category == 'core')
        .take(4)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BouncyTap(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LetterTracingScreen(
                  selectedLanguage: widget.selectedLanguage,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_g2Color, Color(0xFF54A0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _g2Color.withValues(alpha: 0.3),
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
                        ? 'කෙටි පුහුණුව සඳහා ඕනෑම පිල්ලම් කාඩ්පතක් ඔබන්න.'
                        : 'Tap any pillam card to practise its Sinhala syllable.',
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
          ...tracingPillam.map(_buildTracingCard),
        ],
      ),
    );
  }

  Widget _buildTracingCard(PillamItem p) {
    final syllable = _exampleSyllable(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BouncyTap(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LetterTracingScreen(
              selectedLanguage: widget.selectedLanguage,
              initialLetter: syllable,
              practiceTargets: [
                TracePracticeTarget(
                  letter: syllable,
                  sound: p.soundSi,
                  exampleWord: p.examples.first,
                ),
              ],
            ),
          ),
        ),
        child: Semantics(
          button: true,
          label: _isSi
              ? '$syllable ලියන්න'
              : 'Practise tracing the Sinhala syllable $syllable',
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _g2Color.withValues(alpha: 0.28),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _g2Color.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TaskPicture(
                        word: p.examples.first,
                        fallbackEmoji: '🖼️',
                        size: 80,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 34),
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _g2Color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            syllable,
                            style: GoogleFonts.notoSansSinhala(
                              color: Colors.white,
                              fontSize: 15,
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
                        p.pillam,
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _g2Color,
                        ),
                      ),
                      Text(
                        p.nameSi,
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_isSi ? "ශබ්දය" : "Sound"}: ${p.soundSi}',
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        p.examples.first,
                        style: GoogleFonts.notoSansSinhala(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _g2Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _g2Color.withValues(alpha: 0.25),
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
          BouncyTap(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Grade2LearningPathScreen(
                    selectedLanguage: widget.selectedLanguage,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A89E), Color(0xFF397BE8)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A89E).withValues(alpha: 0.28),
                    blurRadius: 13,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 38)),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSi
                              ? 'මගේ උසස් මට්ටම් 6 මාවත'
                              : 'My 6-Level Advanced Path',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _isSi
                              ? 'පිල්ලම් සිට කියවීමේ අවබෝධය දක්වා'
                              : 'Pillam to reading comprehension',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _isSi
                                ? '70% ලබා ඉදිරියට යන්න'
                                : 'Reach 70% to level up',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 17),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isSi ? 'අමතර පුහුණුව' : 'Extra Practice',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildTaskCard(
            key: const ValueKey('pillam_fill'),
            taskType: 'pillam_fill',
            emoji: '🧩',
            titleSi: 'පිල්ලම් පුරවමු',
            titleEn: 'Pillam Fill-in',
            subtitleSi: 'රූපය බලා අඩු පිල්ලම තෝරන්න!',
            subtitleEn: 'Look at the picture & pick the missing pillam!',
            gradientColors: const [_g2Color, Color(0xFF54A0FF)],
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PillamFillTaskScreen(
                    selectedLanguage: widget.selectedLanguage,
                  ),
                ),
              );
              if (mounted) setState(() {}); // refresh best-score after a run
            },
          ),
          const SizedBox(height: 16),
          _buildTaskCard(
            key: const ValueKey('pillam_naming'),
            taskType: 'pillam_naming',
            emoji: '🔤',
            titleSi: 'පිල්ලම හඳුනාගමු',
            titleEn: 'Identify the Pillam',
            subtitleSi: 'පහත පිල්ලමට අදාළ නිවැරදි නම තෝරන්න.',
            subtitleEn: 'Choose the correct name for the pillam shown.',
            gradientColors: const [Color(0xFFFF9F43), Color(0xFFFFC93C)],
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PillamNamingTaskScreen(
                    selectedLanguage: widget.selectedLanguage,
                  ),
                ),
              );
              if (mounted) setState(() {}); // refresh best-score after a run
            },
          ),
        ],
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
        grade: 2,
        language: 'sinhala',
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
