import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/sinhala_letter_label_map.dart';
import '../../services/trace_training_capture_service.dart';
import '../../utils/app_colors.dart';
import '../learning/models/grade_content.dart';

class _CaptureTarget {
  final String label;
  final String display;
  final String kind;
  final String help;
  final int? classId;

  const _CaptureTarget(
    this.label,
    this.display,
    this.kind,
    this.help, [
    this.classId,
  ]);
}

/// Collects real app-canvas traces for CNN domain adaptation. This screen is
/// reachable only from the debug-build Profile page.
class TraceTrainingCollectorScreen extends StatefulWidget {
  const TraceTrainingCollectorScreen({super.key});

  @override
  State<TraceTrainingCollectorScreen> createState() =>
      _TraceTrainingCollectorScreenState();
}

class _TraceTrainingCollectorScreenState
    extends State<TraceTrainingCollectorScreen> {
  static const _writerKey = 'trace_training_writer_id';
  static const _categories = ['base', 'combined', 'pillam', 'invalid'];

  final _service = TraceTrainingCaptureService();
  final _writer = TextEditingController(text: 'writer_01');
  final List<List<Offset>> _strokes = [];
  List<Offset> _activeStroke = [];

  late final Map<String, List<_CaptureTarget>> _targets = _makeTargets();
  String _category = 'base';
  int _targetIndex = 0;
  Size _canvasSize = Size.zero;
  Map<String, int> _counts = const {};
  String _folder = '';
  bool _loading = true;
  bool _saving = false;
  bool _consent = false;
  bool _showGuide = true;

  List<_CaptureTarget> get _categoryTargets => _targets[_category]!;
  _CaptureTarget get _target => _categoryTargets[_targetIndex];
  bool get _hasInk => _strokes.any((s) => s.length > 1);
  String get _targetKey =>
      TraceTrainingCaptureService.labelKey(_target.label, kind: _target.kind);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _writer.dispose();
    super.dispose();
  }

  Map<String, List<_CaptureTarget>> _makeTargets() {
    final classFor = <String, int>{
      for (final e in SinhalaLetterLabelMap.supportedClassIdToUnicode.entries)
        e.value: e.key,
    };
    final pillam = Grade2Content.pillam
        .where((item) => item.category == 'core')
        .toList(growable: false);
    return {
      'base': Grade1Content.sinhalaLetters
          .map(
            (item) => _CaptureTarget(
              item.letter,
              item.letter,
              'base',
              'Trace the correct base letter',
              classFor[item.letter],
            ),
          )
          .toList(growable: false),
      'combined': pillam
          .map((item) {
            final label = 'ක${item.pillam}';
            return _CaptureTarget(
              label,
              label,
              'combined',
              '${item.nameSi} • trace the whole letter',
              classFor[label],
            );
          })
          .toList(growable: false),
      'pillam': pillam
          .map(
            (item) => _CaptureTarget(
              item.pillam,
              '◌${item.pillam}',
              'pillam',
              '${item.nameSi} • trace the mark only',
            ),
          )
          .toList(growable: false),
      'invalid': const [
        _CaptureTarget(
          TraceTrainingCaptureService.unknownLabel,
          '?',
          'invalid',
          'Draw a non-letter line, incomplete shape, or scribble',
          SinhalaLetterLabelMap.unknownClassId,
        ),
      ],
    };
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final folder = (await _service.datasetRoot()).path;
      final counts = await _service.sampleCounts();
      if (!mounted) return;
      setState(() {
        _writer.text = prefs.getString(_writerKey) ?? 'writer_01';
        _folder = folder;
        _counts = counts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Could not open the dataset folder: $error', error: true);
    }
  }

  void _clear() {
    _strokes.clear();
    _activeStroke = [];
  }

  void _selectCategory(String category) {
    setState(() {
      _category = category;
      _targetIndex = 0;
      _showGuide = category != 'invalid';
      _clear();
    });
  }

  Future<Uint8List> _rawPng() async {
    final width = _canvasSize.width.round();
    final height = _canvasSize.height.round();
    if (width < 1 || height < 1) throw StateError('Canvas is not ready.');
    final recorder = ui.PictureRecorder();
    _InkPainter(
      _strokes,
    ).paint(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode the drawing.');
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _save() async {
    if (!_consent) {
      _message('Confirm consent before collecting a sample.', error: true);
      return;
    }
    if (!_hasInk) {
      _message('Draw a sample first.', error: true);
      return;
    }
    final writerId = TraceTrainingCaptureService.safeWriterId(_writer.text);
    if (writerId.isEmpty) {
      _message('Enter an anonymous writer code.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_writerKey, writerId);
      _writer.text = writerId;
      await _service.saveSample(
        rawPng: await _rawPng(),
        label: _target.label,
        kind: _target.kind,
        writerId: writerId,
        currentModelClassId: _target.classId,
      );
      final counts = await _service.sampleCounts();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _clear();
      });
      _message('Training sample saved ✓');
    } catch (error) {
      if (mounted) _message('Could not save sample: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String _categoryName(String value) => switch (value) {
    'base' => 'Base letters',
    'combined' => 'Combined',
    'pillam' => 'Pillam',
    _ => 'Invalid',
  };

  @override
  Widget build(BuildContext context) {
    final currentCount = _counts[_targetKey] ?? 0;
    final total = _counts.values.fold<int>(0, (sum, value) => sum + value);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'CNN Training Data Collector',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _notice(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _writer,
                    decoration: InputDecoration(
                      labelText: 'Anonymous writer code',
                      hintText: 'writer_01',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories
                        .map(
                          (item) => ChoiceChip(
                            label: Text(_categoryName(item)),
                            selected: item == _category,
                            onSelected: (_) => _selectCategory(item),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _targetIndex,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Capture target',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: [
                      for (var i = 0; i < _categoryTargets.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${_categoryTargets[i].display}  •  ${_categoryTargets[i].help}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _targetIndex = value;
                        _clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _targetHeader(currentCount, total),
                  const SizedBox(height: 10),
                  _drawingCanvas(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _hasInk
                            ? () => setState(() => _strokes.removeLast())
                            : null,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Undo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _hasInk ? () => setState(_clear) : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _category == 'invalid'
                                ? 'Save invalid'
                                : 'Save correct',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _folderCard(),
                ],
              ),
            ),
    );
  }

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7DF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.sunshine),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.science_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Research/debug tool only. Never enter a child name or account ID. Use an anonymous code only.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        CheckboxListTile(
          value: _consent,
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) => setState(() => _consent = value ?? false),
          title: const Text(
            'Consent was obtained to collect this handwriting.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _targetHeader(int count, int total) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: AppColors.gradientPrimary,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Text(
          _target.display,
          style: GoogleFonts.notoSansSinhala(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 38,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _target.help,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'This target: $count  •  Total: $total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_category != 'invalid')
          IconButton(
            onPressed: () => setState(() => _showGuide = !_showGuide),
            icon: Icon(
              _showGuide ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
          ),
      ],
    ),
  );

  Widget _drawingCanvas() => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _canvasSize = size;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) =>
                setState(() => _activeStroke = [d.localPosition]),
            onPanUpdate: (d) {
              final p = d.localPosition;
              if (p.dx >= 0 &&
                  p.dy >= 0 &&
                  p.dx <= size.width &&
                  p.dy <= size.height) {
                setState(() => _activeStroke.add(p));
              }
            },
            onPanEnd: (_) => setState(() {
              if (_activeStroke.length > 1) {
                _strokes.add(List<Offset>.from(_activeStroke));
              }
              _activeStroke = [];
            }),
            child: CustomPaint(
              painter: _GridPainter(),
              foregroundPainter: _InkPainter([
                ..._strokes,
                if (_activeStroke.isNotEmpty) _activeStroke,
              ]),
              child: CustomPaint(
                painter: _GuidePainter(
                  _target.display,
                  show: _showGuide && _category != 'invalid',
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _folderCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.folder_copy_outlined, color: AppColors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dataset folder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _folder,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy path',
          onPressed: _folder.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: _folder));
                  if (mounted) _message('Path copied');
                },
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    ),
  );
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _InkPainter(this.strokes);

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
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

class _GuidePainter extends CustomPainter {
  final String text;
  final bool show;
  _GuidePainter(this.text, {required this.show});

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.notoSansSinhala(
          fontSize: size.shortestSide * (text.runes.length > 1 ? 0.48 : 0.68),
          fontWeight: FontWeight.w600,
          color: AppColors.primary.withValues(alpha: 0.13),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) =>
      text != oldDelegate.text || show != oldDelegate.show;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.07);
    for (var y = 28.0; y < size.height; y += 28) {
      for (var x = 28.0; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
