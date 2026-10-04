// lib/services/quiz_generation_service.dart
// Deterministic grade-aware comprehension-question generation.

import '../models/story.dart';

class QuizQuestion {
  final String type; // 'mcq','truefalse','fill','sequence','short'
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

enum QuestionDepth { literal, inferential }

class QuizGenerationService {
  /// Generates quiz questions for [story] at the appropriate grade level.
  ///
  /// Grade 1: only `mcq` + `truefalse`, literal depth, picture-friendly prompts.
  /// Grade 2: all types, 70% literal + 30% inferential.
  List<QuizQuestion> generateQuiz(
    Story story, {
    int count = 5,
    QuestionDepth depth = QuestionDepth.literal,
    int gradeLevel = 2,
  }) {
    final content = story.contentEn;
    final titleEn = story.titleEn;
    final vocabEn = story.vocabularyWordsEn;
    final questions = <QuizQuestion>[];

    // ── Grade 1: recognition-only (2 types, picture-prompt framing) ─────────
    if (gradeLevel <= 1) {
      questions.add(
        QuizQuestion(
          type: 'mcq',
          question:
              'Look at the story picture! Who is the main character in "$titleEn"? 🖼️',
          options: [
            _mainCharacterFor(story),
            'A big elephant 🐘',
            'A little bird 🐦',
            'A kind farmer 👨‍🌾',
          ],
          correctAnswer: _mainCharacterFor(story),
          explanation: 'Great job! You found the main character! 🌟',
        ),
      );
      final firstSentence = content.split('.').first.trim();
      questions.add(
        QuizQuestion(
          type: 'truefalse',
          question: '👀 Read carefully! Is this true? "$firstSentence."',
          options: ['✅ True', '❌ False'],
          correctAnswer: '✅ True',
          explanation: 'Yes! This is what happens in the story! 🎉',
        ),
      );
      // Add a second MCQ about setting for Grade 1
      questions.add(
        QuizQuestion(
          type: 'mcq',
          question: 'Where does the story "$titleEn" happen? 🗺️',
          options: [
            _settingFor(story),
            'In a big city 🏙️',
            'On a spaceship 🚀',
            'Under the sea 🌊',
          ],
          correctAnswer: _settingFor(story),
          explanation: 'Amazing! You remembered where the story takes place! ⭐',
        ),
      );
      return questions.take(count).toList();
    }

    // ── Grade 2: all types, mix literal + inferential ────────────────────────

    // 1. MCQ — Main idea (literal)
    questions.add(
      QuizQuestion(
        type: 'mcq',
        question: 'What is the main idea of "$titleEn"?',
        options: [
          _mainIdeaFor(story),
          'A story about the weather',
          'A journey through mountains',
          'A lesson about numbers',
        ],
        correctAnswer: _mainIdeaFor(story),
        explanation:
            'The story focuses on ${_mainIdeaFor(story).toLowerCase()}.',
      ),
    );

    // 2. True/False (literal)
    final firstSentence = content.split('.').first.trim();
    questions.add(
      QuizQuestion(
        type: 'truefalse',
        question: 'True or False: "$firstSentence."',
        options: ['True', 'False'],
        correctAnswer: 'True',
        explanation: 'This is directly stated at the beginning of the story.',
      ),
    );

    // 3. Fill in the blank (literal — Grade 2 vocabulary expansion)
    if (vocabEn.isNotEmpty) {
      final word = vocabEn.first;
      final sentence = _findSentenceWith(content, word);
      final blank = sentence.replaceAll(
        RegExp(word, caseSensitive: false),
        '______',
      );
      questions.add(
        QuizQuestion(
          type: 'fill',
          question: 'Fill in the blank: "$blank"',
          options: [word, ...vocabEn.skip(1).take(3)],
          correctAnswer: word,
          explanation: '"$word" is the correct word that fits here.',
        ),
      );
    }

    // 4. Sequencing (literal — event ordering, curriculum: "identify sequence")
    questions.add(
      QuizQuestion(
        type: 'sequence',
        question: 'What happens FIRST in the story "$titleEn"?',
        options: _getSequenceOptions(story),
        correctAnswer: _getSequenceOptions(story).first,
        explanation: 'This is the opening event of the story.',
      ),
    );

    // 5. Inferential — Grade 2 only (why/predict, ~30% of questions)
    if (gradeLevel >= 2 && depth == QuestionDepth.inferential) {
      questions.add(
        QuizQuestion(
          type: 'mcq',
          question:
              'Why do you think ${_mainCharacterFor(story)} acted that way? 🤔',
          options: [
            _inferentialReasonFor(story),
            'Because they were hungry',
            'Because the weather changed',
            'Because a friend told them to',
          ],
          correctAnswer: _inferentialReasonFor(story),
          explanation: _inferentialReasonFor(story),
        ),
      );
      questions.add(
        QuizQuestion(
          type: 'short',
          question:
              'What do you think might happen next after the story ends? 💭',
          options: [],
          correctAnswer: _inferentialPredictionFor(story),
          explanation: _inferentialPredictionFor(story),
        ),
      );
    }

    // 6. Short Answer — lesson (Grade 2 critical thinking)
    questions.add(
      QuizQuestion(
        type: 'short',
        question: 'In your own words, what lesson does "$titleEn" teach us?',
        options: [],
        correctAnswer: _moralFor(story),
        explanation: _moralFor(story),
      ),
    );

    return questions.take(count).toList();
  }

  String _mainIdeaFor(Story story) {
    final map = {
      'g1_s1': 'An elephant enjoying ripe bananas',
      'g1_s2': 'A cat that loves milk and is grateful',
      'g1_s3': 'A boy finding and playing with his red ball',
      'g1_s4': 'A girl flying her colourful kite with her father',
      'g1_s5': 'A girl using an umbrella safely on a rainy school day',
      'g2_s1': 'A lion helped by a mouse he once spared',
      'g2_s2': 'Daily care making a garden beautiful',
      'g2_s3': 'A child returning a lost pencil honestly',
      'g2_s4': 'Birds working together to help thirsty animals',
      'g2_s5': 'A child caring responsibly for a shared library book',
    };
    return map[story.id] ??
        'Characters facing a challenge and learning something';
  }

  String _mainCharacterFor(Story story) {
    final map = {
      'g1_s1': 'Sindu, the little elephant 🐘',
      'g1_s2': 'Mini, the little cat 🐱',
      'g1_s3': 'Nimal 👦',
      'g1_s4': 'Ama 👧',
      'g1_s5': 'Dinu 👧',
      'g2_s1': 'A brave lion 🦁',
      'g2_s2': 'Senuli 👧',
      'g2_s3': 'Ravindu 👦',
      'g2_s4': 'A group of helpful birds 🐦',
      'g2_s5': 'Kavindu 👦',
    };
    return map[story.id] ?? 'A brave and kind animal 🐾';
  }

  String _settingFor(Story story) {
    final map = {
      'g1_s1': 'Near a banana tree 🌿',
      'g1_s2': 'At home 🏡',
      'g1_s3': 'In Nimal’s garden 🌳',
      'g1_s4': 'In an open field 🌤️',
      'g1_s5': 'On the way to school ☔',
      'g2_s1': 'In the jungle 🌳',
      'g2_s2': 'In Senuli’s garden 🌷',
      'g2_s3': 'In a classroom 🏫',
      'g2_s4': 'In a dry forest 🌳',
      'g2_s5': 'At the school library 📚',
    };
    return map[story.id] ?? 'In a beautiful forest 🌲';
  }

  String _inferentialReasonFor(Story story) {
    final map = {
      'g2_s1':
          'Because the mouse had shown kindness earlier, and kindness deserves kindness.',
      'g2_s2':
          'Because Senuli cared about living things and took responsibility for her garden.',
      'g2_s3':
          'Because Ravindu knew that returning the pencil was honest and helpful.',
      'g2_s4':
          'Because working together allowed the birds to carry enough water.',
      'g2_s5':
          'Because Kavindu wanted the next reader to receive a clean book.',
    };
    return map[story.id] ??
        'Because they wanted to help others and do what was right.';
  }

  String _inferentialPredictionFor(Story story) {
    final map = {
      'g1_s1':
          'The elephant might share the bananas with its friends next time.',
      'g1_s2': 'The cat might help the family in return for their kindness.',
      'g1_s3': 'Nimal might invite a friend to play with the ball.',
      'g1_s4': 'Ama might make another kite with different colours.',
      'g1_s5': 'Dinu might share her umbrella with a friend after school.',
      'g2_s1':
          'The lion and mouse might become best friends and help each other again.',
      'g2_s2': 'Senuli might plant more flowers and care for them each day.',
      'g2_s3': 'Ravindu and Nethmi might become helpful friends.',
      'g2_s4': 'The animals might work together to protect the old well.',
      'g2_s5': 'Kavindu might borrow another book and care for it well.',
    };
    return map[story.id] ??
        'The characters might continue to help each other and grow wiser.';
  }

  String _moralFor(Story story) {
    final map = {
      'g1_s1': 'Enjoy simple things and return home safely.',
      'g1_s2': 'Be thankful when someone cares for you.',
      'g1_s3': 'Keep trying calmly when something is lost.',
      'g1_s4': 'Time spent learning and playing with family brings joy.',
      'g1_s5': 'Good preparation helps us travel safely in rainy weather.',
      'g2_s1': 'Even small acts of kindness can make a big difference.',
      'g2_s2': 'Small responsible actions create a beautiful difference.',
      'g2_s3': 'Honesty helps others and makes us feel proud.',
      'g2_s4': 'Teamwork can solve a problem that is too hard for one person.',
      'g2_s5':
          'Shared belongings should be used carefully and returned on time.',
    };
    return map[story.id] ??
        'Every story teaches us something valuable about life.';
  }

  String _findSentenceWith(String content, String word) {
    final sentences = content.split('.');
    return sentences
        .firstWhere(
          (s) => s.toLowerCase().contains(word.toLowerCase()),
          orElse: () => sentences.first,
        )
        .trim();
  }

  List<String> _getSequenceOptions(Story story) {
    final sentences = story.contentEn
        .split('.')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.length >= 4) {
      return [
        sentences[0].trim(),
        sentences[sentences.length ~/ 3].trim(),
        sentences[sentences.length * 2 ~/ 3].trim(),
        sentences.last.trim(),
      ];
    }
    return ['Beginning of story', 'Middle of story', 'Climax', 'End of story'];
  }
}
