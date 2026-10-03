import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/readbuddy_background.dart';
import '../parent_login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selected;
  bool _continuing = false;
  bool get _isSi => _selected == 'sinhala';

  Future<void> _continue() async {
    final language = _selected;
    if (language == null || _continuing) return;
    setState(() => _continuing = true);
    await StorageService().setLanguage(language);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ParentLoginScreen(selectedLanguage: language),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReadBuddyBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: ReadBuddyLogo(size: 70),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _isSi
                          ? 'ඔබේ ඉගෙනුම්\nභාෂාව තෝරන්න'
                          : 'Choose your\nlearning language',
                      style: _isSi
                          ? GoogleFonts.notoSansSinhala(
                              color: AppColors.textPrimary,
                              fontSize: 34,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            )
                          : Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isSi
                          ? 'යෙදුමේ සියලුම උපදෙස් සිංහලෙන් පෙන්වයි.'
                          : 'All app instructions will appear in English.',
                      style: _isSi
                          ? GoogleFonts.notoSansSinhala(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.5,
                            )
                          : GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                    ),
                    const SizedBox(height: 32),
                    _languageCard(
                      value: 'english',
                      flag: '🇬🇧',
                      title: 'English',
                      subtitle: 'Learn and read in English',
                      sample: 'Hello, little reader!',
                      accent: AppColors.blue,
                    ),
                    const SizedBox(height: 14),
                    _languageCard(
                      value: 'sinhala',
                      flag: '🇱🇰',
                      title: 'සිංහල',
                      subtitle: 'සිංහලෙන් කියවා ඉගෙන ගනිමු',
                      sample: 'ආයුබෝවන්, පුංචි පාඨකයා!',
                      accent: AppColors.coral,
                      sinhala: true,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _selected == null || _continuing
                          ? null
                          : _continue,
                      icon: _continuing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _selected == null
                            ? 'Select a language'
                            : (_isSi ? 'ඉදිරියට යන්න' : 'Continue'),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isSi
                          ? 'පසුව පැතිකඩෙන් භාෂාව වෙනස් කළ හැකිය.'
                          : 'You can change this later in Profile.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageCard({
    required String value,
    required String flag,
    required String title,
    required String subtitle,
    required String sample,
    required Color accent,
    bool sinhala = false,
  }) {
    final selected = _selected == value;
    final titleStyle = sinhala
        ? GoogleFonts.notoSansSinhala(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          )
        : GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          );
    return Semantics(
      selected: selected,
      button: true,
      label: '$title language',
      child: InkWell(
        onTap: () => setState(() => _selected = value),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(flag, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: sinhala
                          ? GoogleFonts.notoSansSinhala(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            )
                          : Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      sample,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (sinhala
                                  ? GoogleFonts.notoSansSinhala()
                                  : GoogleFonts.poppins())
                              .copyWith(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: accent,
                        size: 28,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('unselected'),
                        color: AppColors.border,
                        size: 28,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
