// lib/screens/learning/models/letter_recognition_task.dart
// Question generator for the "see the picture, pick the letter" task.

import 'dart:math';
import 'grade_content.dart';

class LetterRecognitionQuestion {
  final LetterItem target;
  final List<LetterItem> options; // includes the target, shuffled
  const LetterRecognitionQuestion({
    required this.target,
    required this.options,
  });
}

class LetterRecognitionTask {
  /// Builds a round of [count] picture-recognition questions from [letters].
  ///
  /// Letters using the '🔤' neutral placeholder emoji (see grade_content.dart)
  /// are excluded — that glyph doesn't depict anything a child could
  /// recognise, so it can't be the picture half of a picture-recognition
  /// question.
  static List<LetterRecognitionQuestion> generate(
    List<LetterItem> letters, {
    int count = 8,
    int optionCount = 4,
  }) {
    final usable = letters.where((l) => l.emoji != '🔤').toList();
    final rnd = Random();
    final pool = List<LetterItem>.from(usable)..shuffle(rnd);
    final questionCount = count.clamp(0, pool.length);

    return List.generate(questionCount, (i) {
      final target = pool[i];
      final distractors =
          (List<LetterItem>.from(usable)
                ..remove(target)
                ..shuffle(rnd))
              .take(optionCount - 1)
              .toList();
      final options = [target, ...distractors]..shuffle(rnd);
      return LetterRecognitionQuestion(target: target, options: options);
    });
  }
}
