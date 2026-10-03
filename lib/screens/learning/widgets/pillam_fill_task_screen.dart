// lib/screens/learning/widgets/pillam_fill_task_screen.dart
// Grade 2 practice task: show a word with a missing pillam plus a picture
// cue, child taps the pillam that completes it. Scores the round and saves
// the attempt so parents/teachers can see progress over time.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grade_content.dart';
import '../models/pillam_fill_task.dart';
import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/task_picture.dart';

class PillamFillTaskScreen extends StatefulWidget {
  final String selectedLanguage;

  const PillamFillTaskScreen({super.key, required this.selectedLanguage});

  @override
  State<PillamFillTaskScreen> createState() => _PillamFillTaskScreenState();
}

class _PillamFillTaskScreenState extends State<PillamFillTaskScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF4ECDC4);
  static const _taskType = 'pillam_fill';

  late List<PillamFillQuestion> _questions;
  int _current = 0;
  int _score = 0;
  String? _selected;
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
    _questions = PillamFillTask.generate(Grade2Content.pillamFillWords);
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  PillamFillQuestion get _q => _questions[_current];

  void _select(String option) {
    if (_answered) return;
    final correct = option == _q.target.answer;
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) _score++;
    });
    _itemResults.add(
      TaskItemResult(itemId: _q.target.answer, isCorrect: correct),
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
        grade: 2,
        language: 'sinhala',
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
      _questions = PillamFillTask.generate(Grade2Content.pillamFillWords);
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
          _isSi ? '🧩 පිල්ලම් පුරවමු' : '🧩 Pillam Fill-in',
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
                    ? 'තව පිල්ලම් එකතු වෙමින් පවතී'
                    : 'More pillam coming soon',
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
                _buildWordCard(),
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

  Widget _buildWordCard() {
    final wordStyle = GoogleFonts.notoSansSinhala(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    Color blankBorder = _accent;
    Color blankText = Colors.grey;
    String blankLabel = '?';
    if (_answered) {
      final correct = _selected == _q.target.answer;
      blankBorder = correct ? Colors.green : Colors.red;
      blankText = correct ? Colors.green.shade800 : Colors.red.shade800;
      blankLabel = _selected ?? '?';
    }

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
            _isSi ? 'අඩු පිල්ලම තෝරන්න!' : 'Which pillam completes the word?',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TaskPicture(
            word: _q.target.word,
            fallbackEmoji: _q.target.emoji,
            size: 112,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_q.target.before, style: wordStyle),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 38,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: blankBorder, width: 2.5),
                  borderRadius: BorderRadius.circular(10),
                  color: blankBorder.withValues(alpha: 0.06),
                ),
                child: Text(
                  blankLabel,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: blankText,
                  ),
                ),
              ),
              Text(_q.target.after, style: wordStyle),
            ],
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
        final isSelected = _selected == option;
        final isCorrectAnswer = option == _q.target.answer;
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
                option,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 30,
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
    final isCorrect = _selected == _q.target.answer;
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
                        ? (_isSi
                              ? 'ශ්‍රේෂ්ඨයි! ${_q.target.word}'
                              : 'Great job! ${_q.target.word}')
                        : (_isSi
                              ? 'නිවැරදි වචනය: ${_q.target.word}'
                              : 'Correct word: ${_q.target.word}'),
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
                colors: [_accent, Color(0xFF54A0FF)],
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
