// lib/screens/learning/widgets/letter_detail_screen.dart
// Grade 1 — see a letter and learn words that begin with it.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grade_content.dart';
import '../../../utils/app_colors.dart';

class LetterDetailScreen extends StatelessWidget {
  final LetterItem letter;
  final String selectedLanguage;
  final bool isEnglish;
  final Color accentColor;

  const LetterDetailScreen({
    super.key,
    required this.letter,
    required this.selectedLanguage,
    required this.isEnglish,
    required this.accentColor,
  });

  bool get _isSi => selectedLanguage == 'sinhala';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSi ? 'අකුර ඉගෙනගනිමු 🌟' : 'Learn This Letter 🌟',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildLetterCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              _isSi ? '⭐ මෙම අකුරට වචනය' : '⭐ Word for this letter',
            ),
            const SizedBox(height: 12),
            _buildWordCard(),
            if (letter.moreWords.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildSectionTitle(
                _isSi
                    ? '🎉 තවත් වචන ${letter.moreWords.length}ක්!'
                    : '🎉 ${letter.moreWords.length} more words!',
              ),
              const SizedBox(height: 12),
              _buildMoreWordsGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildLetterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            letter.letter,
            style: isEnglish
                ? const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : GoogleFonts.notoSansSinhala(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${letter.sound}"',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard() {
    final hasGloss = letter.exampleWordEn.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(letter.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            letter.exampleWord,
            style: isEnglish
                ? TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  )
                : GoogleFonts.notoSansSinhala(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
          ),
          if (hasGloss) ...[
            const SizedBox(height: 4),
            Text(
              letter.exampleWordEn,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreWordsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: letter.moreWords.length,
      itemBuilder: (_, i) {
        final word = letter.moreWords[i];
        final color = AppColors.kidColorFor(i);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word,
                textAlign: TextAlign.center,
                style: isEnglish
                    ? TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: color,
                      )
                    : GoogleFonts.notoSansSinhala(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
