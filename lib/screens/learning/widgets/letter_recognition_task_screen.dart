// lib/screens/learning/widgets/letter_recognition_task_screen.dart
// Grade 1 practice task: show a picture, child taps the letter it starts
// with. Scores the round and saves the attempt so parents/teachers can see
// how the child is progressing over time.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grade_content.dart';
import '../models/letter_recognition_task.dart';
import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/task_picture.dart';

class LetterRecognitionTaskScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isEnglish;
  final int gradeLevel;

  const LetterRecognitionTaskScreen({
    super.key,
    required this.selectedLanguage,
    required this.isEnglish,
    this.gradeLevel = 1,
  });

  @override
  State<LetterRecognitionTaskScreen> createState() =>
      _LetterRecognitionTaskScreenState();
}

class _LetterRecognitionTaskScreenState
    extends State<LetterRecognitionTaskScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFFF6B6B);
  static const _taskType = 'letter_recognition';

  late List<LetterRecognitionQuestion> _questions;
  int _current = 0;
  int _score = 0;
  LetterItem? _selected;
  bool _answered = false;
  bool _done = false;
  late AnimationController _feedbackCtrl;
  final List<TaskItemResult> _itemResults = [];

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _questions = LetterRecognitionTask.generate(
      widget.isEnglish
          ? Grade1Content.englishLetters
          : Grade1Content.sinhalaLetters,
    );
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  LetterRecognitionQuestion get _q => _questions[_current];

  void _select(LetterItem option) {
    if (_answered) return;
    final correct = option.letter == _q.target.letter;
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) _score++;
    });
    _itemResults.add(
      TaskItemResult(itemId: _q.target.letter, isCorrect: correct),
    );
    _feedbackCtrl.forward(from: 0);
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _answered = false;
        _selected = null;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await TaskProgressService().saveAttempt(
      TaskAttempt(
        taskType: _taskType,
        grade: widget.gradeLevel,
        language: widget.isEnglish ? 'english' : 'sinhala',
        score: _score,
        total: _questions.length,
        completedAt: DateTime.now(),
        items: List.of(_itemResults),
      ),
    );
    if (mounted) setState(() => _done = true);
  }

  void _retry() {
    setState(() {
      _questions = LetterRecognitionTask.generate(
        widget.isEnglish
            ? Grade1Content.englishLetters
            : Grade1Content.sinhalaLetters,
      );
      _current = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _done = false;
      _itemResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSi ? '🔤 අකුරු හඳුනා ගනිමු' : '🔤 Letter Recognition',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_done)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_current + 1}/${_questions.length}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _questions.isEmpty
          ? Center(
              child: Text(
                _isSi
                    ? 'තව අකුරු එකතු වෙමින් පවතී'
                    : 'More letters coming soon',
                style: GoogleFonts.poppins(),
              ),
            )
          : (_done ? _buildResults() : _buildQuiz()),
    );
  }

  Widget _buildQuiz() {
    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPictureCard(),
                const SizedBox(height: 24),
                _buildOptions(),
                if (_answered) ...[
                  const SizedBox(height: 20),
                  _buildFeedback(),
                  const SizedBox(height: 16),
                  _buildNextButton(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_isSi ? 'ලකුණු' : 'Score'}: $_score/${_questions.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPictureCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isSi
                ? 'මේ පටන් ගන්නේ කුමන අකුරෙන්ද?'
                : 'Which letter does this start with?',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TaskPicture(
            word: _q.target.exampleWord,
            fallbackEmoji: _q.target.emoji,
            size: 132,
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: _q.options.map((option) {
        final isSelected = _selected?.letter == option.letter;
        final isCorrectAnswer = option.letter == _q.target.letter;
        Color bg = Colors.white;
        Color border = Colors.grey.shade200;
        Color textColor = Colors.black87;

        if (_answered && isCorrectAnswer) {
          bg = Colors.green.shade50;
          border = Colors.green;
          textColor = Colors.green.shade800;
        } else if (_answered && isSelected) {
          bg = Colors.red.shade50;
          border = Colors.red;
          textColor = Colors.red.shade800;
        } else if (isSelected) {
          bg = _accent.withValues(alpha: 0.08);
          border = _accent;
          textColor = _accent;
        }

        return GestureDetector(
          onTap: () => _select(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                option.letter,
                style: widget.isEnglish
                    ? TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      )
                    : GoogleFonts.notoSansSinhala(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _selected?.letter == _q.target.letter;
    return AnimatedBuilder(
      animation: _feedbackCtrl,
      builder: (context, child) => Transform.scale(
        scale: 0.8 + 0.2 * _feedbackCtrl.value,
        child: Opacity(
          opacity: _feedbackCtrl.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(
                  isCorrect ? '🎉' : '💡',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCorrect
                        ? (_isSi ? 'ශ්‍රේෂ්ඨයි!' : 'Great job!')
                        : (_isSi
                              ? 'නිවැරදි අකුර: ${_q.target.letter}'
                              : 'Correct letter: ${_q.target.letter}'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: isCorrect
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _current == _questions.length - 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLast ? Colors.green : _accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: _next,
        child: Text(
          isLast
              ? (_isSi ? '🏆 ප්‍රතිඵල බලන්න' : '🏆 See Results')
              : (_isSi ? 'ඊළඟ →' : 'Next →'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final pct = (_score / _questions.length * 100).round();
    final emoji = pct >= 80
        ? '🏆'
        : pct >= 60
        ? '⭐'
        : '💪';
    final message = pct >= 80
        ? (_isSi ? 'විශිෂ්ටයි!' : 'Excellent!')
        : pct >= 60
        ? (_isSi ? 'හොඳයි!' : 'Good Job!')
        : (_isSi ? 'දිගටම පුරුදු වෙන්න!' : 'Keep Practising!');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accent, Color(0xFFFF9F43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  '$pct%',
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_isSi ? 'නිවැරදි' : 'Correct'}: $_score/${_questions.length}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _isSi ? 'ආපසු' : 'Go Back',
                    style: GoogleFonts.poppins(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _retry,
                  child: Text(
                    _isSi ? '🔄 නැවත' : '🔄 Retry',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
