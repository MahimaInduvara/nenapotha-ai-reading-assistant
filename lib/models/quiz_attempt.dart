// lib/models/quiz_attempt.dart
// A single completed comprehension-quiz run, persisted to Firestore
// (students/{id}/quizAttempts) so progress screens/AI can show real
// comprehension data instead of mock numbers.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-question result within one quiz attempt — `type` is the question
/// FORMAT ('mcq', 'truefalse', 'fill', 'sequence', 'short'), not a
/// comprehension category like "main idea" (the app has never tracked
/// comprehension by category, only by question format).
class QuizQuestionResult {
  final String type;
  final bool isCorrect;
  const QuizQuestionResult({required this.type, required this.isCorrect});

  Map<String, dynamic> toMap() => {'type': type, 'isCorrect': isCorrect};

  factory QuizQuestionResult.fromMap(Map<String, dynamic> map) =>
      QuizQuestionResult(
        type: map['type'] ?? '',
        isCorrect: map['isCorrect'] ?? false,
      );
}

class QuizAttempt {
  final String id;
  final String storyId;
  final int score;
  final int total;
  final List<QuizQuestionResult> results;
  final DateTime completedAt;

  const QuizAttempt({
    this.id = '',
    required this.storyId,
    required this.score,
    required this.total,
    this.results = const [],
    required this.completedAt,
  });

  double get percentage => total > 0 ? score / total * 100 : 0;

  Map<String, dynamic> toFirestoreMap() => {
    'storyId': storyId,
    'score': score,
    'total': total,
    'results': results.map((r) => r.toMap()).toList(),
    'completedAt': Timestamp.fromDate(completedAt),
  };

  factory QuizAttempt.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawResults = data['results'] as List? ?? [];
    return QuizAttempt(
      id: doc.id,
      storyId: data['storyId'] ?? '',
      score: data['score'] ?? 0,
      total: data['total'] ?? 0,
      results: rawResults
          .map(
            (r) =>
                QuizQuestionResult.fromMap(Map<String, dynamic>.from(r as Map)),
          )
          .toList(),
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
