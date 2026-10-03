import 'dart:math';

import 'grade_content.dart';

enum Grade1QuestionMode {
  visualMatch,
  wordClue,
  pictureInitial,
  missingInitial,
}

class Grade1LevelDefinition {
  final int level;
  final String taskType;
  final String titleEn;
  final String titleSi;
  final String subtitleEn;
  final String subtitleSi;
  final String emoji;
  final int questionCount;
  final int optionCount;

  const Grade1LevelDefinition({
    required this.level,
    required this.taskType,
    required this.titleEn,
    required this.titleSi,
    required this.subtitleEn,
    required this.subtitleSi,
    required this.emoji,
    required this.questionCount,
    required this.optionCount,
  });

  static const double unlockPercentage = 70;

  static const List<Grade1LevelDefinition> levels = [
    Grade1LevelDefinition(
      level: 1,
      taskType: 'grade1_level_1',
      titleEn: 'Find the Same Letter',
      titleSi: 'එකම අකුර සොයමු',
      subtitleEn: 'See and match • Easy',
      subtitleSi: 'බලා ගලපන්න • පහසු',
      emoji: '👀',
      questionCount: 6,
      optionCount: 3,
    ),
    Grade1LevelDefinition(
      level: 2,
      taskType: 'grade1_level_2',
      titleEn: 'Letter and Word',
      titleSi: 'අකුර සහ වචනය',
      subtitleEn: 'Use the word clue • Easy',
      subtitleSi: 'වචන ඉඟියෙන් තෝරන්න • පහසු',
      emoji: '🔤',
      questionCount: 8,
      optionCount: 3,
    ),
    Grade1LevelDefinition(
      level: 3,
      taskType: 'grade1_level_3',
      titleEn: 'Picture to Letter',
      titleSi: 'රූපයෙන් අකුරට',
      subtitleEn: 'Find the first letter • Medium',
      subtitleSi: 'මුල් අකුර සොයන්න • මධ්‍යම',
      emoji: '🖼️',
      questionCount: 8,
      optionCount: 4,
    ),
    Grade1LevelDefinition(
      level: 4,
      taskType: 'grade1_level_4',
      titleEn: 'Complete the Word',
      titleSi: 'වචනය සම්පූර්ණ කරමු',
      subtitleEn: 'Fill the missing first letter • Hard',
      subtitleSi: 'අඩු මුල් අකුර පුරවන්න • අමාරු',
      emoji: '🧩',
      questionCount: 10,
      optionCount: 4,
    ),
    Grade1LevelDefinition(
      level: 5,
      taskType: 'grade1_level_5',
      titleEn: 'Letter Master Challenge',
      titleSi: 'අකුරු ශූර අභියෝගය',
      subtitleEn: 'Mixed skills • Challenge',
      subtitleSi: 'මිශ්‍ර හැකියා • අභියෝගය',
      emoji: '🏆',
      questionCount: 10,
      optionCount: 5,
    ),
  ];

  static Grade1LevelDefinition byLevel(int level) =>
      levels.firstWhere((item) => item.level == level);

  static bool isUnlocked(int level, Map<int, double> bestPercentages) {
    if (level <= 1) return true;
    return (bestPercentages[level - 1] ?? 0) >= unlockPercentage;
  }
}

class Grade1LevelQuestion {
  final LetterItem target;
  final List<LetterItem> options;
  final Grade1QuestionMode mode;

  const Grade1LevelQuestion({
    required this.target,
    required this.options,
    required this.mode,
  });

  String get missingWord {
    final word = target.exampleWord;
    if (!word.startsWith(target.letter)) return '___ $word';
    return '___${word.substring(target.letter.length)}';
  }
}

abstract final class Grade1LevelTask {
  static List<Grade1LevelQuestion> generate({
    required List<LetterItem> letters,
    required int level,
    Random? random,
  }) {
    if (letters.isEmpty) return const [];
    final definition = Grade1LevelDefinition.byLevel(level);
    final rnd = random ?? Random();
    final questions = <Grade1LevelQuestion>[];

    for (var index = 0; index < definition.questionCount; index++) {
      final mode = _modeFor(level, index);
      final eligible = mode == Grade1QuestionMode.pictureInitial
          ? letters.where((item) => item.emoji != '🔤').toList()
          : List<LetterItem>.from(letters);
      final usable = eligible.isEmpty
          ? List<LetterItem>.from(letters)
          : eligible;
      if (index % usable.length == 0) usable.shuffle(rnd);
      final target = usable[index % usable.length];
      final distractors = List<LetterItem>.from(letters)
        ..removeWhere((item) => item.letter == target.letter)
        ..shuffle(rnd);
      final options = <LetterItem>[
        target,
        ...distractors.take(definition.optionCount - 1),
      ]..shuffle(rnd);
      questions.add(
        Grade1LevelQuestion(target: target, options: options, mode: mode),
      );
    }
    return questions;
  }

  static Grade1QuestionMode _modeFor(int level, int questionIndex) {
    switch (level) {
      case 1:
        return Grade1QuestionMode.visualMatch;
      case 2:
        return Grade1QuestionMode.wordClue;
      case 3:
        return Grade1QuestionMode.pictureInitial;
      case 4:
        return Grade1QuestionMode.missingInitial;
      case 5:
        const mixed = [
          Grade1QuestionMode.wordClue,
          Grade1QuestionMode.pictureInitial,
          Grade1QuestionMode.missingInitial,
          Grade1QuestionMode.visualMatch,
        ];
        return mixed[questionIndex % mixed.length];
      default:
        throw RangeError.range(level, 1, 5, 'level');
    }
  }
}
