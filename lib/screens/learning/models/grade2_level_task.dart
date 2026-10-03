import 'dart:math';

import 'grade_content.dart';

enum Grade2QuestionMode {
  identifyPillam,
  completePillam,
  pictureWord,
  completeSentence,
  comprehension,
}

class Grade2LevelDefinition {
  final int level;
  final String taskType;
  final String emoji;
  final String titleEn;
  final String titleSi;
  final String subtitleEn;
  final String subtitleSi;
  final int questionCount;
  final int optionCount;

  const Grade2LevelDefinition({
    required this.level,
    required this.taskType,
    required this.emoji,
    required this.titleEn,
    required this.titleSi,
    required this.subtitleEn,
    required this.subtitleSi,
    required this.questionCount,
    required this.optionCount,
  });

  static const double unlockPercentage = 70;

  static const List<Grade2LevelDefinition> levels = [
    Grade2LevelDefinition(
      level: 1,
      taskType: 'grade2_level_1',
      emoji: '🔤',
      titleEn: 'Pillam Explorer',
      titleSi: 'පිල්ලම් ගවේෂකයා',
      subtitleEn: 'Recognise core pillam and their names',
      subtitleSi: 'මූලික පිල්ලම් හා ඒවායේ නම් හඳුනාගමු',
      questionCount: 8,
      optionCount: 3,
    ),
    Grade2LevelDefinition(
      level: 2,
      taskType: 'grade2_level_2',
      emoji: '🧩',
      titleEn: 'Word Builder',
      titleSi: 'වචන ගොඩනඟන්නා',
      subtitleEn: 'Choose the pillam that completes each word',
      subtitleSi: 'වචනය සම්පූර්ණ කරන පිල්ලම තෝරමු',
      questionCount: 10,
      optionCount: 4,
    ),
    Grade2LevelDefinition(
      level: 3,
      taskType: 'grade2_level_3',
      emoji: '🖼️',
      titleEn: 'Picture Vocabulary',
      titleSi: 'රූප වචන මාලාව',
      subtitleEn: 'Connect pictures with the correct Sinhala words',
      subtitleSi: 'රූප නිවැරදි සිංහල වචන සමඟ ගළපමු',
      questionCount: 10,
      optionCount: 4,
    ),
    Grade2LevelDefinition(
      level: 4,
      taskType: 'grade2_level_4',
      emoji: '✍️',
      titleEn: 'Sentence Builder',
      titleSi: 'වාක්‍ය ගොඩනඟන්නා',
      subtitleEn: 'Complete meaningful sentences',
      subtitleSi: 'අර්ථවත් වාක්‍ය සම්පූර්ණ කරමු',
      questionCount: 10,
      optionCount: 4,
    ),
    Grade2LevelDefinition(
      level: 5,
      taskType: 'grade2_level_5',
      emoji: '🔎',
      titleEn: 'Reading Detective',
      titleSi: 'කියවීමේ රහස් පරීක්ෂක',
      subtitleEn: 'Read, understand, and answer questions',
      subtitleSi: 'කියවා තේරුම්ගෙන ප්‍රශ්නවලට පිළිතුරු දෙමු',
      questionCount: 8,
      optionCount: 4,
    ),
    Grade2LevelDefinition(
      level: 6,
      taskType: 'grade2_level_6',
      emoji: '🏆',
      titleEn: 'Grade 2 Champion',
      titleSi: 'දෙවන ශ්‍රේණියේ ශූරයා',
      subtitleEn: 'Advanced mixed literacy challenge',
      subtitleSi: 'උසස් මිශ්‍ර භාෂා කුසලතා අභියෝගය',
      questionCount: 12,
      optionCount: 4,
    ),
  ];

  static bool isUnlocked(int level, Map<int, double> bestPercentages) {
    if (level <= 1) return true;
    return (bestPercentages[level - 1] ?? 0) >= unlockPercentage;
  }
}

class Grade2LevelQuestion {
  final Grade2QuestionMode mode;
  final String promptEn;
  final String promptSi;
  final String display;
  final String? emoji;
  final String answer;
  final List<String> options;
  final String itemId;

  const Grade2LevelQuestion({
    required this.mode,
    required this.promptEn,
    required this.promptSi,
    required this.display,
    required this.answer,
    required this.options,
    required this.itemId,
    this.emoji,
  });
}

class Grade2ComprehensionItem {
  final String passage;
  final String question;
  final String answer;
  final List<String> distractors;

  const Grade2ComprehensionItem({
    required this.passage,
    required this.question,
    required this.answer,
    required this.distractors,
  });
}

abstract final class Grade2LevelTask {
  static const List<Grade2ComprehensionItem> comprehensionItems = [
    Grade2ComprehensionItem(
      passage: 'අම්මා කෑම උයනවා.',
      question: 'කෑම උයන්නේ කවුද?',
      answer: 'අම්මා',
      distractors: ['තාත්තා', 'ළමයා', 'බළලා'],
    ),
    Grade2ComprehensionItem(
      passage: 'තාත්තා ගෙදර එනවා.',
      question: 'තාත්තා එන්නේ කොහෙටද?',
      answer: 'ගෙදරට',
      distractors: ['පාසලට', 'කඩයට', 'වත්තට'],
    ),
    Grade2ComprehensionItem(
      passage: 'මම පාසලට යනවා.',
      question: 'මම යන්නේ කොහෙටද?',
      answer: 'පාසලට',
      distractors: ['ගෙදරට', 'වත්තට', 'ගඟට'],
    ),
    Grade2ComprehensionItem(
      passage: 'ළමයා පොත කියවනවා.',
      question: 'ළමයා කියවන්නේ කුමක්ද?',
      answer: 'පොත',
      distractors: ['පුවරුව', 'ගස', 'බෝලය'],
    ),
    Grade2ComprehensionItem(
      passage: 'සුනෙත්‍රා සෙල්ලම් කරනවා.',
      question: 'සෙල්ලම් කරන්නේ කවුද?',
      answer: 'සුනෙත්‍රා',
      distractors: ['අම්මා', 'තාත්තා', 'ගුරුවරයා'],
    ),
    Grade2ComprehensionItem(
      passage: 'ගස ලොකු, ලස්සනයි.',
      question: 'ගස කොහොමද?',
      answer: 'ලොකු හා ලස්සනයි',
      distractors: ['කුඩායි', 'කැඩිලා', 'වියළියි'],
    ),
    Grade2ComprehensionItem(
      passage: 'අලි ගහ ළඟ ඉන්නවා.',
      question: 'අලි ඉන්නේ කොහෙද?',
      answer: 'ගහ ළඟ',
      distractors: ['ගෙදර', 'පාසලේ', 'ගඟේ'],
    ),
    Grade2ComprehensionItem(
      passage: 'බළලා කිරි බොනවා.',
      question: 'බළලා බොන්නේ කුමක්ද?',
      answer: 'කිරි',
      distractors: ['වතුර', 'තේ', 'කෑම'],
    ),
  ];

  static List<Grade2LevelQuestion> generate({
    required int level,
    Random? random,
  }) {
    final definition = Grade2LevelDefinition.levels[level - 1];
    final rng = random ?? Random();
    final questions = <Grade2LevelQuestion>[];
    for (var index = 0; index < definition.questionCount; index++) {
      final mode = _modeFor(level, index);
      questions.add(
        _questionFor(
          mode: mode,
          index: index,
          optionCount: definition.optionCount,
          random: rng,
        ),
      );
    }
    return questions;
  }

  static Grade2QuestionMode _modeFor(int level, int index) => switch (level) {
    1 => Grade2QuestionMode.identifyPillam,
    2 => Grade2QuestionMode.completePillam,
    3 => Grade2QuestionMode.pictureWord,
    4 => Grade2QuestionMode.completeSentence,
    5 => Grade2QuestionMode.comprehension,
    _ => Grade2QuestionMode.values[index % Grade2QuestionMode.values.length],
  };

  static Grade2LevelQuestion _questionFor({
    required Grade2QuestionMode mode,
    required int index,
    required int optionCount,
    required Random random,
  }) {
    return switch (mode) {
      Grade2QuestionMode.identifyPillam => _identifyPillam(
        index,
        optionCount,
        random,
      ),
      Grade2QuestionMode.completePillam => _completePillam(
        index,
        optionCount,
        random,
      ),
      Grade2QuestionMode.pictureWord => _pictureWord(
        index,
        optionCount,
        random,
      ),
      Grade2QuestionMode.completeSentence => _completeSentence(
        index,
        optionCount,
        random,
      ),
      Grade2QuestionMode.comprehension => _comprehension(
        index,
        optionCount,
        random,
      ),
    };
  }

  static Grade2LevelQuestion _identifyPillam(
    int index,
    int optionCount,
    Random random,
  ) {
    final core = Grade2Content.pillam
        .where((item) => item.category == 'core')
        .toList();
    final target = core[index % core.length];
    return Grade2LevelQuestion(
      mode: Grade2QuestionMode.identifyPillam,
      promptEn: 'Choose the correct Sinhala name',
      promptSi: 'නිවැරදි සිංහල නම තෝරන්න',
      display: 'ක${target.pillam}',
      answer: target.nameSi,
      options: _options(
        answer: target.nameSi,
        pool: core.map((item) => item.nameSi),
        count: optionCount,
        random: random,
      ),
      itemId: target.pillam,
    );
  }

  static Grade2LevelQuestion _completePillam(
    int index,
    int optionCount,
    Random random,
  ) {
    final items = Grade2Content.pillamFillWords;
    final target = items[index % items.length];
    return Grade2LevelQuestion(
      mode: Grade2QuestionMode.completePillam,
      promptEn: 'Which pillam completes this word?',
      promptSi: 'වචනය සම්පූර්ණ කරන පිල්ලම කුමක්ද?',
      display: '${target.before}□${target.after}',
      emoji: target.emoji,
      answer: target.answer,
      options: _options(
        answer: target.answer,
        pool: items.map((item) => item.answer),
        count: optionCount,
        random: random,
      ),
      itemId: target.word,
    );
  }

  static Grade2LevelQuestion _pictureWord(
    int index,
    int optionCount,
    Random random,
  ) {
    final words = Grade2Content.words;
    final target = words[index % words.length];
    return Grade2LevelQuestion(
      mode: Grade2QuestionMode.pictureWord,
      promptEn: 'Choose the word that matches the picture',
      promptSi: 'රූපයට ගැළපෙන වචනය තෝරන්න',
      display: target.emoji,
      answer: target.wordSi,
      options: _options(
        answer: target.wordSi,
        pool: words.map((item) => item.wordSi),
        count: optionCount,
        random: random,
      ),
      itemId: target.wordSi,
    );
  }

  static Grade2LevelQuestion _completeSentence(
    int index,
    int optionCount,
    Random random,
  ) {
    final words = Grade2Content.words;
    final target = words[index % words.length];
    final blank = target.sentence.replaceFirst(target.wordSi, '_____');
    return Grade2LevelQuestion(
      mode: Grade2QuestionMode.completeSentence,
      promptEn: 'Choose the word that completes the sentence',
      promptSi: 'වාක්‍යය සම්පූර්ණ කරන වචනය තෝරන්න',
      display: blank,
      emoji: target.emoji,
      answer: target.wordSi,
      options: _options(
        answer: target.wordSi,
        pool: words.map((item) => item.wordSi),
        count: optionCount,
        random: random,
      ),
      itemId: target.wordSi,
    );
  }

  static Grade2LevelQuestion _comprehension(
    int index,
    int optionCount,
    Random random,
  ) {
    final target = comprehensionItems[index % comprehensionItems.length];
    return Grade2LevelQuestion(
      mode: Grade2QuestionMode.comprehension,
      promptEn: 'Read and answer',
      promptSi: 'කියවා පිළිතුරු දෙන්න',
      display: '${target.passage}\n\n${target.question}',
      answer: target.answer,
      options: _options(
        answer: target.answer,
        pool: target.distractors,
        count: optionCount,
        random: random,
      ),
      itemId: target.question,
    );
  }

  static List<String> _options({
    required String answer,
    required Iterable<String> pool,
    required int count,
    required Random random,
  }) {
    final distractors = pool.where((item) => item != answer).toSet().toList()
      ..shuffle(random);
    final options = <String>[answer, ...distractors.take(count - 1)]
      ..shuffle(random);
    return options;
  }
}
