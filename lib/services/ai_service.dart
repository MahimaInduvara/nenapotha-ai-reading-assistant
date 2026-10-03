// lib/services/ai_service.dart
// AI brain for ReadBuddy — quiz generation, vocabulary, chat, recommendations

import '../models/story.dart';

// ── Data Models ────────────────────────────────────────────────────────────────

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

class VocabResult {
  final String word;
  final String definitionEn;
  final String definitionSi;
  final String exampleSentence;
  final String emoji;
  final List<String> synonyms;
  final List<String> antonyms;

  VocabResult({
    required this.word,
    required this.definitionEn,
    required this.definitionSi,
    required this.exampleSentence,
    required this.emoji,
    required this.synonyms,
    required this.antonyms,
  });
}

class ReadingRecommendation {
  final Story story;
  final String reason;
  final String reasonSi;
  final String level; // 'easier','same','harder','challenge'

  ReadingRecommendation({
    required this.story,
    required this.reason,
    required this.reasonSi,
    required this.level,
  });
}

class ChatResponse {
  final String text;
  final String? followUpQuestion;
  final bool triggerConfetti;
  final int wordsLearnedDelta;
  final LetterChoiceExercise? exercise;
  final ChatResponseSource source;
  final bool isError;

  ChatResponse({
    required this.text,
    this.followUpQuestion,
    this.triggerConfetti = false,
    this.wordsLearnedDelta = 0,
    this.exercise,
    this.source = ChatResponseSource.local,
    this.isError = false,
  });
}

enum ChatResponseSource { local, firebaseAI, fallback }

class LetterChoiceExercise {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  LetterChoiceExercise({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  }) : assert(options.length == 3),
       assert(options.contains(correctAnswer));
}

enum ChatIntent {
  greeting,
  letterSelectionTask,
  wordMeaning,
  quiz,
  storySummary,
  progress,
  reading,
  writing,
  help,
  unknown,
}

class ChatIntentResult {
  final ChatIntent intent;
  final ChatResponse? response;

  const ChatIntentResult({required this.intent, this.response});

  bool get isHandledLocally => response != null;
}

// ── Question Depth ────────────────────────────────────────────────────────────

/// Controls whether generated questions are literal (who/what/where) or
/// inferential (why/how/predict) — matching the Grade 1 vs Grade 2 curriculum split.
enum QuestionDepth { literal, inferential }

// ── AI Service ─────────────────────────────────────────────────────────────────

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // ── Chat ───────────────────────────────────────────────────────────────────

  ChatIntentResult routeChatIntent({
    required String userMessage,
    required String language,
    required int gradeLevel,
    Story? currentStory,
    int wordsLearned = 0,
  }) {
    final msg = userMessage.toLowerCase().trim();
    final isSi = _shouldReplyInSinhala(userMessage, language);
    final hasLetter = _matches(msg, const [
      'letter',
      'letters',
      'alphabet',
      'අකුර',
      'අකුරු',
      'අක්ෂර',
      'අක්ෂරය',
    ]);
    final hasLearningAction = _matches(msg, const [
      'choose',
      'choosing',
      'select',
      'selection',
      'task',
      'tasks',
      'exercise',
      'exercises',
      'practice',
      'remember',
      'තෝරන්න',
      'තෝරන',
      'තෝරා',
      'තේරීම',
      'කාර්යය',
      'කාර්යයන්',
      'අභ්‍යාසය',
      'අභ්‍යාස',
      'පුහුණුව',
      'මතක',
    ]);

    // Specific learning activities must be checked before broad words such
    // as "help". This prevents "letter tasks help me remember" from being
    // misclassified as a generic study-tip request.
    if (hasLetter && hasLearningAction) {
      return ChatIntentResult(
        intent: ChatIntent.letterSelectionTask,
        response: _buildLetterChoiceResponse(
          userMessage: userMessage,
          gradeLevel: _requestedGrade(userMessage, gradeLevel),
          isSi: isSi,
        ),
      );
    }

    if (_matches(msg, const [
      'mean',
      'meaning',
      'define',
      'explain',
      'word',
      'වචනය',
      'වචන',
      'අර්ථය',
      'අර්ථ',
      'තේරුම',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.wordMeaning,
        response: _generateLegacyChatResponse(
          userMessage: userMessage,
          language: isSi ? 'sinhala' : 'english',
          gradeLevel: gradeLevel,
          currentStory: currentStory,
          wordsLearned: wordsLearned,
        ),
      );
    }

    if (_matches(msg, const [
      'progress',
      'score',
      'how am i',
      'ප්‍රගතිය',
      'දියුණුව',
      'ලකුණු',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.progress,
        response: _generateLegacyChatResponse(
          userMessage: userMessage,
          language: isSi ? 'sinhala' : 'english',
          gradeLevel: gradeLevel,
          currentStory: currentStory,
          wordsLearned: wordsLearned,
        ),
      );
    }

    if (_matches(msg, const [
      'summary',
      'summarize',
      'story',
      'කතාව',
      'සාරාංශය',
      'සාරාංශ',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.storySummary,
        response: _generateLegacyChatResponse(
          userMessage: userMessage,
          language: isSi ? 'sinhala' : 'english',
          gradeLevel: gradeLevel,
          currentStory: currentStory,
          wordsLearned: wordsLearned,
        ),
      );
    }

    if (_matches(msg, const [
      'quiz',
      'question',
      'questions',
      'test',
      'practice',
      'ප්‍රශ්නය',
      'ප්‍රශ්න',
      'පරීක්ෂණය',
      'පරීක්ෂා',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.quiz,
        response: _generateLegacyChatResponse(
          userMessage: userMessage,
          language: isSi ? 'sinhala' : 'english',
          gradeLevel: gradeLevel,
          currentStory: currentStory,
          wordsLearned: wordsLearned,
        ),
      );
    }

    if (_matches(msg, const [
      'write',
      'writing',
      'trace',
      'handwriting',
      'ලියන්න',
      'ලිවීම',
      'ලියන',
      'අඳින්න',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.writing,
        response: ChatResponse(
          text: isSi
              ? '✍️ අකුරු ලිවීම පුහුණු කිරීමට Learn ටැබයේ Letter Tracing විවෘත කරන්න. මුලින් අකුර බලලා, පසුව රේඛාව මත සෙමින් අඳින්න.'
              : '✍️ Open Letter Tracing in the Learn tab. Look at the letter first, then trace it slowly along the guide.',
        ),
      );
    }

    if (_matches(msg, const [
      'read',
      'reading',
      'කියවන්න',
      'කියවීම',
      'කියවන',
      'කියවමු',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.reading,
        response: ChatResponse(
          text: isSi
              ? '📖 කියවීම පුහුණු කිරීමට ඔබේ ශ්‍රේණියට ගැලපෙන කතාවක් තෝරන්න. අමාරු වචනයක් තිබුණොත් ඒ වචනය මට එවන්න.'
              : '📖 Choose a story for Grade ${gradeLevel.clamp(1, 2)} and read one short section at a time. Send me any difficult word and I will explain it.',
        ),
      );
    }

    if (_matches(msg, const [
      'help',
      'task',
      'tasks',
      'exercise',
      'exercises',
      'choose',
      'select',
      'remember',
      'උදව්',
      'කාර්යය',
      'කාර්යයන්',
      'අභ්‍යාසය',
      'අභ්‍යාස',
      'තෝරන්න',
      'මතක',
    ])) {
      return ChatIntentResult(
        intent: ChatIntent.help,
        response: ChatResponse(text: _clarificationText(isSi)),
      );
    }

    if (_matches(msg, const ['hello', 'hi', 'hey', 'ayubowan', 'ආයුබෝවන්'])) {
      return ChatIntentResult(
        intent: ChatIntent.greeting,
        response: _generateLegacyChatResponse(
          userMessage: userMessage,
          language: isSi ? 'sinhala' : 'english',
          gradeLevel: gradeLevel,
          currentStory: currentStory,
          wordsLearned: wordsLearned,
        ),
      );
    }

    return const ChatIntentResult(intent: ChatIntent.unknown);
  }

  /// Backward-compatible local entry point. The hybrid chat screen uses
  /// [routeChatIntent] and sends unknown requests to the protected callable.
  ChatResponse generateChatResponse({
    required String userMessage,
    required String language,
    required int gradeLevel,
    Story? currentStory,
    int wordsLearned = 0,
  }) {
    final result = routeChatIntent(
      userMessage: userMessage,
      language: language,
      gradeLevel: gradeLevel,
      currentStory: currentStory,
      wordsLearned: wordsLearned,
    );
    return result.response ??
        ChatResponse(
          text: _clarificationText(
            _shouldReplyInSinhala(userMessage, language),
          ),
        );
  }

  ChatResponse _generateLegacyChatResponse({
    required String userMessage,
    required String language,
    required int gradeLevel,
    Story? currentStory,
    int wordsLearned = 0,
  }) {
    final msg = userMessage.toLowerCase().trim();
    final isSi = language == 'sinhala';

    // Greeting
    if (_matches(msg, ['hello', 'hi', 'ayubowan', 'ආයුබෝවන්'])) {
      return ChatResponse(
        text: isSi
            ? 'ආයුබෝවන්! 👋 මම NenaPotha AI! ඔබට කතා කියවීමට, වචන ඉගෙන ගැනීමට, සහ ප්‍රශ්න විසඳීමට මට හැකිය!'
            : 'Hello! 👋 I\'m NenaPotha AI! I can help you read stories, learn new words, and answer any questions!',
      );
    }

    // Word meaning
    if (_matches(msg, [
      'mean',
      'what is',
      'explain',
      'define',
      'word',
      'වචන',
      'අර්ථ',
    ])) {
      final word = _extractWord(userMessage);
      final result = lookupWord(word, gradeLevel);
      return ChatResponse(
        text: isSi
            ? '📖 "${result.word}" ${result.emoji}\n\n🇱🇰 සිංහල: ${result.definitionSi}\n🇬🇧 English: ${result.definitionEn}\n\n✏️ නිදසුන: ${result.exampleSentence}\n\n🔄 සමාන වචන: ${result.synonyms.join(', ')}'
            : '📖 "${result.word}" ${result.emoji}\n\n🇬🇧 Meaning: ${result.definitionEn}\n🇱🇰 Sinhala: ${result.definitionSi}\n\n✏️ Example: ${result.exampleSentence}\n\n🔄 Synonyms: ${result.synonyms.join(', ')}',
        triggerConfetti: true,
        wordsLearnedDelta: 1,
      );
    }

    // Quiz request
    if (_matches(msg, [
      'quiz',
      'question',
      'test',
      'practice',
      'ප්‍රශ්න',
      'පරීක්ෂා',
    ])) {
      final q = currentStory != null
          ? generateQuiz(currentStory, count: 1).first
          : _defaultQuestion(isSi);
      return ChatResponse(
        text: isSi
            ? '🧠 ප්‍රශ්නය:\n\n${q.question}\n\n${q.options.asMap().entries.map((e) => '${String.fromCharCode(65 + e.key)}) ${e.value}').join('\n')}'
            : '🧠 Question:\n\n${q.question}\n\n${q.options.asMap().entries.map((e) => '${String.fromCharCode(65 + e.key)}) ${e.value}').join('\n')}',
        followUpQuestion: q.correctAnswer,
      );
    }

    // Summarize
    if (_matches(msg, [
      'summary',
      'summarize',
      'about',
      'story',
      'කතාව',
      'සාරාංශ',
    ])) {
      if (currentStory != null) {
        return ChatResponse(
          text: isSi
              ? '📚 "${currentStory.titleSi}" කතාවේ සාරාංශය:\n\n${currentStory.contentSi.split(' ').take(40).join(' ')}...\n\n🌟 ශ්‍රේණිය ${currentStory.gradeLevel} • ${currentStory.wordCount} වචන'
              : '📚 Summary of "${currentStory.titleEn}":\n\n${currentStory.contentEn.split(' ').take(40).join(' ')}...\n\n🌟 Grade ${currentStory.gradeLevel} • ${currentStory.wordCount} words',
        );
      }
      return ChatResponse(
        text: isSi
            ? 'කරුණාකර කතාවක් තෝරා ගෙන ඒ ගැන විමසන්න! 📖'
            : 'Please select a story first and then ask me about it! 📖',
      );
    }

    // Progress
    if (_matches(msg, ['progress', 'how am i', 'score', 'ප්‍රගතිය', 'ලකුණු'])) {
      return ChatResponse(
        text: isSi
            ? '📊 ඔබේ ප්‍රගතිය:\n\n✅ ඔබ $_learnedWordsCount+ වචන ඉගෙනගෙන ඇත!\n🔥 ලස්සන ගමනක් යනවා!\n\n💡 ඉදිරියට: නව කතාවක් කියවා ඔබේ ලකුණු වැඩි කරගන්න!'
            : '📊 Your Progress:\n\n✅ You\'ve learned many new words!\n🔥 You\'re on a great journey!\n\n💡 Next: Read a new story to boost your score!',
        triggerConfetti: true,
      );
    }

    // Encouragement & reading together
    if (_matches(msg, [
      'read with',
      'read together',
      'help me read',
      'කියවමු',
    ])) {
      return ChatResponse(
        text: isSi
            ? '📖 අපි එකට කියවමු! ශ්‍රේණිය $gradeLevel සඳහා නිවැරදි කතාවක් තෝරා ගෙන "Reading" ටැබ් ඔබන්න. ඔබ කියවන විට, ඕනෑම වචනයක් ස්පර්ශ කළ විට මම ඒකේ අර්ථය කියනවා! 🌟'
            : '📖 Let\'s read together! Pick a story from the "Reading" tab for Grade $gradeLevel. When you read, tap any word and I\'ll explain it instantly! 🌟',
      );
    }

    // Vocabulary tips. Broad "help" requests are handled by the intent router
    // with a clarification question and never reach this branch.
    if (_matches(msg, ['tip', 'advice', 'ඉඟි'])) {
      final tips = isSi
          ? [
              '🌟 දිනකට නව වචන 5ක් ඉගෙනගන්න!',
              '📖 දිනපතා කතාවක් කියවන්න!',
              '🎯 ශ්‍රවණ කෙරෙහි අවධානය යොමු කරන්න!',
            ]
          : [
              '🌟 Learn 5 new words every day!',
              '📖 Read at least one story daily!',
              '🎯 Focus on understanding the main idea!',
            ];
      tips.shuffle();
      return ChatResponse(text: tips.first);
    }

    return ChatResponse(text: _clarificationText(isSi));
  }

  int _learnedWordsCount = 0;
  void incrementWords() => _learnedWordsCount++;

  bool _matches(String msg, List<String> keywords) {
    final messageTokens = _tokenize(msg);
    return keywords.any(
      (keyword) => _containsTokenSequence(messageTokens, _tokenize(keyword)),
    );
  }

  List<String> _tokenize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\u0D80-\u0DFF']+", unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);

  bool _containsTokenSequence(List<String> message, List<String> phrase) {
    if (phrase.isEmpty || phrase.length > message.length) return false;
    for (var start = 0; start <= message.length - phrase.length; start++) {
      var matches = true;
      for (var offset = 0; offset < phrase.length; offset++) {
        if (message[start + offset] != phrase[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  bool _shouldReplyInSinhala(String message, String preferredLanguage) {
    final hasSinhala = RegExp(
      r'[\u0D80-\u0DFF]',
      unicode: true,
    ).hasMatch(message);
    final hasEnglish = RegExp(r'[A-Za-z]').hasMatch(message);
    return hasSinhala || (!hasEnglish && preferredLanguage == 'sinhala');
  }

  int _requestedGrade(String message, int profileGrade) {
    final normalized = message.toLowerCase();
    if (_matches(normalized, const [
      'grade 1',
      'grade one',
      '1 ශ්‍රේණිය',
      'ශ්‍රේණිය 1',
      'පළමු ශ්‍රේණිය',
    ])) {
      return 1;
    }
    if (_matches(normalized, const [
      'grade 2',
      'grade two',
      '2 ශ්‍රේණිය',
      'ශ්‍රේණිය 2',
      'දෙවන ශ්‍රේණිය',
    ])) {
      return 2;
    }
    return profileGrade.clamp(1, 2);
  }

  String _clarificationText(bool isSi) => isSi
      ? 'මට නිවැරදි උදව්ව දෙන්න, ඔබට ඕනෑ දේ තෝරන්න: අකුරු තේරීමේ අභ්‍යාසයක්, කියවීම, ලිවීම, වචන අර්ථයක්, නැත්නම් ප්‍රගතිය ගැනද?'
      : 'Please tell me what you want: a letter-selection exercise, reading help, writing practice, a word meaning, or progress information?';

  ChatResponse _buildLetterChoiceResponse({
    required String userMessage,
    required int gradeLevel,
    required bool isSi,
  }) {
    final grade = gradeLevel.clamp(1, 2);
    final exercises = grade == 1
        ? <LetterChoiceExercise>[
            LetterChoiceExercise(
              question: isSi
                  ? '“ක” ශබ්දය ඇති අකුර තෝරන්න.'
                  : 'Choose the Sinhala letter that makes the “ka” sound.',
              options: const ['ක', 'ග', 'ත'],
              correctAnswer: 'ක',
              explanation: isSi
                  ? 'නිවැරදියි! “ක” අකුරෙන් “ක” ශබ්දය ලැබේ.'
                  : 'Correct! The letter ක makes the “ka” sound.',
            ),
            LetterChoiceExercise(
              question: isSi
                  ? '“ම” ශබ්දය ඇති අකුර තෝරන්න.'
                  : 'Choose the Sinhala letter that makes the “ma” sound.',
              options: const ['න', 'ම', 'බ'],
              correctAnswer: 'ම',
              explanation: isSi
                  ? 'නිවැරදියි! “ම” අකුරෙන් “ම” ශබ්දය ලැබේ.'
                  : 'Correct! The letter ම makes the “ma” sound.',
            ),
            LetterChoiceExercise(
              question: isSi
                  ? '“අ” ශබ්දය ඇති අකුර තෝරන්න.'
                  : 'Choose the Sinhala letter that makes the short “a” sound.',
              options: const ['ආ', 'ඇ', 'අ'],
              correctAnswer: 'අ',
              explanation: isSi
                  ? 'නිවැරදියි! මෙය “අ” අකුරයි.'
                  : 'Correct! This is the Sinhala letter අ.',
            ),
          ]
        : <LetterChoiceExercise>[
            LetterChoiceExercise(
              question: isSi
                  ? '“ගම” වචනය ආරම්භ වන අකුර තෝරන්න.'
                  : 'Choose the first letter of the Sinhala word “ගම”.',
              options: const ['ක', 'ග', 'ච'],
              correctAnswer: 'ග',
              explanation: isSi
                  ? 'නිවැරදියි! “ගම” වචනය “ග” අකුරෙන් ආරම්භ වේ.'
                  : 'Correct! ගම begins with the letter ග.',
            ),
            LetterChoiceExercise(
              question: isSi
                  ? '“මල” වචනය ආරම්භ වන අකුර තෝරන්න.'
                  : 'Choose the first letter of the Sinhala word “මල”.',
              options: const ['න', 'බ', 'ම'],
              correctAnswer: 'ම',
              explanation: isSi
                  ? 'නිවැරදියි! “මල” වචනය “ම” අකුරෙන් ආරම්භ වේ.'
                  : 'Correct! මල begins with the letter ම.',
            ),
            LetterChoiceExercise(
              question: isSi
                  ? '“බත” වචනය ආරම්භ වන අකුර තෝරන්න.'
                  : 'Choose the first letter of the Sinhala word “බත”.',
              options: const ['ප', 'බ', 'ද'],
              correctAnswer: 'බ',
              explanation: isSi
                  ? 'නිවැරදියි! “බත” වචනය “බ” අකුරෙන් ආරම්භ වේ.'
                  : 'Correct! බත begins with the letter බ.',
            ),
          ];
    final seed = userMessage.runes.fold<int>(grade, (sum, rune) => sum + rune);
    final exercise = exercises[seed % exercises.length];
    return ChatResponse(
      text: isSi
          ? '🎯 ශ්‍රේණිය $grade අකුරු තේරීමේ අභ්‍යාසය'
          : '🎯 Grade $grade letter-selection exercise',
      exercise: exercise,
    );
  }

  String _extractWord(String msg) {
    final words = msg.split(' ');
    const skip = {
      'what',
      'is',
      'does',
      'mean',
      'define',
      'the',
      'a',
      'explain',
    };
    return words.firstWhere(
      (w) => !skip.contains(w.toLowerCase()) && w.length > 2,
      orElse: () => 'beautiful',
    );
  }

  QuizQuestion _defaultQuestion(bool isSi) => QuizQuestion(
    type: 'mcq',
    question: isSi
        ? 'කතාවේ ප්‍රධාන චරිතය කෙතරම් නිර්භීතද?'
        : 'What is the main theme of most fables?',
    options: isSi
        ? ['ශ්‍රේෂ්ඨ ශූරයා', 'ජීවිතාවබෝධය', 'ශ්‍රී ලංකාව', 'ස්වභාවය']
        : ['Adventure', 'A life lesson', 'Nature', 'Animals'],
    correctAnswer: isSi ? 'ජීවිතාවබෝධය' : 'A life lesson',
    explanation: isSi
        ? 'නිවැරදියි! නාටිකා බොහෝවිට ජීවිතය පිළිබඳ දෙයක් කියයි.'
        : 'Correct! Fables usually teach us a life lesson.',
  );

  // ── Quiz Generator ─────────────────────────────────────────────────────────

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

  // ── Vocabulary ─────────────────────────────────────────────────────────────

  VocabResult lookupWord(String word, int gradeLevel) {
    final db = _vocabDatabase();
    final key = word.toLowerCase().trim();
    if (db.containsKey(key)) return db[key]!;

    // Fallback for unknown words
    return VocabResult(
      word: word,
      definitionEn: 'A word found in the story. Try using it in a sentence!',
      definitionSi:
          'කතාවේ දක්නා ලැබෙන වචනයකි. එය වාක්‍යයක භාවිතා කිරීමට උත්සාහ කරන්න!',
      exampleSentence: 'The $word was very interesting.',
      emoji: '📖',
      synonyms: ['interesting', 'notable'],
      antonyms: ['common', 'usual'],
    );
  }

  Map<String, VocabResult> _vocabDatabase() => {
    'elephant': VocabResult(
      word: 'Elephant',
      definitionEn: 'The largest land animal with a long trunk',
      definitionSi: 'දිගු කොඩිය ඇති විශාලම ගොඩගත් සතා',
      exampleSentence: 'The elephant splashed water with its trunk.',
      emoji: '🐘',
      synonyms: ['pachyderm', 'tusker'],
      antonyms: ['mouse', 'ant'],
    ),
    'beautiful': VocabResult(
      word: 'Beautiful',
      definitionEn: 'Very pleasing to look at or listen to',
      definitionSi: 'බැලීමට හෝ ඇසීමට ගොඩාක් ලස්සන',
      exampleSentence: 'The flowers in the garden are beautiful.',
      emoji: '🌸',
      synonyms: ['lovely', 'gorgeous', 'pretty'],
      antonyms: ['ugly', 'plain'],
    ),
    'brave': VocabResult(
      word: 'Brave',
      definitionEn: 'Ready to face danger without fear',
      definitionSi: 'බිය නොගෙන අනතුරට මුහුණ දීමට සූදානම්',
      exampleSentence: 'The brave lion protected the forest.',
      emoji: '🦁',
      synonyms: ['courageous', 'fearless', 'bold'],
      antonyms: ['cowardly', 'timid'],
    ),
    'kind': VocabResult(
      word: 'Kind',
      definitionEn: 'Friendly and generous to others',
      definitionSi: 'අන් අයට මිත්‍රශීලී සහ හදවතින් දෙන',
      exampleSentence: 'She was kind to the little mouse.',
      emoji: '💛',
      synonyms: ['gentle', 'caring', 'generous'],
      antonyms: ['cruel', 'mean'],
    ),
    'wisdom': VocabResult(
      word: 'Wisdom',
      definitionEn: 'The ability to make good decisions using knowledge',
      definitionSi: 'දැනුම භාවිතා කරමින් හොඳ තීරණ ගැනීමේ හැකියාව',
      exampleSentence: 'The old owl was known for its wisdom.',
      emoji: '🦉',
      synonyms: ['knowledge', 'intelligence', 'insight'],
      antonyms: ['foolishness', 'ignorance'],
    ),
    'forest': VocabResult(
      word: 'Forest',
      definitionEn: 'A large area covered with trees',
      definitionSi: 'ගස් වලින් ආවරණය වූ විශාල ප්‍රදේශයකි',
      exampleSentence: 'The animals lived deep in the forest.',
      emoji: '🌲',
      synonyms: ['woods', 'jungle', 'woodland'],
      antonyms: ['desert', 'city'],
    ),
    'ripe': VocabResult(
      word: 'Ripe',
      definitionEn: 'Fully grown and ready to eat',
      definitionSi: 'සම්පූර්ණයෙන් හැදී කෑමට සූදානම්',
      exampleSentence: 'The ripe mango was sweet and juicy.',
      emoji: '🥭',
      synonyms: ['mature', 'ready', 'developed'],
      antonyms: ['raw', 'unripe'],
    ),
    'journey': VocabResult(
      word: 'Journey',
      definitionEn: 'A long trip from one place to another',
      definitionSi: 'එක් ස්ථානයකින් තවත් ස්ථානයකට දිගු ගමනක්',
      exampleSentence: 'The crow began a long journey to find water.',
      emoji: '🗺️',
      synonyms: ['trip', 'voyage', 'adventure'],
      antonyms: ['stay', 'rest'],
    ),
    'magnificent': VocabResult(
      word: 'Magnificent',
      definitionEn: 'Impressively beautiful or grand',
      definitionSi: 'ආකර්ශනීය ලෙස ලස්සන හෝ ශ්‍රේෂ්ඨ',
      exampleSentence: 'The mountains were magnificent at sunrise.',
      emoji: '🏔️',
      synonyms: ['splendid', 'grand', 'glorious'],
      antonyms: ['ordinary', 'plain'],
    ),
    'biodiversity': VocabResult(
      word: 'Biodiversity',
      definitionEn: 'The variety of all living things in an area',
      definitionSi: 'ප්‍රදේශයක ජීවමාන සියල්ලේ විවිධත්වය',
      exampleSentence: 'Sri Lanka is famous for its rich biodiversity.',
      emoji: '🌿',
      synonyms: ['variety', 'richness', 'diversity'],
      antonyms: ['uniformity', 'sameness'],
    ),
  };

  // ── Adaptive Recommendation ────────────────────────────────────────────────

  ReadingRecommendation recommend({
    required double comprehensionScore,
    required int currentGrade,
    required int wordsLearned,
    required List<Story> allStories,
    required List<String> completedStoryIds,
  }) {
    final incomplete = allStories
        .where((s) => !completedStoryIds.contains(s.id))
        .toList();

    String level;
    int targetGrade;
    String reason;
    String reasonSi;

    if (comprehensionScore < 50) {
      level = 'easier';
      targetGrade = (currentGrade - 1).clamp(1, 2);
      reason =
          'Let\'s practice with an easier story to build your confidence! You\'re doing great!';
      reasonSi =
          'ඔබේ විශ්වාසය ගොඩනැගීමට පහසු කතාවකින් පුහුණු වෙමු! ඔබ ශ්‍රේෂ්ඨ!';
    } else if (comprehensionScore < 70) {
      level = 'same';
      targetGrade = currentGrade;
      reason = 'Keep practising at your current level — you\'re almost there!';
      reasonSi = 'ඔබේ වර්තමාන මට්ටමේ පුහුණු වෙමු — ඔබ ලඟ ළඟා වෙනවා!';
    } else if (comprehensionScore < 85) {
      level = 'harder';
      targetGrade = currentGrade;
      reason =
          'Great work! Try a slightly more challenging story with new vocabulary!';
      reasonSi =
          'ශ්‍රේෂ්ඨ කාර්යයි! නව වචන සහිත ටිකක් අභියෝගාත්මක කතාවක් උත්සාහ කරන්න!';
    } else {
      level = 'challenge';
      targetGrade = (currentGrade + 1).clamp(1, 2);
      reason = 'Outstanding! You\'re ready for the next grade level challenge!';
      reasonSi = 'අසාමාන්‍ය! ඔබ ඊළඟ ශ්‍රේණියේ අභියෝගයට සූදානම්!';
    }

    final candidates = incomplete
        .where((s) => s.gradeLevel == targetGrade)
        .toList();
    final fallback = incomplete
        .where((s) => s.gradeLevel == currentGrade)
        .toList();
    final pool = candidates.isNotEmpty
        ? candidates
        : (fallback.isNotEmpty ? fallback : allStories);
    pool.shuffle();
    final story = pool.first;

    return ReadingRecommendation(
      story: story,
      reason: reason,
      reasonSi: reasonSi,
      level: level,
    );
  }

  // ── Teacher Insights ───────────────────────────────────────────────────────
}
