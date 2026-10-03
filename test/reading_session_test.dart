import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/models/reading_session.dart';

void main() {
  test('reading completion rate uses completed pages', () {
    final session =
        ReadingSession(
            storyId: 'story',
            gradeLevel: 1,
            startTime: DateTime(2026),
          )
          ..pagesCompleted = 3
          ..totalPages = 4;

    expect(session.completionRate, 0.75);
  });

  test('completed session reports elapsed seconds', () {
    final session = ReadingSession(
      storyId: 'story',
      gradeLevel: 1,
      startTime: DateTime(2026),
    )..endTime = DateTime(2026).add(const Duration(seconds: 75));

    expect(session.durationSeconds, 75);
  });
}
