// lib/screens/learning/models/pillam_fill_task.dart
// Question generator for the "fill in the missing pillam" task — a word
// with one pillam blanked out plus a picture cue; the child picks the
// correct pillam to complete the word.

import 'dart:math';
import 'grade_content.dart';

class PillamFillQuestion {
  final PillamFillItem target;
  final List<String> options; // pillam glyphs, includes the answer, shuffled
  const PillamFillQuestion({required this.target, required this.options});
}

class PillamFillTask {
  /// Builds a round of [count] fill-in-the-blank questions from [items].
  static List<PillamFillQuestion> generate(
    List<PillamFillItem> items, {
    int count = 8,
    int optionCount = 4,
  }) {
    final rnd = Random();
    final pool = List<PillamFillItem>.from(items)..shuffle(rnd);
    final questionCount = count.clamp(0, pool.length);
    final allAnswers = items.map((i) => i.answer).toSet().toList();

    return List.generate(questionCount, (i) {
      final target = pool[i];
      final distractors =
          (List<String>.from(allAnswers)
                ..remove(target.answer)
                ..shuffle(rnd))
              .take(optionCount - 1)
              .toList();
      final options = [target.answer, ...distractors]..shuffle(rnd);
      return PillamFillQuestion(target: target, options: options);
    });
  }
}
