import '../models/task_attempt.dart';

/// Aggregate evidence for one expected tracing letter.
class LetterTraceMetrics {
  final String expectedLetter;
  final int attempts;
  final int correct;
  final int unsupportedPredictions;
  final int lowConfidencePredictions;
  final double meanConfidence;
  final double meanShapeSimilarity;
  final double? meanInferenceMilliseconds;

  const LetterTraceMetrics({
    required this.expectedLetter,
    required this.attempts,
    required this.correct,
    required this.unsupportedPredictions,
    required this.lowConfidencePredictions,
    required this.meanConfidence,
    required this.meanShapeSimilarity,
    required this.meanInferenceMilliseconds,
  });

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  Map<String, Object?> toJson() => {
    'expectedLetter': expectedLetter,
    'attempts': attempts,
    'correct': correct,
    'accuracy': accuracy,
    'unsupportedPredictions': unsupportedPredictions,
    'lowConfidencePredictions': lowConfidencePredictions,
    'meanConfidence': meanConfidence,
    'meanShapeSimilarity': meanShapeSimilarity,
    if (meanInferenceMilliseconds != null)
      'meanInferenceMilliseconds': meanInferenceMilliseconds,
  };
}

/// Local, de-identified model evidence derived from saved tracing attempts.
///
/// This is practice evidence, not a clinical measure or a controlled child
/// study. Raw trace images and student identifiers are deliberately absent.
class TraceEvaluationSummary {
  final int totalAttempts;
  final int correctAttempts;
  final int unsupportedPredictions;
  final int lowConfidencePredictions;
  final double meanConfidence;
  final double meanShapeSimilarity;
  final double? meanInferenceMilliseconds;
  final Map<String, LetterTraceMetrics> byLetter;
  final Map<String, Map<String, int>> confusionCounts;
  final List<String> modelVersions;

  const TraceEvaluationSummary({
    required this.totalAttempts,
    required this.correctAttempts,
    required this.unsupportedPredictions,
    required this.lowConfidencePredictions,
    required this.meanConfidence,
    required this.meanShapeSimilarity,
    required this.meanInferenceMilliseconds,
    required this.byLetter,
    required this.confusionCounts,
    required this.modelVersions,
  });

  factory TraceEvaluationSummary.empty() => const TraceEvaluationSummary(
    totalAttempts: 0,
    correctAttempts: 0,
    unsupportedPredictions: 0,
    lowConfidencePredictions: 0,
    meanConfidence: 0,
    meanShapeSimilarity: 0,
    meanInferenceMilliseconds: null,
    byLetter: {},
    confusionCounts: {},
    modelVersions: [],
  );

  bool get hasData => totalAttempts > 0;
  double get accuracy =>
      totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;

  Map<String, Object?> toJson() => {
    'scope': 'local-practice-evidence-only',
    'totalAttempts': totalAttempts,
    'correctAttempts': correctAttempts,
    'accuracy': accuracy,
    'unsupportedPredictions': unsupportedPredictions,
    'lowConfidencePredictions': lowConfidencePredictions,
    'meanConfidence': meanConfidence,
    'meanShapeSimilarity': meanShapeSimilarity,
    if (meanInferenceMilliseconds != null)
      'meanInferenceMilliseconds': meanInferenceMilliseconds,
    'modelVersions': modelVersions,
    'byLetter': byLetter.map((key, value) => MapEntry(key, value.toJson())),
    'confusionCounts': confusionCounts,
  };
}

class _MutableLetterMetrics {
  int attempts = 0;
  int correct = 0;
  int unsupported = 0;
  int lowConfidence = 0;
  double confidenceTotal = 0;
  int confidenceCount = 0;
  double shapeSimilarityTotal = 0;
  int shapeSimilarityCount = 0;
  double inferenceTotal = 0;
  int inferenceCount = 0;
}

abstract final class TraceEvaluationService {
  static const double confidenceThreshold = 0.5;

  static TraceEvaluationSummary summarize(Iterable<TaskAttempt> attempts) {
    var total = 0;
    var correct = 0;
    var unsupported = 0;
    var lowConfidence = 0;
    var confidenceTotal = 0.0;
    var confidenceCount = 0;
    var shapeSimilarityTotal = 0.0;
    var shapeSimilarityCount = 0;
    var inferenceTotal = 0.0;
    var inferenceCount = 0;
    final versions = <String>{};
    final mutableByLetter = <String, _MutableLetterMetrics>{};
    final confusions = <String, Map<String, int>>{};

    for (final attempt in attempts) {
      if (attempt.taskType != 'letter_tracing') continue;
      for (final item in attempt.items) {
        total++;
        if (item.isCorrect) correct++;

        final expected = item.itemId;
        final predicted = item.predictedLabel ?? 'unknown';
        final isUnsupported =
            item.predictedLabel == null || predicted.startsWith('class:');
        if (isUnsupported) unsupported++;

        final confidence = item.confidence;
        final isLowConfidence =
            confidence != null && confidence < confidenceThreshold;
        if (isLowConfidence) lowConfidence++;
        if (confidence != null) {
          confidenceTotal += confidence;
          confidenceCount++;
        }

        final shapeSimilarity = item.shapeSimilarity;
        if (shapeSimilarity != null) {
          shapeSimilarityTotal += shapeSimilarity;
          shapeSimilarityCount++;
        }

        final inference = item.inferenceMilliseconds;
        if (inference != null) {
          inferenceTotal += inference;
          inferenceCount++;
        }
        if (item.modelVersion case final version?) versions.add(version);

        final letter = mutableByLetter.putIfAbsent(
          expected,
          _MutableLetterMetrics.new,
        );
        letter.attempts++;
        if (item.isCorrect) letter.correct++;
        if (isUnsupported) letter.unsupported++;
        if (isLowConfidence) letter.lowConfidence++;
        if (confidence != null) {
          letter.confidenceTotal += confidence;
          letter.confidenceCount++;
        }
        if (shapeSimilarity != null) {
          letter.shapeSimilarityTotal += shapeSimilarity;
          letter.shapeSimilarityCount++;
        }
        if (inference != null) {
          letter.inferenceTotal += inference;
          letter.inferenceCount++;
        }

        final expectedConfusions = confusions.putIfAbsent(expected, () => {});
        expectedConfusions[predicted] =
            (expectedConfusions[predicted] ?? 0) + 1;
      }
    }

    final byLetter = <String, LetterTraceMetrics>{};
    for (final entry in mutableByLetter.entries) {
      final value = entry.value;
      byLetter[entry.key] = LetterTraceMetrics(
        expectedLetter: entry.key,
        attempts: value.attempts,
        correct: value.correct,
        unsupportedPredictions: value.unsupported,
        lowConfidencePredictions: value.lowConfidence,
        meanConfidence: value.confidenceCount == 0
            ? 0
            : value.confidenceTotal / value.confidenceCount,
        meanShapeSimilarity: value.shapeSimilarityCount == 0
            ? 0
            : value.shapeSimilarityTotal / value.shapeSimilarityCount,
        meanInferenceMilliseconds: value.inferenceCount == 0
            ? null
            : value.inferenceTotal / value.inferenceCount,
      );
    }

    final sortedVersions = versions.toList()..sort();
    return TraceEvaluationSummary(
      totalAttempts: total,
      correctAttempts: correct,
      unsupportedPredictions: unsupported,
      lowConfidencePredictions: lowConfidence,
      meanConfidence: confidenceCount == 0
          ? 0
          : confidenceTotal / confidenceCount,
      meanShapeSimilarity: shapeSimilarityCount == 0
          ? 0
          : shapeSimilarityTotal / shapeSimilarityCount,
      meanInferenceMilliseconds: inferenceCount == 0
          ? null
          : inferenceTotal / inferenceCount,
      byLetter: Map.unmodifiable(byLetter),
      confusionCounts: Map.unmodifiable(
        confusions.map(
          (key, value) => MapEntry(key, Map<String, int>.unmodifiable(value)),
        ),
      ),
      modelVersions: List.unmodifiable(sortedVersions),
    );
  }

  /// Produces exportable records without a student ID or raw trace image.
  static List<Map<String, Object?>> sanitizedRecords(
    Iterable<TaskAttempt> attempts,
  ) {
    final records = <Map<String, Object?>>[];
    for (final attempt in attempts) {
      if (attempt.taskType != 'letter_tracing') continue;
      for (final item in attempt.items) {
        records.add({
          'completedAt': attempt.completedAt.toUtc().toIso8601String(),
          'grade': attempt.grade,
          'language': attempt.language,
          'expectedLetter': item.itemId,
          'isCorrect': item.isCorrect,
          if (item.predictedLabel != null)
            'predictedLabel': item.predictedLabel,
          if (item.predictionClassId != null)
            'predictionClassId': item.predictionClassId,
          if (item.predictionOutputIndex != null)
            'predictionOutputIndex': item.predictionOutputIndex,
          if (item.confidence != null) 'confidence': item.confidence,
          if (item.shapeSimilarity != null)
            'shapeSimilarity': item.shapeSimilarity,
          if (item.inferenceMilliseconds != null)
            'inferenceMilliseconds': item.inferenceMilliseconds,
          if (item.modelVersion != null) 'modelVersion': item.modelVersion,
        });
      }
    }
    return List.unmodifiable(records);
  }

  static Map<String, Object?> buildSanitizedExport(
    Iterable<TaskAttempt> attempts, {
    DateTime? generatedAt,
  }) {
    final tracingAttempts = attempts
        .where((attempt) => attempt.taskType == 'letter_tracing')
        .toList(growable: false);
    return {
      'schemaVersion': 'readbuddy-trace-evaluation-v1',
      'generatedAt': (generatedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'privacy': {
        'containsStudentIdentifier': false,
        'containsRawTraceImage': false,
        'intendedUse': 'supervisor-approved technical evaluation',
      },
      'summary': summarize(tracingAttempts).toJson(),
      'records': sanitizedRecords(tracingAttempts),
    };
  }
}
