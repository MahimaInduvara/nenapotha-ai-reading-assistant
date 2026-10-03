import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_session.dart';
import '../services/activity_service.dart';
import '../services/story_data_service.dart';
import '../utils/app_colors.dart';
import '../widgets/task_picture.dart';
import 'quiz_screen.dart';

class ReadingScreen extends StatefulWidget {
  final String storyId;
  final String titleSi;
  final String titleEn;
  final String contentSi;
  final String contentEn;
  final int gradeLevel;
  final String selectedLanguage;

  const ReadingScreen({
    super.key,
    required this.storyId,
    required this.titleSi,
    required this.titleEn,
    required this.contentSi,
    required this.contentEn,
    required this.gradeLevel,
    required this.selectedLanguage,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  // Grade 1 receives larger type and shorter pages than Grade 2.
  double get _fontSize => widget.gradeLevel == 1 ? 36 : 30;
  double get _lineHeight => widget.gradeLevel == 1 ? 1.75 : 1.85;

  // Page number
  int _currentPage = 0;
  late List<String> _contentPagesSi;
  late List<String> _contentPagesEn;

  // Rewards & Progress
  int _stars = 0;
  // Always 0: the points system was grade-3-only (grade 3 no longer exists
  // in this app) and nothing else awards it. Kept so ReadingSession.pointsEarned
  // still has a value to save, rather than removing the field from the model.
  final int _points = 0;
  int _helpRequests = 0;

  // Confetti animation
  bool _showConfetti = false;

  // Real activity tracking — persisted to Firestore when the story finishes
  // (see _showCompletionDialog / _saveReadingSession).
  late ReadingSession _session;
  bool _sessionSaved = false;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage == 'sinhala'
        ? 'sinhala'
        : 'english';
    _splitContentIntoPages();
    _session = ReadingSession(
      storyId: widget.storyId,
      titleEn: widget.titleEn,
      titleSi: widget.titleSi,
      gradeLevel: widget.gradeLevel,
      language: _currentLanguage,
      startTime: DateTime.now(),
    )..totalPages = _activePages.length;
  }

  late String _currentLanguage;

  bool get _isSi => _currentLanguage == 'sinhala';
  List<String> get _activePages => _isSi ? _contentPagesSi : _contentPagesEn;

  void _splitContentIntoPages() {
    // Grade 1: 2-3 simple sentences (~30-40 words) — letter/word recognition stage.
    // Grade 2: short paragraph (~50-70 words) — sentence -> paragraph stage.
    final charsPerPage = widget.gradeLevel == 1 ? 90 : 250;

    _contentPagesSi = _splitText(widget.contentSi, charsPerPage);
    _contentPagesEn = _splitText(widget.contentEn, charsPerPage);

    if (_contentPagesSi.isEmpty) _contentPagesSi = [widget.contentSi];
    if (_contentPagesEn.isEmpty) _contentPagesEn = [widget.contentEn];
  }

  List<String> _splitText(String text, int chars) {
    final words = text.trim().split(RegExp(r'\s+'));
    final pages = <String>[];
    final page = StringBuffer();

    for (final word in words) {
      if (word.isEmpty) continue;
      final nextLength = page.length + (page.isEmpty ? 0 : 1) + word.length;
      if (page.isNotEmpty && nextLength > chars) {
        pages.add(page.toString());
        page.clear();
      }
      if (page.isNotEmpty) page.write(' ');
      page.write(word);
    }

    if (page.isNotEmpty) pages.add(page.toString());
    return pages;
  }

  void _nextPage() {
    _session.pagesCompleted++;
    setState(() => _stars++);
    _triggerConfetti();

    if (_currentPage < _activePages.length - 1) {
      setState(() => _currentPage++);
    } else {
      _showCompletionDialog();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  Future<void> _saveReadingSession() async {
    if (_sessionSaved) return; // avoid a double-save if the dialog re-renders
    _sessionSaved = true;

    _session.endTime = DateTime.now();
    _session.helpRequestsCount = _helpRequests;
    _session.pointsEarned = _points;
    _session.starsEarned = _stars;

    try {
      await ActivityService().saveReadingSession(_session);
    } catch (_) {
      _sessionSaved = false; // allow a retry if this ever gets called again
    }
  }

  void _showCompletionDialog() {
    _saveReadingSession();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isSi ? '🎊 කතාව අවසන්!' : '🎊 Story Finished!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isSi
                  ? 'කතාව සම්පූර්ණ කළාට ඉතා හොඳයි!'
                  : 'Great job completing the story!',
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showComprehensionQuestions();
              },
              child: Text(_isSi ? 'ප්‍රශ්නාවලිය කරන්න' : 'Take Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComprehensionQuestions() {
    const qCount = 3;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isSi
              ? 'ප්‍රශ්නාවලිය! (ප්‍රශ්න $qCount)'
              : 'Quiz Time! ($qCount questions)',
        ),
        content: Text(
          _isSi
              ? 'කතාව ගැන ප්‍රශ්නවලට පිළිතුරු දෙන්න සූදානම්ද?'
              : 'Are you ready to answer some questions about the story?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isSi ? 'පසුව' : 'Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final story = StoryDataService.getStoryById(widget.storyId);
              if (story == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isSi
                          ? 'මේ කතාවේ ප්‍රශ්නාවලිය දැන් විවෘත කළ නොහැක.'
                          : 'The quiz for this story cannot be opened right now.',
                    ),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    story: story,
                    selectedLanguage: _currentLanguage,
                    gradeLevel: story.gradeLevel,
                  ),
                ),
              );
            },
            child: Text(_isSi ? 'ආරම්භ කරන්න' : 'Start'),
          ),
        ],
      ),
    );
  }

  void _triggerConfetti() {
    setState(() => _showConfetti = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  void _handleWordTap(String word) {
    _helpRequests++;
    final cleanWord = word.replaceAll(RegExp(r'[.,!?“”"‘’():;]'), '');
    final titleCaseWord = cleanWord.isEmpty
        ? cleanWord
        : '${cleanWord[0].toUpperCase()}${cleanWord.substring(1).toLowerCase()}';
    final pictureWord = TaskPicture.hasPicture(cleanWord)
        ? cleanWord
        : titleCaseWord;
    final storyEmoji =
        StoryDataService.getStoryById(widget.storyId)?.thumbnailUrl ?? '📖';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          word,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, color: Colors.purple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskPicture(word: pictureWord, fallbackEmoji: storyEmoji, size: 96),
            const SizedBox(height: 10),
            Text(
              _isSi
                  ? 'මෙම වචනය නැවත කියවා බලන්න: $cleanWord'
                  : 'Read this word again: $cleanWord',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isSi ? 'හරි!' : 'Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveText(String text) {
    List<String> words = text.split(' ');
    return Wrap(
      children: words.map((word) {
        return GestureDetector(
          onTap: () => _handleWordTap(word),
          child: Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(
              word,
              style: GoogleFonts.notoSansSinhala(
                fontSize: _fontSize,
                height: _lineHeight,
                color: Colors.grey[800],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLanguage == 'sinhala' ? widget.titleSi : widget.titleEn,
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentPage + 1) / _activePages.length,
                backgroundColor: Colors.grey[200],
                color: AppColors.primary,
                minHeight: 6,
              ),

              // Top Status Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSi
                          ? 'පිටුව ${_currentPage + 1}/${_activePages.length}'
                          : 'Page ${_currentPage + 1}/${_activePages.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        _stars,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple[100]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("🦉", style: TextStyle(fontSize: 30)),
                              SizedBox(width: 10),
                              Text(
                                _isSi
                                    ? 'උදව් සඳහා වචනයක් තට්ටු කරන්න!'
                                    : 'Tap any word for help!',
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      _buildInteractiveText(_activePages[_currentPage]),
                    ],
                  ),
                ),
              ),

              // Controls Bottom Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(_isSi ? 'පසුපස' : 'Back'),
                        ),
                        TextButton.icon(
                          onPressed: _nextPage,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(_isSi ? 'ඊළඟ' : 'Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_showConfetti)
            Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 1 + value,
                    child: Opacity(
                      opacity: 1 - value,
                      child: const Text('🎉', style: TextStyle(fontSize: 100)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
