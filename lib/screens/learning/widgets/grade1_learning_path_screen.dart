import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/bouncy_tap.dart';
import '../../../widgets/task_picture.dart';
import '../models/grade1_level_task.dart';
import '../models/grade_content.dart';

const _levelColors = [
  Color(0xFF20B2AA),
  Color(0xFF42A5F5),
  Color(0xFFFF9F43),
  Color(0xFFAB47BC),
  Color(0xFFEF5350),
];

class Grade1LearningPathScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isEnglish;

  const Grade1LearningPathScreen({
    super.key,
    required this.selectedLanguage,
    required this.isEnglish,
  });

  @override
  State<Grade1LearningPathScreen> createState() =>
      _Grade1LearningPathScreenState();
}

class _Grade1LearningPathScreenState extends State<Grade1LearningPathScreen> {
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
      Grade1LevelDefinition.levels.map(
        (level) => TaskProgressService().getBest(
          taskType: level.taskType,
          grade: 1,
          language: widget.isEnglish ? 'english' : 'sinhala',
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
        (item) =>
            item != null &&
            item.percentage >= Grade1LevelDefinition.unlockPercentage,
      )
      .length;

  Future<void> _open(Grade1LevelDefinition level) async {
    if (!Grade1LevelDefinition.isUnlocked(level.level, _percentages)) {
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
        builder: (_) => Grade1LevelTaskScreen(
          selectedLanguage: widget.selectedLanguage,
          isEnglish: widget.isEnglish,
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
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isSi ? 'මගේ ඉගෙනුම් මාවත' : 'My Learning Path',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  ...Grade1LevelDefinition.levels.map(_levelCard),
                  _note(),
                ],
              ),
            ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF5B4CF0), Color(0xFF8B5CF6)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSi ? 'පහසු සිට අමාරු දක්වා' : 'Easy to Challenge',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _isSi
                        ? 'මට්ටම් 5කින් පියවරෙන් පියවර ඉගෙනගන්න'
                        : 'Grow step by step through 5 skill levels',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isSi ? 'සම්පූර්ණ කළ මට්ටම්' : 'Levels mastered',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            Text(
              '$_mastered/5',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _mastered / 5,
            minHeight: 9,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
          ),
        ),
      ],
    ),
  );

  Widget _levelCard(Grade1LevelDefinition level) {
    final unlocked = Grade1LevelDefinition.isUnlocked(
      level.level,
      _percentages,
    );
    final best = _best[level.level];
    final mastered =
        best != null &&
        best.percentage >= Grade1LevelDefinition.unlockPercentage;
    final color = _levelColors[level.level - 1];
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
          ? '💡 ඊළඟ මට්ටම විවෘත කිරීමට 70% ක් අවශ්‍යයි. සෑම උත්සාහයක්ම ප්‍රගතියට සුරැකේ.'
          : '💡 Score 70% to unlock the next level. Every attempt and difficult letter is saved in Progress.',
      style: GoogleFonts.poppins(
        color: const Color(0xFF7A5B00),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class Grade1LevelTaskScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isEnglish;
  final Grade1LevelDefinition definition;

  const Grade1LevelTaskScreen({
    super.key,
    required this.selectedLanguage,
    required this.isEnglish,
    required this.definition,
  });

  @override
  State<Grade1LevelTaskScreen> createState() => _Grade1LevelTaskScreenState();
}

class _Grade1LevelTaskScreenState extends State<Grade1LevelTaskScreen> {
  late List<Grade1LevelQuestion> _questions;
  final List<TaskItemResult> _items = [];
  int _current = 0;
  int _score = 0;
  LetterItem? _selected;
  bool _answered = false;
  bool _done = false;

  bool get _isSi => widget.selectedLanguage == 'sinhala';
  Color get _accent => _levelColors[widget.definition.level - 1];
  Grade1LevelQuestion get _question => _questions[_current];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _questions = Grade1LevelTask.generate(
      letters: widget.isEnglish
          ? Grade1Content.englishLetters
          : Grade1Content.sinhalaLetters,
      level: widget.definition.level,
    );
  }

  void _choose(LetterItem choice) {
    if (_answered) return;
    final correct = choice.letter == _question.target.letter;
    setState(() {
      _selected = choice;
      _answered = true;
      if (correct) _score++;
    });
    _items.add(
      TaskItemResult(itemId: _question.target.letter, isCorrect: correct),
    );
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
        grade: 1,
        language: widget.isEnglish ? 'english' : 'sinhala',
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
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
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
          padding: const EdgeInsets.all(20),
          children: [
            _clue(),
            const SizedBox(height: 20),
            _options(),
            if (_answered) ...[
              const SizedBox(height: 16),
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
    final mode = _question.mode;
    final title = switch (mode) {
      Grade1QuestionMode.visualMatch =>
        _isSi ? 'මේ අකුර සොයන්න' : 'Find this letter',
      Grade1QuestionMode.wordClue =>
        _isSi ? 'මේ වචනයේ මුල් අකුර තෝරන්න' : 'Choose this word’s first letter',
      Grade1QuestionMode.pictureInitial =>
        _isSi ? 'රූපයේ මුල් අකුර තෝරන්න' : 'Choose the first letter',
      Grade1QuestionMode.missingInitial =>
        _isSi ? 'අඩු මුල් අකුර පුරවන්න' : 'Complete the word',
    };
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
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (mode == Grade1QuestionMode.visualMatch)
            Text(_question.target.letter, style: _letterStyle(72, _accent))
          else if (mode == Grade1QuestionMode.wordClue) ...[
            TaskPicture(
              word: _question.target.exampleWord,
              fallbackEmoji: _question.target.emoji,
              size: 92,
            ),
            const SizedBox(height: 8),
            Text(
              _question.target.exampleWord,
              style: _letterStyle(30, _accent),
            ),
          ] else if (mode == Grade1QuestionMode.pictureInitial)
            TaskPicture(
              word: _question.target.exampleWord,
              fallbackEmoji: _question.target.emoji,
              size: 124,
            )
          else ...[
            TaskPicture(
              word: _question.target.exampleWord,
              fallbackEmoji: _question.target.emoji,
              size: 76,
            ),
            Text(_question.missingWord, style: _letterStyle(34, _accent)),
          ],
        ],
      ),
    );
  }

  Widget _options() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: widget.definition.optionCount >= 5 ? 3 : 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.5,
    children: _question.options.map((choice) {
      final selected = _selected?.letter == choice.letter;
      final correct = choice.letter == _question.target.letter;
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
      return BouncyTap(
        onTap: () => _choose(choice),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(choice.letter, style: _letterStyle(31, foreground)),
        ),
      );
    }).toList(),
  );

  Widget _feedback() {
    final correct = _selected?.letter == _question.target.letter;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: correct ? Colors.green : Colors.orange),
      ),
      child: Text(
        correct
            ? (_isSi ? '🌟 හරි! ඉතා හොඳයි.' : '🌟 Correct! Great work.')
            : (_isSi
                  ? '💡 නිවැරදි අකුර: ${_question.target.letter}'
                  : '💡 Correct letter: ${_question.target.letter}'),
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _results() {
    final percentage = (_score / _questions.length * 100).round();
    final mastered =
        percentage >= Grade1LevelDefinition.unlockPercentage.round();
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
        if (mastered && widget.definition.level < 5)
          _message(
            _isSi
                ? '🎉 ඊළඟ මට්ටම දැන් විවෘතයි!'
                : '🎉 The next level is now unlocked!',
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

  Widget _message(String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: Colors.green.shade800,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  TextStyle _letterStyle(double size, Color color) => widget.isEnglish
      ? GoogleFonts.poppins(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w800,
        )
      : GoogleFonts.notoSansSinhala(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w700,
        );
}
