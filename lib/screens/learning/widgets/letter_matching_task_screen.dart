// lib/screens/learning/widgets/letter_matching_task_screen.dart
// Grade 1 practice task: two shuffled columns of the same letters — tap one
// on the left then its match on the right to connect them. Tracks which
// letters were matched without a prior wrong guess ("perfect" matches) as
// the score, and saves the attempt for progress tracking.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grade_content.dart';
import '../models/letter_matching_task.dart';
import '../../../models/task_attempt.dart';
import '../../../services/task_progress_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/bouncy_tap.dart';

class LetterMatchingTaskScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isEnglish;
  final int gradeLevel;

  const LetterMatchingTaskScreen({
    super.key,
    required this.selectedLanguage,
    required this.isEnglish,
    this.gradeLevel = 1,
  });

  @override
  State<LetterMatchingTaskScreen> createState() =>
      _LetterMatchingTaskScreenState();
}

class _LetterMatchingTaskScreenState extends State<LetterMatchingTaskScreen> {
  static const _accent = Color(0xFF9C88FF);
  static const _taskType = 'letter_matching';

  late List<String> _left;
  late List<String> _right;
  int? _selectedLeft;
  final Set<int> _matchedLeft = {};
  final Set<int> _matchedRight = {};
  final Set<String> _mistakeLetters = {};
  int _wrongLeft = -1;
  int _wrongRight = -1;
  bool _done = false;

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  @override
  void initState() {
    super.initState();
    _generateRound();
  }

  void _generateRound() {
    final letters = widget.isEnglish
        ? Grade1Content.englishLetters
        : Grade1Content.sinhalaLetters;
    final (left, right) = LetterMatchingTask.generate(letters);
    _left = left;
    _right = right;
    _selectedLeft = null;
    _matchedLeft.clear();
    _matchedRight.clear();
    _mistakeLetters.clear();
    _done = false;
  }

  void _tapLeft(int i) {
    if (_matchedLeft.contains(i) || _done) return;
    setState(() => _selectedLeft = _selectedLeft == i ? null : i);
  }

  void _tapRight(int j) {
    if (_matchedRight.contains(j) || _done || _selectedLeft == null) return;
    final li = _selectedLeft!;
    final isMatch = _left[li] == _right[j];

    if (isMatch) {
      setState(() {
        _matchedLeft.add(li);
        _matchedRight.add(j);
        _selectedLeft = null;
      });
      if (_matchedLeft.length == _left.length) _finish();
    } else {
      _mistakeLetters.add(_left[li]);
      setState(() {
        _wrongLeft = li;
        _wrongRight = j;
        _selectedLeft = null;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _wrongLeft = -1;
            _wrongRight = -1;
          });
        }
      });
    }
  }

  Future<void> _finish() async {
    final score = _left.where((l) => !_mistakeLetters.contains(l)).length;
    await TaskProgressService().saveAttempt(
      TaskAttempt(
        taskType: _taskType,
        grade: widget.gradeLevel,
        language: widget.isEnglish ? 'english' : 'sinhala',
        score: score,
        total: _left.length,
        completedAt: DateTime.now(),
        items: _left
            .map(
              (l) => TaskItemResult(
                itemId: l,
                isCorrect: !_mistakeLetters.contains(l),
              ),
            )
            .toList(),
      ),
    );
    if (mounted) setState(() => _done = true);
  }

  void _retry() => setState(_generateRound);

  int get _perfectCount =>
      _left.where((l) => !_mistakeLetters.contains(l)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSi ? '🔗 අකුරු ගලපමු' : '🔗 Letter Matching',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: _done ? _buildResults() : _buildGame(),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildProgressBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            _isSi ? 'එකම අකුර යා කරන්න!' : 'Tap a letter, then tap its match!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _buildColumn(_left, isLeft: true)),
                const SizedBox(width: 24),
                Expanded(child: _buildColumn(_right, isLeft: false)),
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
                '${_isSi ? "ගැලපුම්" : "Matched"}: ${_matchedLeft.length}/${_left.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_mistakeLetters.isNotEmpty)
                Text(
                  '${_isSi ? "වැරදි" : "Mistakes"}: ${_mistakeLetters.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _left.isEmpty ? 0 : _matchedLeft.length / _left.length,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(List<String> items, {required bool isLeft}) {
    return Column(
      children: List.generate(items.length, (i) {
        final matched = (isLeft ? _matchedLeft : _matchedRight).contains(i);
        final selected = isLeft && _selectedLeft == i;
        final wrong = isLeft ? _wrongLeft == i : _wrongRight == i;

        Color bg = Colors.white;
        Color border = Colors.grey.shade200;
        Color textColor = Colors.black87;
        if (matched) {
          bg = Colors.green.shade50;
          border = Colors.green;
          textColor = Colors.green.shade700;
        } else if (wrong) {
          bg = Colors.red.shade50;
          border = Colors.red;
          textColor = Colors.red.shade700;
        } else if (selected) {
          bg = _accent.withValues(alpha: 0.1);
          border = _accent;
          textColor = _accent;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BouncyTap(
            onTap: matched ? () {} : () => isLeft ? _tapLeft(i) : _tapRight(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: matched
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: textColor,
                        size: 26,
                      )
                    : Text(
                        items[i],
                        style: widget.isEnglish
                            ? TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              )
                            : GoogleFonts.notoSansSinhala(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResults() {
    final pct = _left.isEmpty
        ? 0
        : (_perfectCount / _left.length * 100).round();
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
                  '${_isSi ? "නිවැරදිව ගැලපු" : "Perfect matches"}: $_perfectCount/${_left.length}',
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
