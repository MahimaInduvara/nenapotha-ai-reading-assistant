import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/task_attempt.dart';
import 'package:reading_assistant_app/services/trace_evaluation_service.dart';

TaskAttempt _attempt({
  required String expected,
  required bool correct,
  required String predicted,
  required int classId,
  required double confidence,
  required double inferenceMilliseconds,
  DateTime? completedAt,
}) => TaskAttempt(
  taskType: 'letter_tracing',
  grade: 1,
  language: 'sinhala',
  score: correct ? 1 : 0,
  total: 1,
  completedAt: completedAt ?? DateTime.utc(2026, 8, 31),
  items: [
    TaskItemResult(
      itemId: expected,
      isCorrect: correct,
      confidence: confidence,
      predictedLabel: predicted,
      predictionClassId: classId,
      predictionOutputIndex: classId - 1,
      inferenceMilliseconds: inferenceMilliseconds,
      modelVersion: 'readbuddy-stage3-cnn-v4-ad082e94',
    ),
  ],
);

void main() {
  group('TaskItemResult Stage 5 evidence', () {
    test('round-trips model provenance and remains backward compatible', () {
      const item = TaskItemResult(
        itemId: 'අ',
        isCorrect: true,
        confidence: 0.91,
        shapeSimilarity: 0.84,
        predictedLabel: 'අ',
        predictionClassId: 1,
        predictionOutputIndex: 0,
        inferenceMilliseconds: 12.5,
        modelVersion: 'readbuddy-stage3-cnn-v4-ad082e94',
      );

      final restored = TaskItemResult.fromJson(item.toJson());
      expect(restored.predictionClassId, 1);
      expect(restored.shapeSimilarity, 0.84);
      expect(restored.predictionOutputIndex, 0);
      expect(restored.inferenceMilliseconds, 12.5);
      expect(restored.modelVersion, 'readbuddy-stage3-cnn-v4-ad082e94');

      final legacy = TaskItemResult.fromJson({
        'itemId': 'ක',
        'isCorrect': false,
      });
      expect(legacy.predictionClassId, isNull);
      expect(legacy.shapeSimilarity, isNull);
      expect(legacy.inferenceMilliseconds, isNull);
      expect(legacy.modelVersion, isNull);
    });
  });

  group('TraceEvaluationService', () {
    final tracingAttempts = [
      _attempt(
        expected: 'අ',
        correct: true,
        predicted: 'අ',
        classId: 1,
        confidence: 0.9,
        inferenceMilliseconds: 10,
      ),
      _attempt(
        expected: 'අ',
        correct: false,
        predicted: 'ආ',
        classId: 2,
        confidence: 0.8,
        inferenceMilliseconds: 20,
      ),
      _attempt(
        expected: 'ක',
        correct: false,
        predicted: 'class:100',
        classId: 100,
        confidence: 0.4,
        inferenceMilliseconds: 30,
      ),
    ];

    test('computes aggregate, per-letter, latency, and confusion evidence', () {
      final summary = TraceEvaluationService.summarize(tracingAttempts);

      expect(summary.totalAttempts, 3);
      expect(summary.correctAttempts, 1);
      expect(summary.accuracy, closeTo(1 / 3, 0.000001));
      expect(summary.meanConfidence, closeTo(0.7, 0.000001));
      expect(summary.meanInferenceMilliseconds, 20);
      expect(summary.unsupportedPredictions, 1);
      expect(summary.lowConfidencePredictions, 1);
      expect(summary.modelVersions, ['readbuddy-stage3-cnn-v4-ad082e94']);

      expect(summary.byLetter['අ']!.attempts, 2);
      expect(summary.byLetter['අ']!.accuracy, 0.5);
      expect(summary.byLetter['ක']!.unsupportedPredictions, 1);
      expect(summary.confusionCounts['අ'], {'අ': 1, 'ආ': 1});
      expect(summary.confusionCounts['ක'], {'class:100': 1});
    });

    test('ignores non-tracing tasks', () {
      final summary = TraceEvaluationService.summarize([
        ...tracingAttempts,
        TaskAttempt(
          taskType: 'letter_matching',
          grade: 1,
          language: 'sinhala',
          score: 1,
          total: 1,
          completedAt: DateTime.utc(2026, 8, 31),
          items: const [TaskItemResult(itemId: 'ග', isCorrect: true)],
        ),
      ]);

      expect(summary.totalAttempts, 3);
      expect(summary.byLetter, isNot(contains('ග')));
    });

    test('builds a de-identified export without raw images', () {
      final export = TraceEvaluationService.buildSanitizedExport(
        tracingAttempts,
        generatedAt: DateTime.utc(2026, 8, 31, 12),
      );
      final encoded = jsonEncode(export);

      expect(export['schemaVersion'], 'readbuddy-trace-evaluation-v1');
      expect(encoded, isNot(contains('studentId')));
      expect(encoded, isNot(contains('rawTrace')));
      expect(encoded, isNot(contains('imageBytes')));
      expect((export['records'] as List), hasLength(3));
      expect((export['privacy'] as Map)['containsRawTraceImage'], isFalse);
    });

    test('returns an empty summary when no evidence exists', () {
      final summary = TraceEvaluationService.summarize(const []);
      expect(summary.hasData, isFalse);
      expect(summary.accuracy, 0);
      expect(summary.byLetter, isEmpty);
    });
  });
}
