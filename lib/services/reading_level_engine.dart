// lib/services/reading_level_engine.dart
// AI-powered adaptive reading level detection & recommendation engine

import '../models/story.dart';
import 'story_data_service.dart';
import 'text_difficulty_classifier.dart';

class ReadingLevelEngine {
  static final TextDifficultyClassifier _difficultyClassifier =
      TextDifficultyClassifier();

  /// Runs the offline text-difficulty classifier (see
  /// text_difficulty_classifier.dart) against a story's raw text and returns
  /// the grade level — 1 or 2 only, it's a binary classifier — it best
  /// matches. Useful for sanity-checking a Grade 1/2 story's assigned
  /// gradeLevel against its actual content difficulty, independent of
  /// whatever grade it was authored/tagged for. Do not call this for Grade
  /// 3+ content — it was not trained on Grade 3 samples and has no way to
  /// signal "neither," it always forces a 1-or-2 answer.
  static int classifyStoryDifficulty(String text) {
    return _difficultyClassifier.predictGrade(text);
  }

  /// Returns authored-grade stories while using the small classifier only as
  /// an advisory ordering signal. The exploratory 26-sample model must never
  /// move Grade 1 content into Grade 2 (or vice versa) without human review.
  static List<Story> recommendStoriesForLevel(int gradeLevel) {
    final tagged = StoryDataService.getStoriesForGrade(gradeLevel).toList();
    tagged.sort((a, b) {
      final aAgrees = classifyStoryDifficulty(a.contentSi) == gradeLevel;
      final bAgrees = classifyStoryDifficulty(b.contentSi) == gradeLevel;
      if (aAgrees == bAgrees) return 0;
      return aAgrees ? -1 : 1;
    });
    return tagged;
  }

  /// True means the proof-of-concept classifier disagrees with the human
  /// authored grade and the text should be reviewed, not auto-relabelled.
  static bool needsDifficultyReview(Story story) =>
      classifyStoryDifficulty(story.contentSi) != story.gradeLevel;

  /// Identifies "difficult" words for a given grade level
  static bool isDifficultWord(String word, int gradeLevel) {
    final clean = word.replaceAll(RegExp(r'[^\w]'), '');
    switch (gradeLevel) {
      case 1:
        return clean.length > 4;
      case 2:
        return clean.length > 5;
      default:
        return false;
    }
  }
}
