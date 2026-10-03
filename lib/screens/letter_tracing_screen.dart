// lib/screens/letter_tracing_screen.dart
// Grade 1 — Letter Tracing Module. Correctness is primarily judged by coverage
// and similarity to the displayed guide. The on-device TFLite classifier is
// supporting evidence rather than a hard gate because its training domain is
// isolated handwriting, not children's guided tracing.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_attempt.dart';
import '../services/letter_classifier_service.dart';
import '../services/sinhala_letter_label_map.dart';
import '../services/task_progress_service.dart';
import '../services/trace_similarity_service.dart';
import '../utils/app_colors.dart';
import 'learning/models/grade_content.dart';

// ── Letter data ────────────────────────────────────────────────────────────────

class _LetterDef {
  final String letter;
  final String sound;
  final String exampleWord;
  final String emoji;

  const _LetterDef({
    required this.letter,
    required this.sound,
    required this.exampleWord,
    required this.emoji,
  });
}

class _TraceCheckResult {
  final double shapeSimilarity;
  final LetterPrediction? prediction;

  const _TraceCheckResult({
    required this.shapeSimilarity,
    required this.prediction,
  });
}

class TracePracticeTarget {
  final String letter;
  final String sound;
  final String exampleWord;
  final String emoji;

  const TracePracticeTarget({
    required this.letter,
    required this.sound,
    required this.exampleWord,
    this.emoji = '✍️',
  });
}

// ── Painter ────────────────────────────────────────────────────────────────────

double _traceGlyphScale(String letter) => letter.runes.length > 1 ? 0.48 : 0.68;

class _GuidePainter extends CustomPainter {
  final String letter;
  final bool showGuide;

  _GuidePainter(this.letter, {this.showGuide = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGuide) return;

    // Sinhala syllables such as "කා" contain a base character plus a vowel
    // sign and need extra horizontal/vertical breathing room compared with a
    // single letter. Keeping the whole guide visible is essential for useful
    // quick practice and a fair shape comparison.
    // Render the real Sinhala glyph as the writing guide. The old guide used
    // approximate straight-line polygons, which could teach an incorrect
    // letter shape. This guide is visual only and is never sent to the model.
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: GoogleFonts.notoSansSinhala(
          fontSize: size.shortestSide * _traceGlyphScale(letter),
          fontWeight: FontWeight.w600,
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.9);

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.showGuide != showGuide || old.letter != letter;
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => old.strokes != strokes;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class LetterTracingScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool useEnglishLetters;
  final String? initialLetter;
  final List<TracePracticeTarget>? practiceTargets;

  const LetterTracingScreen({
    super.key,
    required this.selectedLanguage,
    this.useEnglishLetters = false,
    this.initialLetter,
    this.practiceTargets,
  });

  @override
  State<LetterTracingScreen> createState() => _LetterTracingScreenState();
}

class _LetterTracingScreenState extends State<LetterTracingScreen> {
  bool get _isSi => widget.selectedLanguage == 'sinhala';
  late final List<_LetterDef> _letters;
  bool get _isEnglishPractice =>
      widget.useEnglishLetters && widget.practiceTargets == null;
  String get _practiceLanguage => _isEnglishPractice ? 'english' : 'sinhala';

  int _letterIdx = 0;
  _LetterDef get _current => _letters[_letterIdx];
  bool get _currentSupportsRecognition => SinhalaLetterLabelMap
      .supportedClassIdToUnicode
      .values
      .contains(_current.letter);

  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Size? _strokeCanvasSize;

  // Minimum classifier confidence to count a predicted-label match as
  // actually "correct" — a match at, say, 12% confidence isn't a real verdict.
  static const _confidenceThreshold = 0.5;
  static const _shapeSimilarityThreshold = 0.75;

  double _score = 0; // 0-100, shown in the score bar
  bool _passed = false; // the actual correctness verdict — see _onCheckTap
  bool _showResult = false;
  bool _showGuide = true;

  final _drawingLayerKey = GlobalKey();
  final _classifierService = LetterClassifierService();
  LetterPrediction? _classification;
  bool _modelLoading = true;
  bool _classifying = false;
  String? _recognitionError;

  @override
  void initState() {
    super.initState();
    _letters = _buildPracticeLetters();
    final requestedIndex = widget.initialLetter == null
        ? -1
        : _letters.indexWhere((item) => item.letter == widget.initialLetter);
    if (requestedIndex >= 0) _letterIdx = requestedIndex;
    _loadClassifier();
  }

  List<_LetterDef> _buildPracticeLetters() {
    final custom = widget.practiceTargets;
    if (custom != null && custom.isNotEmpty) {
      return custom
          .map(
            (item) => _LetterDef(
              letter: item.letter,
              sound: item.sound,
              exampleWord: item.exampleWord,
              emoji: item.emoji,
            ),
          )
          .toList(growable: false);
    }
    final source = widget.useEnglishLetters
        ? Grade1Content.englishLetters
        : Grade1Content.sinhalaLetters;
    return source
        .map(
          (item) => _LetterDef(
            letter: item.letter,
            sound: item.sound,
            exampleWord: item.exampleWord,
            emoji: item.emoji,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _loadClassifier() async {
    if (!_letters.any(
      (item) => SinhalaLetterLabelMap.supportedClassIdToUnicode.values.contains(
        item.letter,
      ),
    )) {
      if (mounted) setState(() => _modelLoading = false);
      return;
    }
    try {
      await _classifierService.loadModel();
      if (mounted) setState(() => _modelLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modelLoading = false;
        _recognitionError = _isSi
            ? 'ස්වයංක්‍රීය අකුරු හඳුනාගැනීම දැන් නොමැත. උත්සාහය ලකුණු නොකෙරේ.'
            : 'Automatic letter recognition is unavailable. This attempt will not be scored.';
      });
    }
  }

  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }

  void _clearCanvas() => setState(() {
    _strokes.clear();
    _currentStroke = [];
    _strokeCanvasSize = null;
    _score = 0;
    _passed = false;
    _showResult = false;
    _classification = null;
    _classifying = false;
    _recognitionError = null;
  });

  void _undoLastStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      if (_strokes.isEmpty) _strokeCanvasSize = null;
      _score = 0;
      _passed = false;
      _showResult = false;
      _classification = null;
      _recognitionError = null;
    });
  }

  void _nextLetter() {
    setState(() {
      _letterIdx = (_letterIdx + 1) % _letters.length;
      _clearCanvas();
    });
  }

  void _prevLetter() {
    setState(() {
      _letterIdx = (_letterIdx - 1 + _letters.length) % _letters.length;
      _clearCanvas();
    });
  }

  Future<void> _showLetterPicker() async {
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSi ? 'පුහුණු අකුර තෝරන්න' : 'Choose a letter',
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _isSi
                              ? 'පුහුණු අයිතම ${_letters.length}ම මෙහි ඇත'
                              : _isEnglishPractice
                              ? 'All ${_letters.length} Grade 1 English letters'
                              : 'All ${_letters.length} Sinhala practice items',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: _isSi ? 'වසන්න' : 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 76,
                ),
                itemCount: _letters.length,
                itemBuilder: (context, index) {
                  final item = _letters[index];
                  final selected = index == _letterIdx;
                  final canCheck = SinhalaLetterLabelMap
                      .supportedClassIdToUnicode
                      .values
                      .contains(item.letter);
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: _isSi
                        ? '${item.letter}, ${item.exampleWord}'
                        : '${item.letter}, ${item.sound}, ${item.exampleWord}',
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext, index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primarySoft.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.letter,
                                    style: GoogleFonts.notoSansSinhala(
                                      fontSize: 28,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.emoji} ${item.exampleWord}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSansSinhala(
                                      fontSize: 8,
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canCheck)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedIndex == null || !mounted || selectedIndex == _letterIdx) {
      return;
    }
    setState(() => _letterIdx = selectedIndex);
    _clearCanvas();
  }

  /// Measures shape similarity for every Grade 1 letter. When the 455-class
  /// CNN has a verified class for the selected letter, its identity verdict is
  /// also required; CNN confidence is never mislabeled as visual similarity.
  Future<void> _onCheckTap() async {
    if (_currentSupportsRecognition && _modelLoading) {
      setState(() {
        _recognitionError = _isSi
            ? 'අකුරු හඳුනාගැනීම තවම පූරණය වෙමින් පවතී. මොහොතකින් නැවත උත්සාහ කරන්න.'
            : 'Letter recognition is still loading. Please try again shortly.';
      });
      return;
    }

    final check = await _runTraceCheck();
    if (check == null) {
      if (!mounted) return;
      setState(() {
        _score = 0;
        _passed = false;
        _showResult = false;
        _recognitionError = _isSi
            ? 'අකුරේ හැඩය පරීක්ෂා කිරීමට නොහැකි වුණා. නැවත උත්සාහ කරන්න.'
            : 'The letter shape could not be checked. Please try again.';
      });
      return;
    }

    final prediction = check.prediction;
    final cnnMatches =
        prediction?.matchesExpected(
          _current.letter,
          minimumConfidence: _confidenceThreshold,
        ) ??
        false;
    // Only a verified Unicode class (or the explicit Unknown class) is usable
    // identity evidence. Most of the source model's 454 numeric classes are
    // intentionally not mapped in the app. Treating one of those unmapped
    // classes as a proven different letter was the cause of correctly traced
    // letters being forced to 0%. Unmapped output therefore falls back to the
    // strict guide-shape checker; it is not silently called a correct CNN
    // prediction.
    final hasComparableCnnIdentity =
        prediction != null && (prediction.isSupported || prediction.isUnknown);
    final shapeSimilarity = check.shapeSimilarity.clamp(0.0, 1.0);
    final displayedSimilarity =
        TraceSimilarityService.credibleDisplaySimilarity(shapeSimilarity);
    final passed = TraceSimilarityService.passesVerification(
      shapeSimilarity: shapeSimilarity,
      identityCheckRequired:
          _currentSupportsRecognition && hasComparableCnnIdentity,
      identityMatches: cnnMatches,
    );
    setState(() {
      _classification = prediction;
      // Weak overlap is not a credible letter match and is shown as zero.
      // Strong visual similarity remains visible even if the CNN disagrees.
      _score = displayedSimilarity * 100;
      _passed = passed;
      _showResult = true;
      _recognitionError = _currentSupportsRecognition && prediction == null
          ? (_isSi
                ? 'CNN හඳුනාගැනීම නොලැබුණු නිසා හැඩ සමානතාව පමණක් පෙන්වයි.'
                : 'CNN recognition was unavailable, so only shape similarity is shown.')
          : null;
    });
    await _saveAttempt(passed);
  }

  /// Persists this Check tap as a 1-item TaskAttempt, using the same
  /// [passed] verdict just shown in the score bar — the UI and the saved
  /// history can never disagree about whether this attempt was correct.
  Future<void> _saveAttempt(bool passed) async {
    await TaskProgressService().saveAttempt(
      TaskAttempt(
        taskType: 'letter_tracing',
        grade: 1,
        language: _practiceLanguage,
        score: passed ? 1 : 0,
        total: 1,
        completedAt: DateTime.now(),
        items: [
          TaskItemResult(
            itemId: _current.letter,
            isCorrect: passed,
            confidence: _classification?.confidence,
            shapeSimilarity: _score / 100,
            predictedLabel: _classification?.label,
            predictionClassId: _classification?.classId,
            predictionOutputIndex: _classification?.outputIndex,
            inferenceMilliseconds:
                _classifierService.lastInferenceDuration == null
                ? null
                : _classifierService.lastInferenceDuration!.inMicroseconds /
                      1000.0,
            modelVersion: _classification == null
                ? TraceSimilarityService.version
                : '${LetterClassifierService.modelVersion}+${TraceSimilarityService.version}',
          ),
        ],
      ),
    );
  }

  /// Captures the learner ink once, computes a standard-glyph shape score for
  /// every letter, and optionally asks the CNN for an identity prediction.
  Future<_TraceCheckResult?> _runTraceCheck() async {
    setState(() {
      _classifying = true;
      _classification = null;
      _recognitionError = null;
    });
    try {
      final drawingBox =
          _drawingLayerKey.currentContext!.findRenderObject() as RenderBox;
      // Keep the coordinate system from the moment the first stroke began.
      // Result/status widgets may alter layout later, but rechecking the same
      // untouched ink must always compare against the same standard position.
      final evaluationSize = _strokeCanvasSize ?? drawingBox.size;
      final width = evaluationSize.width.ceil();
      final height = evaluationSize.height.ceil();
      if (width <= 0 || height <= 0) return null;

      final strokeSnapshot = [
        for (final stroke in _strokes) List<Offset>.from(stroke),
        if (_currentStroke.isNotEmpty) List<Offset>.from(_currentStroke),
      ];
      if (TraceSimilarityService.isLikelyScribble(strokeSnapshot)) {
        return const _TraceCheckResult(shapeSimilarity: 0, prediction: null);
      }

      // Render directly from the learner's recorded points. Capturing a
      // transparent repaint boundary can be compositor-dependent and may
      // accidentally include a previously painted guide layer. Off-screen
      // rendering guarantees that guide visibility cannot change inference.
      final strokesImage = await _renderLearnerInk(width, height);
      try {
        final standardImage = await _renderStandardGlyph(
          strokesImage.width,
          strokesImage.height,
        );
        final learnerRgba = await strokesImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final standardRgba = await standardImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        standardImage.dispose();
        if (learnerRgba == null || standardRgba == null) return null;

        final shapeSimilarity = TraceSimilarityService.compareRgba(
          learnerRgba: learnerRgba.buffer.asUint8List(),
          standardRgba: standardRgba.buffer.asUint8List(),
          width: strokesImage.width,
          height: strokesImage.height,
        );

        LetterPrediction? prediction;
        if (_currentSupportsRecognition && _classifierService.isLoaded) {
          // Preserve the transparent drawing layer. The classifier converts
          // its alpha mask to the white-ink-on-black convention used by the
          // training dataset.
          final png = await strokesImage.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png != null) {
            try {
              prediction = await _classifierService.predict(
                png.buffer.asUint8List(),
              );
            } catch (_) {
              prediction = null;
            }
          }
        }

        return _TraceCheckResult(
          shapeSimilarity: shapeSimilarity,
          prediction: prediction,
        );
      } finally {
        strokesImage.dispose();
      }
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _classifying = false);
    }
  }

  Future<ui.Image> _renderLearnerInk(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final strokeSnapshot = [
      for (final stroke in _strokes) List<Offset>.from(stroke),
      if (_currentStroke.isNotEmpty) List<Offset>.from(_currentStroke),
    ];
    _StrokePainter(
      strokeSnapshot,
    ).paint(canvas, Size(width.toDouble(), height.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  Future<ui.Image> _renderStandardGlyph(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    final textPainter = TextPainter(
      text: TextSpan(
        text: _current.letter,
        style: GoogleFonts.notoSansSinhala(
          // This must match _GuidePainter exactly. Otherwise a child can
          // trace the visible combined glyph correctly while the checker
          // compares it with a larger hidden glyph and reports zero.
          fontSize: size.shortestSide * _traceGlyphScale(_current.letter),
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.9);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSi ? 'අකුරු ලියමු' : 'Letter Tracing',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _isSi
                  ? 'බලාගෙන • ලියන්න • පරීක්ෂා කරන්න'
                  : 'Look • Write • Check',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildLetterNav(),
            _buildInfoRow(),
            Expanded(child: _buildCanvas()),
            _buildControls(),
            Visibility(
              visible: _showResult,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _buildScoreBar(),
            ),
            if (_modelLoading || _recognitionError != null)
              _buildRecognitionStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildLetterNavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: _isSi ? 'පෙර අකුර' : 'Previous letter',
                onTap: _prevLetter,
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: _isSi
                      ? 'වෙනත් අකුරක් තෝරන්න'
                      : 'Choose another letter',
                  child: InkWell(
                    onTap: _showLetterPicker,
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Column(
                        key: ValueKey(_current.letter),
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _current.letter,
                                style: GoogleFonts.notoSansSinhala(
                                  fontSize: 54,
                                  height: 1.05,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          Text(
                            _isSi
                                ? 'අද ලියන අකුර  •  ${_current.emoji} ${_current.exampleWord}'
                                : '${_current.sound}  •  ${_current.emoji} ${_current.exampleWord}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildLetterNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                tooltip: _isSi ? 'ඊළඟ අකුර' : 'Next letter',
                onTap: _nextLetter,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '${_letterIdx + 1} / ${_letters.length}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_letterIdx + 1) / _letters.length,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          minimumSize: const Size.square(44),
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gesture_rounded,
              size: 21,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSi
                  ? 'ලා පැහැති අකුර උඩින් ඇඟිල්ලෙන් ලියන්න'
                  : 'Trace over the light letter with your finger',
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showGuide = !_showGuide),
            tooltip: _showGuide
                ? (_isSi ? 'අකුර සඟවන්න' : 'Hide guide')
                : (_isSi ? 'අකුර පෙන්වන්න' : 'Show guide'),
            icon: Icon(
              _showGuide
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            color: _showGuide ? AppColors.primary : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _GridPainter()),
            CustomPaint(
              painter: _GuidePainter(_current.letter, showGuide: _showGuide),
            ),
            // Only the learner's ink is captured for CNN inference. The real
            // glyph guide and the grid remain outside this boundary.
            RepaintBoundary(
              key: _drawingLayerKey,
              child: CustomPaint(
                painter: _StrokePainter([
                  ..._strokes,
                  if (_currentStroke.isNotEmpty) _currentStroke,
                ]),
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: _isSi
                    ? '${_current.letter} අකුර ලියන ප්‍රදේශය'
                    : 'Drawing area for the letter ${_current.letter}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    final drawingBox =
                        _drawingLayerKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    _strokeCanvasSize ??= drawingBox?.size;
                    _currentStroke = [details.localPosition];
                    setState(() {});
                  },
                  onPanUpdate: (details) {
                    _currentStroke.add(details.localPosition);
                    setState(() {});
                  },
                  onPanEnd: (_) {
                    if (_currentStroke.isNotEmpty) {
                      _strokes.add(List<Offset>.from(_currentStroke));
                    }
                    _currentStroke = [];
                    setState(() {});
                  },
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentSupportsRecognition
                            ? Icons.verified_rounded
                            : Icons.compare_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _currentSupportsRecognition
                            ? (_isSi
                                  ? 'CNN + හැඩ පරීක්ෂාව'
                                  : 'CNN + shape check')
                            : (_isSi ? 'හැඩ සමානතාව' : 'Shape similarity'),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_strokes.isEmpty && _currentStroke.isEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _isSi ? '☝️ මෙතැනින් ලියන්න' : '☝️ Start writing here',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final checkDisabled =
        _strokes.isEmpty ||
        _classifying ||
        (_currentSupportsRecognition && _modelLoading);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          _buildSmallControl(
            icon: Icons.undo_rounded,
            label: _isSi ? 'ආපසු' : 'Undo',
            onTap: _strokes.isEmpty ? null : _undoLastStroke,
          ),
          const SizedBox(width: 8),
          _buildSmallControl(
            icon: Icons.delete_outline_rounded,
            label: _isSi ? 'මකන්න' : 'Clear',
            onTap: _strokes.isEmpty ? null : _clearCanvas,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: checkDisabled ? null : _onCheckTap,
              icon: _classifying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _classifying
                    ? (_isSi ? 'බලමින්...' : 'Checking...')
                    : (_isSi ? 'හරිද බලන්න' : 'Check my letter'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallControl({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 66,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: _passed ? Colors.green[50] : Colors.orange[50],
      child: Row(
        children: [
          Text(_passed ? '🌟' : '💪', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _passed
                      ? (_isSi ? 'ශ්‍රේෂ්ඨ ලෙස ලිව්වා!' : 'Well traced!')
                      : (_isSi ? 'නැවත උත්සාහ කරන්න!' : 'Keep practising!'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _passed ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  _isSi ? 'අකුරු ලිවීමේ ගුණාත්මකතාව' : 'Tracing quality',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (_classification case final prediction?)
                  Text(
                    _passed &&
                            prediction.matchesExpected(
                              _current.letter,
                              minimumConfidence: _confidenceThreshold,
                            )
                        ? (_isSi
                              ? 'AI අකුරු හඳුනාගැනීමත් තහවුරු වුණා'
                              : 'AI letter recognition also confirmed')
                        : (_passed && !prediction.isSupported
                              ? (_isSi
                                    ? 'හැඩය තහවුරු වුණා; AI පන්තිය තවම සිංහල අකුරකට සිතියම් කර නැහැ'
                                    : 'Shape verified; this AI class is not yet mapped to a Sinhala letter')
                              : (_currentSupportsRecognition &&
                                        !prediction.isUnknown &&
                                        prediction.unicodeLetter !=
                                            _current.letter
                                    ? (_isSi
                                          ? 'AI එක මෙය වෙනත් අකුරක් ලෙස හඳුනාගත්තා'
                                          : 'AI recognised this as a different letter')
                                    : (_score == 0
                                          ? (_isSi
                                                ? 'සම්පූර්ණ අකුර මත පමණක් ලියන්න; අහඹු රේඛා පිළිගන්නේ නැහැ'
                                                : 'Trace the complete letter; random lines are not accepted')
                                          : (_score >=
                                                    _shapeSimilarityThreshold *
                                                        100
                                                ? (_isSi
                                                      ? 'හැඩය ගැළපුණත් AI එක වෙනත් අකුරක් ලෙස හඳුනාගත්තා'
                                                      : 'Shape is close, but AI recognised a different letter')
                                                : (_isSi
                                                      ? 'අකුරු හැඩය සම්මත හැඩයට තවත් ළං කරන්න'
                                                      : 'Trace closer to the standard letter shape'))))),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    _isSi
                        ? 'සම්මත අකුරු හැඩය සමඟ සසඳා ඇත'
                        : 'Compared with the standard glyph shape',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _score / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _passed ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_score.toInt()}%',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _passed ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionStatus() {
    if (_modelLoading || _classifying) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.grey[100],
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              _isSi
                  ? (_modelLoading
                        ? 'උපාංගයේ අකුරු මාදිලිය පූරණය වෙමින්...'
                        : 'සම්මත අකුරු හැඩය සමඟ සසඳමින්...')
                  : (_modelLoading
                        ? 'Loading the on-device letter model...'
                        : 'Comparing with the standard letter shape...'),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    final error = _recognitionError;
    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.amber[50],
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[900],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final prediction = _classification!;
    final predictedLetter = prediction.unicodeLetter;
    final cnnMatches = prediction.matchesExpected(
      _current.letter,
      minimumConfidence: _confidenceThreshold,
    );
    final message = _passed && cnnMatches
        ? (_isSi
              ? 'AI එක "${prediction.label}" ලෙස තහවුරු කළා — විශ්වාසය ${(prediction.confidence * 100).toInt()}%'
              : 'AI confirmed "${prediction.label}" — ${(prediction.confidence * 100).toInt()}% model confidence')
        : _passed
        ? (_isSi
              ? 'සම්මත මාර්ගෝපදේශයට ගැළපෙන අකුරු හැඩය තහවුරු වුණා; AI පන්තිය ${prediction.classId} තවම සිතියම් කර නැහැ.'
              : 'The letter shape matches the guide; AI class ${prediction.classId} is not yet mapped.')
        : predictedLetter == null
        ? (_isSi
              ? 'මාදිලිය සහාය නොදක්වන පන්තිය ${prediction.classId} ලබා දුන්නා; මෙය "${_current.letter}" ලෙස පිළිගත්තේ නැහැ.'
              : 'The model returned unsupported class ${prediction.classId}; it was not accepted as "${_current.letter}".')
        : (_isSi
              ? 'මාදිලිය "$predictedLetter" (පන්තිය ${prediction.classId}) ලෙස හඳුනාගත්තා, "${_current.letter}" නොවේ.'
              : 'Recognised "$predictedLetter" (class ${prediction.classId}), not "${_current.letter}".');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: _passed ? Colors.green[50] : Colors.red[50],
      child: Row(
        children: [
          Icon(
            _passed ? Icons.verified_rounded : Icons.center_focus_weak_rounded,
            color: _passed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _passed ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dotted grid background ─────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withValues(alpha: 0.15);
    const spacing = 30.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
