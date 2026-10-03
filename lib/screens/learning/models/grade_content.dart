// lib/screens/learning/models/grade_content.dart

class LetterItem {
  final String letter;
  final String sound;
  final String exampleWord;
  final String exampleWordEn;
  final String emoji;
  // Additional words that start with/relate to this letter, shown in the
  // letter detail screen's word list (beyond the single featured exampleWord).
  final List<String> moreWords;
  LetterItem({
    required this.letter,
    required this.sound,
    required this.exampleWord,
    required this.exampleWordEn,
    required this.emoji,
    this.moreWords = const [],
  });
}

class PillamItem {
  final String pillam; // the vowel sign itself, e.g. ැ
  final String name; // curriculum name transliterated for the English UI
  final String nameSi; // curriculum name in Sinhala
  final String soundSi; // the resulting vowel sound, e.g. "ඇ" — "(නිශ්ශබ්ද)"
  // for හල් කිරීම, which removes the vowel rather than adding one.
  final String soundEn; // e.g. "æ" — "no vowel" for හල් කිරීම.
  // Real words showing this pillam on a couple of different base
  // consonants, mirroring LetterItem.moreWords — e.g. ['කාසිය', 'මාළු'].
  final List<String> examples;
  // 'core' = the 12 pillam every Grade 2 curriculum teaches. 'bonus' = the
  // rarer Sanskrit-derived vocalic-r signs and the special ර/න conjunct
  // shapes — real and correct, but not something every student needs yet.
  final String category;
  PillamItem({
    required this.pillam,
    required this.name,
    required this.nameSi,
    required this.soundSi,
    required this.soundEn,
    required this.examples,
    this.category = 'core',
  });
}

class PillamFillItem {
  final String word; // full correct word, e.g. 'කාසිය'
  final String before; // word text before the blank
  final String after; // word text after the blank
  final String answer; // the pillam glyph that fills the blank
  final String emoji;
  PillamFillItem({
    required this.word,
    required this.before,
    required this.after,
    required this.answer,
    required this.emoji,
  });
}

class PillamNamingQuestion {
  final String pillam; // the vowel sign shown to the student, e.g. ා
  // Exactly 3 name choices, in the authored display order (not shuffled —
  // this is curated quiz content, not procedurally generated).
  final List<String> options;
  final int correctIndex;
  const PillamNamingQuestion({
    required this.pillam,
    required this.options,
    required this.correctIndex,
  });
}

class VocabWord {
  final String wordSi;
  final String wordEn;
  final String emoji;
  final String sentence;
  VocabWord({
    required this.wordSi,
    required this.wordEn,
    required this.emoji,
    required this.sentence,
  });
}

class Grade1Content {
  // ── ස්වර (Simple Vowels) ────────────────────────────────────────────
  // ── ව්‍යංජන (Primary Consonants) ──────────────────────────────────
  // Per-letter word lists, per the Grade 1 curriculum. English glosses are
  // deliberately left blank rather than guessed — many of these words don't
  // have an unambiguous one-word English translation, and a wrong gloss in a
  // kids' literacy app is worse than no gloss. Add exampleWordEn once a
  // native speaker confirms. Emoji are only set where the word is
  // unambiguous (mango, sun, water, etc.) — '🔤' is a neutral placeholder
  // elsewhere rather than a guessed/wrong visual meaning.
  static final List<LetterItem> sinhalaLetters = [
    // Vowels — ස්වර
    LetterItem(
      letter: 'අ',
      sound: 'a',
      exampleWord: 'අඹ',
      exampleWordEn: '',
      emoji: '🥭',
      moreWords: const ['අහස', 'අලය', 'අත', 'අලස', 'අගය', 'අමර', 'අසල'],
    ),
    LetterItem(
      letter: 'ආ',
      sound: 'aa',
      exampleWord: 'ආගම',
      exampleWordEn: '',
      emoji: '🙏',
      moreWords: const ['ආදරය', 'ආලය', 'ආසනය', 'ආකලන', 'ආවරණ'],
    ),
    LetterItem(
      letter: 'ඇ',
      sound: 'ae',
      exampleWord: 'ඇණ',
      exampleWordEn: '',
      emoji: '🔩',
      moreWords: const ['ඇපය', 'ඇස', 'ඇටය', 'ඇල', 'ඇය', 'ඇම', 'ඇදය', 'ඇකය'],
    ),
    LetterItem(
      letter: 'ඉ',
      sound: 'i',
      exampleWord: 'ඉර',
      exampleWordEn: '',
      emoji: '☀️',
      moreWords: const [
        'ඉඩම',
        'ඉව',
        'ඉන',
        'ඉහත',
        'ඉරණම',
        'ඉඩ',
        'ඉවත',
        'ඉග',
        'ඉලපත',
      ],
    ),
    LetterItem(
      letter: 'ඊ',
      sound: 'ee',
      exampleWord: 'ඊතල',
      exampleWordEn: '',
      emoji: '🏹',
    ),
    LetterItem(
      letter: 'උ',
      sound: 'u',
      exampleWord: 'උදය',
      exampleWordEn: '',
      emoji: '🌅',
      moreWords: const ['උයන', 'උණ', 'උපත', 'උල', 'උමග', 'උස', 'උදරය'],
    ),
    LetterItem(
      letter: 'ඌ',
      sound: 'oo',
      exampleWord: 'ඌරා',
      exampleWordEn: '',
      emoji: '🐷',
    ),
    LetterItem(
      letter: 'එ',
      sound: 'e',
      exampleWord: 'එතන',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['එලව', 'එක', 'එම', 'එපමණ', 'එන', 'එකල', 'එරට'],
    ),
    LetterItem(
      letter: 'ඔ',
      sound: 'o',
      exampleWord: 'ඔපය',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['ඔවදන', 'ඔසද', 'ඔතන', 'ඔනම', 'ඔබ'],
    ),
    // Consonants — ව්‍යංජන
    LetterItem(
      letter: 'ක',
      sound: 'ka',
      exampleWord: 'කලය',
      exampleWordEn: '',
      emoji: '🏺',
      moreWords: const [
        'කඩය',
        'කණ',
        'කට',
        'කමත',
        'කරදරය',
        'කසය',
        'කත',
        'කර',
        'කවන',
      ],
    ),
    LetterItem(
      letter: 'ග',
      sound: 'ga',
      exampleWord: 'ගම',
      exampleWordEn: '',
      emoji: '🏘️',
      moreWords: const ['ගත', 'ගල', 'ගණන', 'ගස', 'ගගන'],
    ),
    LetterItem(
      letter: 'ච',
      sound: 'ca',
      exampleWord: 'චපල',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['චමර', 'චල'],
    ),
    LetterItem(
      letter: 'ජ',
      sound: 'ja',
      exampleWord: 'ජලය',
      exampleWordEn: '',
      emoji: '💧',
      moreWords: const ['ජන', 'ජනනය', 'ජය', 'ජනමය', 'ජනගහනය', 'ජනක'],
    ),
    LetterItem(
      letter: 'ට',
      sound: 'ta',
      exampleWord: 'ටයරය',
      exampleWordEn: '',
      emoji: '🛞',
      moreWords: const ['ටකය', 'ටකරම'],
    ),
    LetterItem(
      letter: 'ඩ',
      sound: 'da',
      exampleWord: 'ඩොල්ෆින',
      exampleWordEn: '',
      emoji: '🐬',
    ),
    LetterItem(
      letter: 'ත',
      sound: 'tha',
      exampleWord: 'තවම',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['තරණය', 'තණ', 'තල', 'තලය'],
    ),
    LetterItem(
      letter: 'ද',
      sound: 'da',
      exampleWord: 'දර',
      exampleWordEn: '',
      emoji: '🪵',
      moreWords: const ['දත', 'දනය', 'දමනය', 'දස', 'දවස', 'දහවල'],
    ),
    LetterItem(
      letter: 'න',
      sound: 'na',
      exampleWord: 'නය',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['නලය', 'නහය', 'නවය', 'නම', 'නවක', 'නතර', 'නවන'],
    ),
    LetterItem(
      letter: 'ප',
      sound: 'pa',
      exampleWord: 'පදය',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['පන', 'පමන', 'පවන', 'පලස', 'පස'],
    ),
    LetterItem(
      letter: 'බ',
      sound: 'ba',
      exampleWord: 'බලය',
      exampleWordEn: '',
      emoji: '💪',
      moreWords: const [
        'බවන',
        'බත',
        'බණ',
        'බතල',
        'බර',
        'බසය',
        'බස',
        'බලන',
        'බද',
      ],
    ),
    LetterItem(
      letter: 'ම',
      sound: 'ma',
      exampleWord: 'මල',
      exampleWordEn: '',
      emoji: '🌸',
      moreWords: const ['මරණය', 'මම', 'මව', 'මග', 'මතය', 'මතකය', 'මහරගම'],
    ),
    LetterItem(
      letter: 'ය',
      sound: 'ya',
      exampleWord: 'යන',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['යස', 'යට', 'යකඩය', 'යහන'],
    ),
    LetterItem(
      letter: 'ර',
      sound: 'ra',
      exampleWord: 'රට',
      exampleWordEn: '',
      emoji: '🌍',
      moreWords: const ['රසය', 'රවන', 'රතය', 'රළ', 'රණ'],
    ),
    LetterItem(
      letter: 'ල',
      sound: 'la',
      exampleWord: 'ලවන',
      exampleWordEn: '',
      emoji: '🧂',
      moreWords: const ['ලය', 'ලපය', 'ලගට'],
    ),
    LetterItem(
      letter: 'ව',
      sound: 'va',
      exampleWord: 'වත',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['වනය', 'වටය', 'වම', 'වමනය', 'වදය', 'වල', 'වයස'],
    ),
    LetterItem(
      letter: 'ස',
      sound: 'sa',
      exampleWord: 'සද',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['සමය', 'සයන', 'සහන', 'සම', 'සවල', 'සරම', 'සමරන'],
    ),
    LetterItem(
      letter: 'හ',
      sound: 'ha',
      exampleWord: 'හත',
      exampleWordEn: '',
      emoji: '🔤',
      moreWords: const ['හද', 'හය', 'හවස', 'හදවත', 'හමන', 'හම'],
    ),
  ];

  static final List<LetterItem> englishLetters = [
    LetterItem(
      letter: 'A',
      sound: 'ay',
      exampleWord: 'Apple',
      exampleWordEn: 'Apple',
      emoji: '🍎',
    ),
    LetterItem(
      letter: 'B',
      sound: 'bee',
      exampleWord: 'Ball',
      exampleWordEn: 'Ball',
      emoji: '⚽',
    ),
    LetterItem(
      letter: 'C',
      sound: 'see',
      exampleWord: 'Cat',
      exampleWordEn: 'Cat',
      emoji: '🐱',
    ),
    LetterItem(
      letter: 'D',
      sound: 'dee',
      exampleWord: 'Dog',
      exampleWordEn: 'Dog',
      emoji: '🐶',
    ),
    LetterItem(
      letter: 'E',
      sound: 'ee',
      exampleWord: 'Egg',
      exampleWordEn: 'Egg',
      emoji: '🥚',
    ),
    LetterItem(
      letter: 'F',
      sound: 'ef',
      exampleWord: 'Fish',
      exampleWordEn: 'Fish',
      emoji: '🐟',
    ),
    LetterItem(
      letter: 'G',
      sound: 'jee',
      exampleWord: 'Goat',
      exampleWordEn: 'Goat',
      emoji: '🐐',
    ),
    LetterItem(
      letter: 'H',
      sound: 'aych',
      exampleWord: 'Hat',
      exampleWordEn: 'Hat',
      emoji: '🎩',
    ),
    LetterItem(
      letter: 'I',
      sound: 'eye',
      exampleWord: 'Ice cream',
      exampleWordEn: 'Ice cream',
      emoji: '🍦',
    ),
    LetterItem(
      letter: 'J',
      sound: 'jay',
      exampleWord: 'Jar',
      exampleWordEn: 'Jar',
      emoji: '🫙',
    ),
    LetterItem(
      letter: 'K',
      sound: 'kay',
      exampleWord: 'Kite',
      exampleWordEn: 'Kite',
      emoji: '🪁',
    ),
    LetterItem(
      letter: 'L',
      sound: 'el',
      exampleWord: 'Lion',
      exampleWordEn: 'Lion',
      emoji: '🦁',
    ),
    LetterItem(
      letter: 'M',
      sound: 'em',
      exampleWord: 'Moon',
      exampleWordEn: 'Moon',
      emoji: '🌙',
    ),
    LetterItem(
      letter: 'N',
      sound: 'en',
      exampleWord: 'Nest',
      exampleWordEn: 'Nest',
      emoji: '🪺',
    ),
    LetterItem(
      letter: 'O',
      sound: 'oh',
      exampleWord: 'Orange',
      exampleWordEn: 'Orange',
      emoji: '🍊',
    ),
    LetterItem(
      letter: 'P',
      sound: 'pee',
      exampleWord: 'Pen',
      exampleWordEn: 'Pen',
      emoji: '✏️',
    ),
    LetterItem(
      letter: 'Q',
      sound: 'cue',
      exampleWord: 'Queen',
      exampleWordEn: 'Queen',
      emoji: '👑',
    ),
    LetterItem(
      letter: 'R',
      sound: 'ar',
      exampleWord: 'Rain',
      exampleWordEn: 'Rain',
      emoji: '🌧️',
    ),
    LetterItem(
      letter: 'S',
      sound: 'es',
      exampleWord: 'Sun',
      exampleWordEn: 'Sun',
      emoji: '☀️',
    ),
    LetterItem(
      letter: 'T',
      sound: 'tee',
      exampleWord: 'Tree',
      exampleWordEn: 'Tree',
      emoji: '🌳',
    ),
    LetterItem(
      letter: 'U',
      sound: 'you',
      exampleWord: 'Umbrella',
      exampleWordEn: 'Umbrella',
      emoji: '☂️',
    ),
    LetterItem(
      letter: 'V',
      sound: 'vee',
      exampleWord: 'Van',
      exampleWordEn: 'Van',
      emoji: '🚐',
    ),
    LetterItem(
      letter: 'W',
      sound: 'double-u',
      exampleWord: 'Water',
      exampleWordEn: 'Water',
      emoji: '💧',
    ),
    LetterItem(
      letter: 'X',
      sound: 'ex',
      exampleWord: 'X-ray',
      exampleWordEn: 'X-ray',
      emoji: '🔬',
    ),
    LetterItem(
      letter: 'Y',
      sound: 'why',
      exampleWord: 'Yarn',
      exampleWordEn: 'Yarn',
      emoji: '🧶',
    ),
    LetterItem(
      letter: 'Z',
      sound: 'zee',
      exampleWord: 'Zebra',
      exampleWordEn: 'Zebra',
      emoji: '🦓',
    ),
  ];

  static final List<VocabWord> simpleWords = [
    VocabWord(
      wordSi: 'මම',
      wordEn: 'I / Me',
      emoji: '👦',
      sentence: 'මම ළමයෙක්.',
    ),
    VocabWord(
      wordSi: 'ඔබ',
      wordEn: 'You',
      emoji: '👉',
      sentence: 'ඔබ හොඳ ළමයෙකු.',
    ),
    VocabWord(
      wordSi: 'අම්මා',
      wordEn: 'Mother',
      emoji: '👩',
      sentence: 'අම්මා කෑම හදනවා.',
    ),
    VocabWord(
      wordSi: 'තාත්තා',
      wordEn: 'Father',
      emoji: '👨',
      sentence: 'තාත්තා ගෙදර ඉන්නවා.',
    ),
    VocabWord(
      wordSi: 'ගෙදර',
      wordEn: 'Home',
      emoji: '🏠',
      sentence: 'මගේ ගෙදර ලස්සනයි.',
    ),
    VocabWord(
      wordSi: 'පාසල',
      wordEn: 'School',
      emoji: '🏫',
      sentence: 'පාසල ළඟ ඉන්නවා.',
    ),
    VocabWord(
      wordSi: 'කෑම',
      wordEn: 'Food',
      emoji: '🍽️',
      sentence: 'කෑම රසයි.',
    ),
    VocabWord(
      wordSi: 'ඇස',
      wordEn: 'Eye',
      emoji: '👁️',
      sentence: 'ඇස ලස්සනයි.',
    ),
    VocabWord(
      wordSi: 'කට',
      wordEn: 'Mouth',
      emoji: '👄',
      sentence: 'කට විශාලයි.',
    ),
    VocabWord(
      wordSi: 'නාය',
      wordEn: 'Water',
      emoji: '💧',
      sentence: 'නාය 차늘 ශීතලයි.',
    ),
  ];
}

class Grade2Content {
  // The 12 pillam (vowel signs — including හල් කිරීම, the mark that removes
  // the vowel entirely) every Grade 2 curriculum teaches, plus a 'bonus' set
  // of rarer Sanskrit-derived signs and special conjunct shapes — real and
  // correct, kept separate so they don't crowd out the core set. Each
  // entry's examples are real words on two different base consonants,
  // mirroring LetterItem's exampleWord/moreWords pattern from Grade 1.
  static final List<PillamItem> pillam = [
    // ── Core 12 ──────────────────────────────────────────────────────────
    PillamItem(
      pillam: 'ා',
      name: 'Aela-pilla',
      nameSi: 'ඇලපිල්ල',
      soundSi: 'ආ',
      soundEn: 'ā',
      examples: ['කාසිය', 'මාළු'],
    ),
    PillamItem(
      pillam: 'ැ',
      name: 'Keti aeda-pilla',
      nameSi: 'කෙටි ඇදපිල්ල',
      soundSi: 'ඇ',
      soundEn: 'æ',
      examples: ['කැලේ', 'වැලි'],
    ),
    PillamItem(
      pillam: 'ෑ',
      name: 'Dik aeda-pilla',
      nameSi: 'දික් ඇදපිල්ල',
      soundSi: 'ඈ',
      soundEn: 'ǣ',
      examples: ['කෑම', 'රෑ'],
    ),
    PillamItem(
      pillam: 'ි',
      name: 'Keti is-pilla',
      nameSi: 'කෙටි ඉස්පිල්ල',
      soundSi: 'ඉ',
      soundEn: 'i',
      examples: ['කිරි', 'මිතුරා'],
    ),
    PillamItem(
      pillam: 'ී',
      name: 'Dik is-pilla',
      nameSi: 'දික් ඉස්පිල්ල',
      soundSi: 'ඊ',
      soundEn: 'ī',
      examples: ['ගීතය', 'වීදුරුව'],
    ),
    PillamItem(
      pillam: 'ු',
      name: 'Keti paa-pilla',
      nameSi: 'කෙටි පාපිල්ල',
      soundSi: 'උ',
      soundEn: 'u',
      examples: ['කුරුල්ලා', 'පුතා'],
    ),
    PillamItem(
      pillam: 'ූ',
      name: 'Dik paa-pilla',
      nameSi: 'දික් පාපිල්ල',
      soundSi: 'ඌ',
      soundEn: 'ū',
      examples: ['කූඩය', 'පූජා'],
    ),
    PillamItem(
      pillam: 'ෙ',
      name: 'Kombuva',
      nameSi: 'කොම්බුව',
      soundSi: 'එ',
      soundEn: 'e',
      examples: ['කෙසෙල්', 'ගෙදර'],
    ),
    PillamItem(
      pillam: 'ේ',
      name: 'Kombuva with hal kirīma',
      nameSi: 'කොම්බුව සහ හල් කිරීම',
      soundSi: 'ඒ',
      soundEn: 'ē',
      examples: ['කේතලය', 'වේලාව'],
    ),
    PillamItem(
      pillam: 'ො',
      name: 'Kombuva with aela-pilla',
      nameSi: 'කොම්බුව සහිත ඇලපිල්ල',
      soundSi: 'ඔ',
      soundEn: 'o',
      examples: ['කොළඹ', 'මොනවා'],
    ),
    PillamItem(
      pillam: 'ෝ',
      name: 'Kombuva, aela-pilla with hal kirīma',
      nameSi: 'කොම්බුව, ඇලපිල්ල සහිත හල් කිරීම',
      soundSi: 'ඕ',
      soundEn: 'ō',
      examples: ['කෝප්පය', 'ලෝකය'],
    ),
    PillamItem(
      pillam: '්',
      name: 'Hal kirīma',
      nameSi: 'හල් කිරීම',
      soundSi: '(නිශ්ශබ්ද ස්වරය — ශබ්දයක් නැත)',
      soundEn: '(no vowel — pure consonant)',
      examples: ['බත්', 'මල්'],
    ),

    // ── Bonus: rarer signs & special shapes ─────────────────────────────
    PillamItem(
      pillam: 'ෞ',
      name: 'Kombuva with gayanukitta',
      nameSi: 'කොම්බුව හා ගයනුකිත්ත',
      soundSi: 'ඖ',
      soundEn: 'au',
      examples: ['කෞතුකාගාරය'],
      category: 'bonus',
    ),
    PillamItem(
      pillam: 'ෘ',
      name: 'Gaeta aela-pilla',
      nameSi: 'ගැට ඇලපිල්ල',
      soundSi: 'ඍ',
      soundEn: 'ri',
      examples: ['කෘතිම'],
      category: 'bonus',
    ),
    PillamItem(
      pillam: 'ෲ',
      name: 'Gaeta aela-pili deka',
      nameSi: 'ගැට ඇලපිලි දෙක',
      soundSi: 'ඎ',
      soundEn: 'ruu',
      examples: ['කෲර'],
      category: 'bonus',
    ),
    PillamItem(
      pillam: 'ු',
      name: 'Ra with keti paa-pilla (special shape)',
      nameSi: 'ර + කෙටි පාපිල්ල (විශේෂ හැඩය)',
      soundSi: 'රු',
      soundEn: 'ru (special shape)',
      examples: ['රුවන'],
      category: 'bonus',
    ),
    PillamItem(
      pillam: 'ූ',
      name: 'Ra with dik paa-pilla (special shape)',
      nameSi: 'ර + දික් පාපිල්ල (විශේෂ හැඩය)',
      soundSi: 'රූ',
      soundEn: 'ruu (special shape)',
      examples: ['රූමත්'],
      category: 'bonus',
    ),
    PillamItem(
      pillam: 'ු',
      name: 'Na with keti paa-pilla (special shape)',
      nameSi: 'න + කෙටි පාපිල්ල (විශේෂ හැඩය)',
      soundSi: 'නු',
      soundEn: 'nu (special shape)',
      examples: ['නුවන'],
      category: 'bonus',
    ),
    PillamItem(
      pillam: 'ූ',
      name: 'Na with dik paa-pilla (special shape)',
      nameSi: 'න + දික් පාපිල්ල (විශේෂ හැඩය)',
      soundSi: 'නූ',
      soundEn: 'nuu (special shape)',
      examples: ['නූල'],
      category: 'bonus',
    ),
  ];

  // Emoji cue per core pillam's example word (keyed by the pillam glyph
  // itself, since that's the only value both here and in `pillam` above are
  // guaranteed to spell identically — no Sinhala word text is retyped).
  static const Map<String, String> _pillamFillEmoji = {
    'ා': '🪙', // කාසිය
    'ැ': '🌳', // කැලේ
    'ෑ': '🍽️', // කෑම
    'ි': '🥛', // කිරි
    'ී': '🎵', // ගීතය
    'ු': '🐦', // කුරුල්ලා
    'ූ': '🧺', // කූඩය
    'ෙ': '🍌', // කෙසෙල්
    'ේ': '🫖', // කේතලය
    'ො': '🏙️', // කොළඹ
    'ෝ': '☕', // කෝප්පය
    '්': '🍚', // බත්
  };

  // Fill-in-the-blank task data: one question per core pillam, generated
  // from `pillam`'s own verified example words (via indexOf/substring)
  // rather than retyped by hand, so it can't drift out of sync or introduce
  // a subtly-wrong Unicode sequence.
  static final List<PillamFillItem> pillamFillWords = pillam
      .where((p) => p.category == 'core')
      .map((p) {
        final word = p.examples.first;
        final idx = word.indexOf(p.pillam);
        return PillamFillItem(
          word: word,
          before: word.substring(0, idx),
          after: word.substring(idx + p.pillam.length),
          answer: p.pillam,
          emoji: _pillamFillEmoji[p.pillam] ?? '❓',
        );
      })
      .toList();

  // "පිල්ලම හඳුනාගමු" (Let's Identify the Pillam) naming-quiz task: shown a
  // pillam glyph, the student picks its correct name from 3 options. Covers
  // all 12 core pillam — the 8 simple ones (සරල පිල්ලම්) plus the 4 compound
  // ones formed from kombuva (සංයුක්ත පිල්ලම්).
  static const List<PillamNamingQuestion> pillamNamingQuestions = [
    PillamNamingQuestion(
      pillam: '්',
      options: ['දික් ඇදපිල්ල', 'කොම්බුව', 'හල් කිරීම'],
      correctIndex: 2,
    ),
    PillamNamingQuestion(
      pillam: 'ා',
      options: ['හල් කිරීම', 'ඇලපිල්ල', 'කෙටි පාපිල්ල'],
      correctIndex: 1,
    ),
    PillamNamingQuestion(
      pillam: 'ැ',
      options: ['ඇලපිල්ල', 'දික් ඇදපිල්ල', 'කෙටි ඇදපිල්ල'],
      correctIndex: 2,
    ),
    PillamNamingQuestion(
      pillam: 'ෑ',
      options: ['දික් ඇදපිල්ල', 'කෙටි ඇදපිල්ල', 'කෙටි පාපිල්ල'],
      correctIndex: 0,
    ),
    PillamNamingQuestion(
      pillam: 'ි',
      options: ['කොම්බුව', 'කෙටි ඉස්පිල්ල', 'දික් ඉස්පිල්ල'],
      correctIndex: 1,
    ),
    PillamNamingQuestion(
      pillam: 'ී',
      options: ['දික් ඉස්පිල්ල', 'කෙටි ඇදපිල්ල', 'කෙටි ඉස්පිල්ල'],
      correctIndex: 0,
    ),
    PillamNamingQuestion(
      pillam: 'ු',
      options: ['දික් පාපිල්ල', 'කෙටි පාපිල්ල', 'හල් කිරීම'],
      correctIndex: 1,
    ),
    PillamNamingQuestion(
      pillam: 'ූ',
      options: ['කොම්බුව සහ හල් කිරීම', 'කෙටි පාපිල්ල', 'දික් පාපිල්ල'],
      correctIndex: 2,
    ),
    PillamNamingQuestion(
      pillam: 'ෙ',
      options: ['ඇලපිල්ල', 'කොම්බුව සහ ඇලපිල්ල', 'කොම්බුව'],
      correctIndex: 2,
    ),
    PillamNamingQuestion(
      pillam: 'ේ',
      options: ['කොම්බුව සහ හල් කිරීම', 'කොම්බුව', 'කොම්බුව සහිත ඇලපිල්ල'],
      correctIndex: 0,
    ),
    PillamNamingQuestion(
      pillam: 'ො',
      options: ['කොම්බුව', 'කොම්බුව සහිත ඇලපිල්ල', 'කොම්බුව සහ හල් කිරීම'],
      correctIndex: 1,
    ),
    PillamNamingQuestion(
      pillam: 'ෝ',
      options: [
        'දික් ඉස්පිල්ල',
        'කොම්බුව සහිත ඇලපිල්ල',
        'කොම්බුව, ඇලපිල්ල සහිත හල් කිරීම',
      ],
      correctIndex: 2,
    ),
  ];

  static final List<VocabWord> words = [
    VocabWord(
      wordSi: 'පිළිම',
      wordEn: 'Statue',
      emoji: '🗿',
      sentence: 'මේ ලස්සන පිළිමයක්.',
    ),
    VocabWord(
      wordSi: 'කියවන්න',
      wordEn: 'Read',
      emoji: '📖',
      sentence: 'පොතක් කියවන්න.',
    ),
    VocabWord(
      wordSi: 'ලිවීම',
      wordEn: 'Writing',
      emoji: '✏️',
      sentence: 'ලිවීම හොඳ පුරුද්දකි.',
    ),
    VocabWord(
      wordSi: 'ගිහින්',
      wordEn: 'Went',
      emoji: '🚶',
      sentence: 'ඔහු පාසලට ගිහින්.',
    ),
    VocabWord(
      wordSi: 'ආවා',
      wordEn: 'Came',
      emoji: '🏃',
      sentence: 'ඔහු ගෙදර ආවා.',
    ),
    VocabWord(
      wordSi: 'ගෙදර',
      wordEn: 'Home',
      emoji: '🏠',
      sentence: 'ගෙදර ලස්සනයි.',
    ),
    VocabWord(
      wordSi: 'පොත',
      wordEn: 'Book',
      emoji: '📚',
      sentence: 'මේ හොඳ පොතකි.',
    ),
    VocabWord(
      wordSi: 'සෙල්ලම්',
      wordEn: 'Play',
      emoji: '⚽',
      sentence: 'සෙල්ලම් කරමු.',
    ),
    VocabWord(
      wordSi: 'කෑම',
      wordEn: 'Food',
      emoji: '🍽️',
      sentence: 'කෑම රසයි.',
    ),
    VocabWord(
      wordSi: 'ගස',
      wordEn: 'Tree',
      emoji: '🌳',
      sentence: 'ගස ලොකුයි.',
    ),
  ];

  static final List<String> sentences = [
    'අම්මා කෑම උයනවා.',
    'තාත්තා ගෙදර එනවා.',
    'මම පාසලට යනවා.',
    'ළමයා පොත කියවනවා.',
    'සුනෙත්‍රා සෙල්ලම් කරනවා.',
    'ගස ලොකු, ලස්සනයි.',
    'අලි ගහ ළඟ ඉන්නවා.',
    'බළලා කිරි බොනවා.',
  ];
}
