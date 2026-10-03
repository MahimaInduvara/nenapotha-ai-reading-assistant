import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/services/ai_service.dart';
import 'package:reading_assistant_app/services/story_data_service.dart';

void main() {
  group('Bilingual story library', () {
    test('provides a useful reading choice for both supported grades', () {
      expect(StoryDataService.getStoriesForGrade(1), hasLength(5));
      expect(StoryDataService.getStoriesForGrade(2), hasLength(5));
      expect(StoryDataService.getAllStories(), hasLength(10));
    });

    test('uses unique IDs and complete Sinhala and English content', () {
      final stories = StoryDataService.getAllStories();
      expect(
        stories.map((story) => story.id).toSet(),
        hasLength(stories.length),
      );

      for (final story in stories) {
        expect(story.titleSi.trim(), isNotEmpty, reason: story.id);
        expect(story.titleEn.trim(), isNotEmpty, reason: story.id);
        expect(
          story.contentSi.split(RegExp(r'\s+')).length,
          greaterThan(20),
          reason: '${story.id} needs meaningful Sinhala reading content',
        );
        expect(
          story.contentEn.split(RegExp(r'\s+')).length,
          greaterThan(20),
          reason: '${story.id} needs meaningful English reading content',
        );
        expect(story.thumbnailUrl.trim(), isNotEmpty, reason: story.id);
        expect(['easy', 'medium', 'hard'], contains(story.difficulty));
      }
    });

    test('removes the known errors from the original draft stories', () {
      final allText = StoryDataService.getAllStories()
          .map(
            (story) => '${story.titleSi} ${story.titleEn} ${story.contentSi}',
          )
          .join(' ');

      for (final error in [
        'ලෙව්කෑම',
        'හිඳින්ෙනා',
        'හෑරූ',
        'දල් කෑවා',
        'Elephant and Banana',
      ]) {
        expect(
          allText,
          isNot(contains(error)),
          reason: 'Found old error: $error',
        );
      }
    });

    test('vocabulary words occur in their matching story language', () {
      for (final story in StoryDataService.getAllStories()) {
        final english = story.contentEn.toLowerCase();
        for (final word in story.vocabularyWordsSi) {
          expect(story.contentSi, contains(word), reason: '${story.id}: $word');
        }
        for (final word in story.vocabularyWordsEn) {
          expect(
            english,
            contains(word.toLowerCase()),
            reason: '${story.id}: $word',
          );
        }
      }
    });

    test('Grade 1 Sinhala stories use short beginner-sized sentences', () {
      for (final story in StoryDataService.getStoriesForGrade(1)) {
        final words = story.contentSi.trim().split(RegExp(r'\s+'));
        final sentences = story.contentSi
            .split('.')
            .map((sentence) => sentence.trim())
            .where((sentence) => sentence.isNotEmpty);

        expect(words.length, inInclusiveRange(20, 25), reason: story.id);
        expect(story.wordCount, words.length, reason: story.id);
        for (final sentence in sentences) {
          expect(
            sentence.split(RegExp(r'\s+')).length,
            lessThanOrEqualTo(5),
            reason: '${story.id}: $sentence',
          );
        }
      }
    });
  });

  group('Story comprehension', () {
    test('Grade 1 uses three concrete recognition questions', () {
      final story = StoryDataService.getStoryById('g1_s3')!;
      final questions = AIService().generateQuiz(
        story,
        count: 5,
        gradeLevel: 1,
      );

      expect(questions, hasLength(3));
      expect(
        questions.map((question) => question.type).toSet(),
        equals({'mcq', 'truefalse'}),
      );
      expect(questions.first.correctAnswer, contains('Nimal'));
    });

    test('Grade 2 includes inferential questions for every new story', () {
      for (final story in StoryDataService.getStoriesForGrade(2)) {
        final questions = AIService().generateQuiz(
          story,
          count: 5,
          gradeLevel: 2,
          depth: QuestionDepth.inferential,
        );

        expect(questions, hasLength(5), reason: story.id);
        expect(
          questions.any((question) => question.question.contains('Why')),
          isTrue,
          reason: story.id,
        );
        expect(
          questions.every((question) => question.correctAnswer.isNotEmpty),
          isTrue,
          reason: story.id,
        );
      }
    });
  });
}
