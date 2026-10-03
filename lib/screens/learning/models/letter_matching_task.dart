// lib/screens/learning/models/letter_matching_task.dart
// Question generator for the "connect the same letter" matching task.

import 'dart:math';
import 'grade_content.dart';

class LetterMatchingTask {
  static const int defaultPairCount = 8;

  /// Picks [count] distinct letters from [letters] and returns two
  /// independently shuffled orderings of them — one for the left column,
  /// one for the right — for the child to connect by matching value.
  static (List<String> left, List<String> right) generate(
    List<LetterItem> letters, {
    int count = defaultPairCount,
  }) {
    final rnd = Random();
    final pool = (List<LetterItem>.from(letters)..shuffle(rnd))
        .take(count.clamp(0, letters.length))
        .map((l) => l.letter)
        .toList();
    final left = List<String>.from(pool)..shuffle(rnd);
    final right = List<String>.from(pool)..shuffle(rnd);
    return (left, right);
  }
}
