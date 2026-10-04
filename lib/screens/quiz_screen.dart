// lib/screens/quiz_screen.dart
// Grade-aware, rule-generated comprehension quiz — 5 question types

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/story.dart';
import '../models/quiz_attempt.dart';
import '../services/quiz_generation_service.dart';
import '../services/activity_service.dart';
import '../utils/app_colors.dart';

class QuizScreen extends StatefulWidget {
  final Story story;
  final String selectedLanguage;
  final int gradeLevel;

  const QuizScreen({
    super.key,
    required this.story,
    required this.selectedLanguage,
    required this.gradeLevel,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final _quizGenerator = QuizGenerationService();
  late List<QuizQuestion> _questions;
  int _current = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedOption;
  bool _done = false;

  final List<Map<String, dynamic>> _results = [];
  late AnimationController _progressCtrl;
  late AnimationController _feedbackCtrl;

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  static const _typeIcons = {
    'mcq': '🔘',
    'truefalse': '✅',
    'fill': '✏️',
    'sequence': '🔢',
    'short': '💬',
  };

  static const _typeLabels = {
    'mcq': 'Multiple Choice',
    'truefalse': 'True or False',
    'fill': 'Fill in the Blank',
    'sequence': 'Sequencing',
    'short': 'Short Answer',
  };

  @override
  void initState() {
    super.initState();
    _questions = _quizGenerator.generateQuiz(
      widget.story,
      count: 5,
      gradeLevel: widget.gradeLevel,
      depth: widget.gradeLevel >= 2
          ? QuestionDepth.inferential
          : QuestionDepth.literal,
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  QuizQuestion get _q => _questions[_current];

  void _select(String option) {
    if (_answered) return;
    final correct = option == _q.correctAnswer;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (correct) _score++;
      _results.add({
        'question': _q.question,
        'selected': option,
        'correct': _q.correctAnswer,
        'isCorrect': correct,
        'type': _q.type,
      });
    });
    _feedbackCtrl.forward(from: 0);
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _answered = false;
        _selectedOption = null;
      });
      _progressCtrl.forward(from: 0);
    } else {
      setState(() => _done = true);
      _saveAttempt();
    }
  }

  Future<void> _saveAttempt() async {
    await ActivityService().saveQuizAttempt(
      QuizAttempt(
        storyId: widget.story.id,
        score: _score,
        total: _questions.length,
        results: _results
            .map(
              (r) => QuizQuestionResult(
                type: r['type'] as String,
                isCorrect: r['isCorrect'] as bool,
              ),
            )
            .toList(),
        completedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSi ? '🧠 ප්‍රශ්නාවලිය' : '🧠 Comprehension Quiz',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
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
      body: _done ? _buildResults() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionCard(),
                const SizedBox(height: 20),
                if (_q.type == 'short')
                  _buildShortAnswerInput()
                else
                  _buildOptions(),
                if (_answered) ...[
                  const SizedBox(height: 16),
                  _buildFeedbackCard(),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
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
              Text(
                _isSi
                    ? 'ශ්‍රේ ${widget.gradeLevel}'
                    : 'Grade ${widget.gradeLevel}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
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

  Widget _buildQuestionCard() {
    final typeLabel = _typeLabels[_q.type] ?? _q.type;
    final typeIcon = _typeIcons[_q.type] ?? '❓';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$typeIcon $typeLabel',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Q${_current + 1}. ${_q.question}',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: _q.options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final isSelected = _selectedOption == opt;
        final isCorrect = _answered && opt == _q.correctAnswer;
        final isWrong = _answered && isSelected && !isCorrect;

        Color bg = Colors.white;
        Color border = Colors.grey.shade200;
        Color textColor = Colors.black87;
        Widget? trailing;

        if (isCorrect) {
          bg = Colors.green.shade50;
          border = Colors.green;
          textColor = Colors.green.shade800;
          trailing = const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
          );
        } else if (isWrong) {
          bg = Colors.red.shade50;
          border = Colors.red;
          textColor = Colors.red.shade800;
          trailing = const Icon(Icons.cancel_rounded, color: Colors.red);
        } else if (isSelected) {
          bg = AppColors.primary.withValues(alpha: 0.08);
          border = AppColors.primary;
          textColor = AppColors.primary;
        }

        return GestureDetector(
          onTap: () => _select(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  final TextEditingController _shortAnswerCtrl = TextEditingController();

  Widget _buildShortAnswerInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _shortAnswerCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              hintText: _isSi
                  ? 'ඔබේ පිළිතුර මෙහි ලියන්න...'
                  : 'Write your answer here...',
              hintStyle: GoogleFonts.poppins(color: Colors.black38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _select(
              _shortAnswerCtrl.text.isEmpty
                  ? _q.correctAnswer
                  : _shortAnswerCtrl.text,
            ),
            child: Text(
              _isSi ? 'පිළිතුර ඉදිරිපත් කරන්න' : 'Submit Answer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard() {
    final isCorrect =
        _selectedOption == _q.correctAnswer ||
        _q.type == 'short'; // short always counts
    return AnimatedBuilder(
      animation: _feedbackCtrl,
      builder: (_, _) => Transform.scale(
        scale: 0.8 + 0.2 * _feedbackCtrl.value,
        child: Opacity(
          opacity: _feedbackCtrl.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isCorrect ? '🎉' : '💡',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect
                          ? (_isSi
                                ? 'ශ්‍රේෂ්ඨ! නිවැරදියි!'
                                : 'Excellent! Correct!')
                          : (_isSi ? 'හොඳ උත්සාහයකි!' : 'Good try!'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCorrect
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                if (!isCorrect && _q.type != 'short') ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_isSi ? 'නිවැරදි පිළිතුර' : 'Correct answer'}: ${_q.correctAnswer}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _q.explanation,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
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
          backgroundColor: isLast ? Colors.green : AppColors.primary,
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
              : (_isSi ? 'ඊළඟ ප්‍රශ්නය →' : 'Next Question →'),
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
    final grade = pct >= 80
        ? (_isSi ? 'ශ්‍රේෂ්ඨ!' : 'Excellent!')
        : pct >= 60
        ? (_isSi ? 'හොඳයි!' : 'Good Job!')
        : (_isSi ? 'දිගටම ප්‍රයත්න කරන්න!' : 'Keep Practising!');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
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
                  grade,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_isSi ? 'නිවැරදි' : 'Correct'}: $_score/${_questions.length}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // AI Insight
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🤖', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSi
                            ? 'NenaPotha AI නිර්දේශය:'
                            : 'NenaPotha AI Insight:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _aiInsight(pct),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Per-question breakdown
          Text(
            _isSi ? '📋 ප්‍රශ්න සමාලෝචනය' : '📋 Question Review',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._results.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (r['isCorrect'] as bool)
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (r['isCorrect'] as bool) ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (r['isCorrect'] as bool) ? '✅' : '❌',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${i + 1}: ${(r['question'] as String).length > 60 ? '${(r['question'] as String).substring(0, 60)}...' : r['question']}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!(r['isCorrect'] as bool))
                          Text(
                            '✓ ${r['correct']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _isSi ? 'ආපසු' : 'Go Back',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _current = 0;
                      _score = 0;
                      _answered = false;
                      _selectedOption = null;
                      _done = false;
                      _results.clear();
                      _questions = _quizGenerator.generateQuiz(
                        widget.story,
                        count: 5,
                        gradeLevel: widget.gradeLevel,
                        depth: widget.gradeLevel >= 2
                            ? QuestionDepth.inferential
                            : QuestionDepth.literal,
                      );
                    });
                  },
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _aiInsight(int pct) {
    if (pct >= 85) {
      return _isSi
          ? 'ශ්‍රේෂ්ඨ කාර්යයි! ඔබ ඊළඟ ශ්‍රේණියේ කතාවකට සූදානම්! 🚀'
          : 'Outstanding! You\'re ready to try a higher level story! 🚀';
    } else if (pct >= 70) {
      return _isSi
          ? 'හොඳ ප්‍රගතියකි! ඒ සමාන කතා කිහිපයක් කියවා ඔබේ ලකුණු 90%+ ලෙස ගන්න!'
          : 'Good progress! Try a few more stories at this level to reach 90%+!';
    } else if (pct >= 50) {
      return _isSi
          ? 'ටිකක් අභ්‍යාස අවශ්‍යයි. Vocabulary cards බලන්න!'
          : 'A bit more practice needed. Try reviewing vocabulary cards!';
    } else {
      return _isSi
          ? 'පහසු කතාවකින් ආරම්භ කිරීම නිර්දේශ කරනවා. ඔබට හැකිය! 💪'
          : 'I recommend starting with an easier story. You can do it! 💪';
    }
  }
}
