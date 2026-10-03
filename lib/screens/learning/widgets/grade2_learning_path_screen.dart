import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/bouncy_tap.dart';
import '../../../widgets/task_picture.dart';
import '../models/grade2_level_task.dart';

const _grade2LevelColors = [
  Color(0xFF16A89E),
  Color(0xFF3489EB),
  Color(0xFFFF8B3D),
  Color(0xFF9C55C7),
  Color(0xFFEC4E68),
  Color(0xFF6654D9),
];

class Grade2LearningPathScreen extends StatefulWidget {
  final String selectedLanguage;

  const Grade2LearningPathScreen({super.key, required this.selectedLanguage});

  @override
  State<Grade2LearningPathScreen> createState() =>
      _Grade2LearningPathScreenState();
}

class _Grade2LearningPathScreenState extends State<Grade2LearningPathScreen> {
  final Map<int, TaskAttempt?> _best = {};
  bool _loading = true;
  bool get _isSi => widget.selectedLanguage == 'sinhala';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait(
      Grade2LevelDefinition.levels.map(
        (level) => TaskProgressService().getBest(
          taskType: level.taskType,
          grade: 2,
          language: 'sinhala',
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < results.length; i++) {
        _best[i + 1] = results[i];
      }
      _loading = false;
    });
  }

  Map<int, double> get _percentages => {
    for (final entry in _best.entries)
      if (entry.value != null) entry.key: entry.value!.percentage,
  };

  int get _mastered => _best.values
      .where(
        (attempt) =>
            attempt != null &&
            attempt.percentage >= Grade2LevelDefinition.unlockPercentage,
      )
      .length;

  Future<void> _open(Grade2LevelDefinition level) async {
    if (!Grade2LevelDefinition.isUnlocked(level.level, _percentages)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSi
                ? 'පළමුව පෙර මට්ටමෙන් 70% ක් ලබාගන්න.'
                : 'Score 70% in the previous level first.',
          ),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Grade2LevelTaskScreen(
          selectedLanguage: widget.selectedLanguage,
          definition: level,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isSi ? 'මගේ උසස් ඉගෙනුම් මාවත' : 'My Advanced Learning Path',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _header(),
                const SizedBox(height: 16),
                ...Grade2LevelDefinition.levels.map(_levelCard),
                _note(),
              ],
            ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF16A89E), Color(0xFF397BE8)],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF16A89E).withValues(alpha: 0.25),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSi ? 'වචනවලින් අවබෝධයට' : 'Words to Understanding',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _isSi
                        ? 'පියවරෙන් පියවර උසස් කුසලතා 6ක්'
                        : 'Six progressive Grade 2 skill levels',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isSi ? 'සම්පූර්ණ කළ මට්ටම්' : 'Levels mastered',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            Text(
              '$_mastered/6',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: _mastered / 6,
          minHeight: 9,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
        ),
      ],
    ),
  );

  Widget _levelCard(Grade2LevelDefinition level) {
    final unlocked = Grade2LevelDefinition.isUnlocked(
      level.level,
      _percentages,
    );
    final best = _best[level.level];
    final mastered =
        best != null &&
        best.percentage >= Grade2LevelDefinition.unlockPercentage;
    final color = _grade2LevelColors[level.level - 1];
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: BouncyTap(
        onTap: () => _open(level),
        child: Opacity(
          opacity: unlocked ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: mastered ? Colors.green : color.withValues(alpha: 0.3),
                width: mastered ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: unlocked
                      ? Text(level.emoji, style: const TextStyle(fontSize: 28))
                      : const Icon(Icons.lock_rounded),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_isSi ? 'මට්ටම ' : 'Level '}${level.level}',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _isSi ? level.titleSi : level.titleEn,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        unlocked
                            ? (_isSi ? level.subtitleSi : level.subtitleEn)
                            : (_isSi
                                  ? 'පෙර මට්ටම සම්පූර්ණ කරන්න'
                                  : 'Complete the previous level'),
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (best != null) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: best.percentage / 100,
                          minHeight: 6,
                          color: mastered ? Colors.green : color,
                          backgroundColor: color.withValues(alpha: 0.1),
                        ),
                        Text(
                          '${_isSi ? 'හොඳම: ' : 'Best: '}'
                          '${best.percentage.round()}%',
                          style: GoogleFonts.poppins(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  mastered
                      ? Icons.verified_rounded
                      : unlocked
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: mastered ? Colors.green : color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFFFD54F)),
    ),
    child: Text(
      _isSi
          ? '💡 ඊළඟ මට්ටම විවෘත කිරීමට 70% ක් ගන්න. සෑම පිල්ලමක්, වචනයක් හා අවබෝධ ප්‍රශ්නයක්ම ප්‍රගතියට සුරැකේ.'
          : '💡 Score 70% to unlock the next level. Pillam, vocabulary, sentence, and comprehension results are saved in Progress.',
      style: GoogleFonts.poppins(
        color: const Color(0xFF7A5B00),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class Grade2LevelTaskScreen extends StatefulWidget {
  final String selectedLanguage;
  final Grade2LevelDefinition definition;

  const Grade2LevelTaskScreen({
    super.key,
    required this.selectedLanguage,
    required this.definition,
  });

  @override
  State<Grade2LevelTaskScreen> createState() => _Grade2LevelTaskScreenState();
}

class _Grade2LevelTaskScreenState extends State<Grade2LevelTaskScreen> {
  late List<Grade2LevelQuestion> _questions;
  final List<TaskItemResult> _items = [];
  int _current = 0;
  int _score = 0;
  String? _selected;
  bool _answered = false;
  bool _done = false;

  bool get _isSi => widget.selectedLanguage == 'sinhala';
  Color get _accent => _grade2LevelColors[widget.definition.level - 1];
  Grade2LevelQuestion get _question => _questions[_current];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _questions = Grade2LevelTask.generate(level: widget.definition.level);
  }

  void _choose(String choice) {
    if (_answered) return;
    final correct = choice == _question.answer;
    setState(() {
      _selected = choice;
      _answered = true;
      if (correct) _score++;
    });
    _items.add(TaskItemResult(itemId: _question.itemId, isCorrect: correct));
  }

  Future<void> _next() async {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
      return;
    }
    await TaskProgressService().saveAttempt(
      TaskAttempt(
        taskType: widget.definition.taskType,
        grade: 2,
        language: 'sinhala',
        score: _score,
        total: _questions.length,
        completedAt: DateTime.now(),
        items: List.unmodifiable(_items),
      ),
    );
    if (mounted) setState(() => _done = true);
  }

  void _retry() {
    setState(() {
      _newRound();
      _current = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _done = false;
      _items.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.definition.emoji} '
          '${_isSi ? widget.definition.titleSi : widget.definition.titleEn}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: _questions.isEmpty
          ? Center(
              child: Text(_isSi ? 'කාර්ය අන්තර්ගතය නැත' : 'No task content'),
            )
          : _done
          ? _results()
          : _quiz(),
    );
  }

  Widget _quiz() => Column(
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_isSi ? 'ලකුණු: ' : 'Score: '}$_score/'
                  '${_questions.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_current + 1}/${_questions.length}',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              minHeight: 8,
              color: Colors.amber,
              backgroundColor: Colors.white24,
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _clue(),
            const SizedBox(height: 16),
            _options(),
            if (_answered) ...[
              const SizedBox(height: 14),
              _feedback(),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _current == _questions.length - 1
                      ? (_isSi ? 'ප්‍රතිඵල බලන්න 🏆' : 'See results 🏆')
                      : (_isSi ? 'ඊළඟ ප්‍රශ්නය →' : 'Next question →'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _clue() {
    final question = _question;
    final showLargeGlyph =
        question.mode == Grade2QuestionMode.identifyPillam ||
        question.mode == Grade2QuestionMode.completePillam;
    final isPicture = question.mode == Grade2QuestionMode.pictureWord;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isSi ? question.promptSi : question.promptEn,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (isPicture)
            TaskPicture(
              word: question.itemId,
              fallbackEmoji: question.display,
              size: 128,
            )
          else ...[
            if (question.emoji != null)
              TaskPicture(
                word: question.itemId,
                fallbackEmoji: question.emoji!,
                size: 82,
              ),
            Text(
              question.display,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                color: _accent,
                fontSize: showLargeGlyph ? 48 : 25,
                height: 1.55,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _options() => Column(
    children: _question.options.map((choice) {
      final selected = _selected == choice;
      final correct = choice == _question.answer;
      var background = Colors.white;
      var border = Colors.grey.shade200;
      var foreground = AppColors.textPrimary;
      if (_answered && correct) {
        background = Colors.green.shade50;
        border = Colors.green;
        foreground = Colors.green.shade800;
      } else if (_answered && selected) {
        background = Colors.red.shade50;
        border = Colors.red;
        foreground = Colors.red.shade800;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: BouncyTap(
          onTap: () => _choose(choice),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: border, width: 2),
            ),
            child: Text(
              choice,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _feedback() {
    final correct = _selected == _question.answer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: correct ? Colors.green : Colors.orange),
      ),
      child: Text(
        correct
            ? (_isSi
                  ? '🌟 හරි! ඉතා හොඳින් තේරුම් ගත්තා.'
                  : '🌟 Correct! Well understood.')
            : (_isSi
                  ? '💡 නිවැරදි පිළිතුර: ${_question.answer}'
                  : '💡 Correct answer: ${_question.answer}'),
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _results() {
    final percentage = (_score / _questions.length * 100).round();
    final mastered =
        percentage >= Grade2LevelDefinition.unlockPercentage.round();
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _accent.withValues(alpha: 0.72)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Text(
                mastered ? '🏆' : '💪',
                style: const TextStyle(fontSize: 64),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                mastered
                    ? (_isSi ? 'මට්ටම සම්පූර්ණයි!' : 'Level mastered!')
                    : (_isSi
                          ? '70% ලබාගන්න නැවත උත්සාහ කරන්න'
                          : 'Try again and reach 70%'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_isSi ? 'නිවැරදි: ' : 'Correct: '}$_score/'
                '${_questions.length}',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (mastered && widget.definition.level < 6)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _isSi
                  ? '🎉 ඊළඟ උසස් මට්ටම දැන් විවෘතයි!'
                  : '🎉 The next advanced level is now unlocked!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_isSi ? 'මට්ටම් වෙත' : 'All levels'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isSi ? 'නැවත කරන්න' : 'Try again'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
