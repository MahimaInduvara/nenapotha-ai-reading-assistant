import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/screens/learning/models/grade_content.dart';
import 'package:reading_assistant_app/widgets/task_picture.dart';

void main() {
  group('Offline task pictures', () {
    test('cover every usable Grade 1 English and Sinhala clue', () {
      final usableLetters = [
        ...Grade1Content.englishLetters,
        ...Grade1Content.sinhalaLetters.where((item) => item.emoji != '🔤'),
      ];
      for (final item in usableLetters) {
        expect(
          TaskPicture.hasPicture(item.exampleWord),
          isTrue,
          reason: 'Missing picture for ${item.exampleWord}',
        );
      }
    });

    test('cover every Grade 2 vocabulary and pillam-fill clue', () {
      final words = {
        ...Grade2Content.words.map((item) => item.wordSi),
        ...Grade2Content.pillamFillWords.map((item) => item.word),
      };
      for (final word in words) {
        expect(
          TaskPicture.hasPicture(word),
          isTrue,
          reason: 'Missing picture for $word',
        );
      }
    });
  });
}
