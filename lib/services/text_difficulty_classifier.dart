// lib/services/text_difficulty_classifier.dart
// Binary logistic regression: Grade 1 vs Grade 2. (No Grade 3 — the
// previous 3-class model was dropped for it; see reading_level_engine.dart
// for the one caller.) Feature order for the weights below is
// [n_words, avg_word_len, avg_sentence_len] — must stay in that order,
// since the weights were fit against features in exactly this order.
//
// Trained on 26 real samples from this app's own content (9 Grade 1,
// 17 Grade 2) — 69.2% training accuracy. Small sample, so treat
// predictions as a rough signal, not a precise measure.
import 'dart:math' as math;

class TextDifficultyResult {
  final int predictedGrade;
  final double grade2Probability;
  final int wordCount;
  final double averageWordLength;
  final double averageSentenceLength;

  const TextDifficultyResult({
    required this.predictedGrade,
    required this.grade2Probability,
    required this.wordCount,
    required this.averageWordLength,
    required this.averageSentenceLength,
  });

  double get predictedGradeProbability =>
      predictedGrade == 2 ? grade2Probability : 1 - grade2Probability;
}

class TextDifficultyClassifier {
  static const List<double> _weights = [
    0.4838682516631426,
    0.5542221381139503,
    0.4838682516631426,
  ];
  static const double _intercept = -4.682712579731816;

  /// Computes [n_words, avg_word_len, avg_sentence_len] for [text].
  /// Words are split on whitespace; sentences on '.', '!', '?'.
  List<double> _extractFeatures(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final nWords = words.length;
    final avgWordLen = nWords == 0
        ? 0.0
        : words.fold<int>(0, (sum, w) => sum + w.length) / nWords;

    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final avgSentenceLen = sentences.isEmpty
        ? nWords.toDouble()
        : sentences
                  .map(
                    (s) => s
                        .split(RegExp(r'\s+'))
                        .where((w) => w.isNotEmpty)
                        .length,
                  )
                  .reduce((a, b) => a + b) /
              sentences.length;

    return [nWords.toDouble(), avgWordLen, avgSentenceLen];
  }

  /// Returns the prediction together with the three observable features used
  /// by the model. This keeps the teacher-facing explanation grounded in the
  /// exact inputs used by the fitted logistic-regression weights.
  TextDifficultyResult analyze(String text) {
    final features = _extractFeatures(text);
    var z = _intercept;
    for (var i = 0; i < features.length; i++) {
      z += _weights[i] * features[i];
    }
    final probability = 1 / (1 + math.exp(-z));
    return TextDifficultyResult(
      predictedGrade: probability >= 0.5 ? 2 : 1,
      grade2Probability: probability,
      wordCount: features[0].round(),
      averageWordLength: features[1],
      averageSentenceLength: features[2],
    );
  }

  /// Scores [text] via sigmoid(intercept + dot(weights, features)) and
  /// returns the grade — 1 or 2 — the probability favors (>= 0.5 -> 2).
  int predictGrade(String text) => analyze(text).predictedGrade;
}
