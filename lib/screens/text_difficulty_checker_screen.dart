import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/text_difficulty_classifier.dart';
import '../utils/app_colors.dart';

/// Teacher-facing demonstration and review tool for the Grade 1/2 text model.
/// Results are advisory and never overwrite a story's authored grade.
class TextDifficultyCheckerScreen extends StatefulWidget {
  final String selectedLanguage;

  const TextDifficultyCheckerScreen({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<TextDifficultyCheckerScreen> createState() =>
      _TextDifficultyCheckerScreenState();
}

class _TextDifficultyCheckerScreenState
    extends State<TextDifficultyCheckerScreen> {
  final _controller = TextEditingController();
  final _classifier = TextDifficultyClassifier();
  TextDifficultyResult? _result;

  bool get _isSi => widget.selectedLanguage == 'sinhala';
  String _copy(String en, String si) => _isSi ? si : en;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyse() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Enter a reading passage first.',
              'පළමුව කියවීමේ පාඨයක් ඇතුළත් කරන්න.',
            ),
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _result = _classifier.analyze(text));
  }

  void _loadSample(int grade) {
    _controller.text = grade == 1
        ? _copy(
            'I see a red cat. The cat can run.',
            'අම්මා ගෙදර යයි. මම පොත බලමි.',
          )
        : _copy(
            'The little children walked through the beautiful garden and carefully observed the colourful butterflies near the flowers.',
            'කුඩා දරුවන් උදෑසන පාසල් වත්තට ගොස් එහි තිබූ විවිධ ශාක සහ වර්ණවත් මල් පිළිබඳව අවධානයෙන් නිරීක්ෂණය කළහ.',
          );
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          _copy('Text Difficulty Checker', 'පාඨ අපහසුතා පරීක්ෂකය'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            _introCard(),
            const SizedBox(height: 16),
            _inputCard(),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _resultCard(_result!),
            ],
            const SizedBox(height: 16),
            _evidenceNotice(),
          ],
        ),
      ),
    );
  }

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF5B45F5), Color(0xFF7D5CF7)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.22),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _copy('Check reading level', 'කියවීමේ මට්ටම පරීක්ෂා කරන්න'),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _copy(
                  'Paste a passage to estimate whether it is closer to Grade 1 or Grade 2.',
                  'පාඨයක් ඇතුළත් කර එය 1 හෝ 2 ශ්‍රේණියට වඩාත් ගැළපේදැයි බලන්න.',
                ),
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _inputCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E2FA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _copy('Reading passage', 'කියවීමේ පාඨය'),
          style: GoogleFonts.poppins(
            color: const Color(0xFF252842),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          minLines: 6,
          maxLines: 10,
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            hintText: _copy(
              'Type or paste the text here...',
              'පාඨය මෙහි ලියන්න හෝ paste කරන්න...',
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _loadSample(1),
                icon: const Icon(Icons.looks_one_rounded, size: 18),
                label: Text(_copy('Grade 1 sample', '1 ශ්‍රේණියේ උදාහරණය')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _loadSample(2),
                icon: const Icon(Icons.looks_two_rounded, size: 18),
                label: Text(_copy('Grade 2 sample', '2 ශ්‍රේණියේ උදාහරණය')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _analyse,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.analytics_rounded),
            label: Text(
              _copy('Analyse text', 'පාඨය විශ්ලේෂණය කරන්න'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _resultCard(TextDifficultyResult result) {
    final grade = result.predictedGrade;
    final colour = grade == 1
        ? const Color(0xFF13AAA2)
        : const Color(0xFFFF8A3D);
    final probability = (result.predictedGradeProbability * 100)
        .clamp(0, 100)
        .toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: colour,
                child: Text(
                  '$grade',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy('Estimated level', 'ඇස්තමේන්තුගත මට්ටම'),
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      _copy('Grade $grade', '$grade ශ්‍රේණිය'),
                      style: GoogleFonts.poppins(
                        color: colour,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                backgroundColor: Colors.white,
                label: Text(
                  '$probability%',
                  style: GoogleFonts.poppins(
                    color: colour,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _metric('${result.wordCount}', _copy('Words', 'වචන')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  result.averageWordLength.toStringAsFixed(1),
                  _copy('Avg. word', 'සා. වචනය'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  result.averageSentenceLength.toStringAsFixed(1),
                  _copy('Avg. sentence', 'සා. වාක්‍යය'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _evidenceNotice() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7DF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFDEA0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.fact_check_outlined, color: Color(0xFFE88B00)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _copy(
              'Advisory only: this proof-of-concept was trained on 26 texts and achieved 69.2% training accuracy. A teacher must review the final level.',
              'මෙය උපදේශාත්මක ප්‍රතිඵලයක් පමණි. පාඨ 26කින් පුහුණු කළ model එකේ training accuracy 69.2%කි. අවසාන මට්ටම ගුරුවරයෙකු පරීක්ෂා කළ යුතුය.',
            ),
            style: GoogleFonts.poppins(
              color: const Color(0xFF7B5700),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
