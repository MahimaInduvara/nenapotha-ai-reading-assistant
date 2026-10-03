import '../models/story.dart';

/// Curated bilingual reading material for the two grades supported by ReadBuddy.
///
/// Each story uses short, age-appropriate sentences and contains the same meaning
/// in Sinhala and English so a child can learn either language from the app.
class StoryDataService {
  static final List<Story> _stories = [
    // ── GRADE 1: short, concrete stories with familiar words ────────────────
    Story(
      id: 'g1_s1',
      titleSi: 'අලියා සහ කෙසෙල්',
      titleEn: 'The Elephant and the Bananas',
      contentSi:
          'සිඳු පුංචි අලියා වේ. සිඳු කෙසෙල් දකියි. කෙසෙල් කහ පාටයි. සිඳු කෙසෙල් ගෙඩියක් කයි. එය රසයි. සිඳු ගෙදර යයි. අම්මාටත් කෙසෙල් ගෙඩියක් දෙයි.',
      contentEn:
          'Sindu is a little elephant. Sindu sees yellow bananas. He eats one banana. The banana is sweet. Sindu takes one banana home. He gives it to Mother.',
      gradeLevel: 1,
      difficulty: 'easy',
      wordCount: 23,
      vocabularyWordsSi: ['අලියා', 'කෙසෙල්', 'කහ', 'රසයි'],
      vocabularyWordsEn: ['elephant', 'banana', 'yellow', 'sweet'],
      thumbnailUrl: '🐘🍌',
    ),
    Story(
      id: 'g1_s2',
      titleSi: 'පුංචි බළලා',
      titleEn: 'The Little Cat',
      contentSi:
          'මිනි පුංචි බළලා වේ. මිනි කිරි දකියි. අම්මා කිරි බඳුනක් දෙයි. මිනි කිරි බොයි. කිරි රසයි. මිනි අම්මාට ස්තුති කරයි. මිනි සතුටින් සෙල්ලම් කරයි.',
      contentEn:
          'Mini is a little cat. Mini sees some milk. Mother gives her a bowl. Mini drinks the milk. The milk is good. Mini says thank you. She plays happily.',
      gradeLevel: 1,
      difficulty: 'easy',
      wordCount: 24,
      vocabularyWordsSi: ['බළලා', 'කිරි', 'බඳුනක්', 'සෙල්ලම්'],
      vocabularyWordsEn: ['cat', 'milk', 'bowl', 'plays'],
      thumbnailUrl: '🐱🥛',
    ),
    Story(
      id: 'g1_s3',
      titleSi: 'නිමල්ගේ රතු බෝලය',
      titleEn: 'Nimal’s Red Ball',
      contentSi:
          'නිමල්ට රතු බෝලයක් ඇත. නිමල් වත්තට යයි. ඔහු බෝලයට පයින් ගසයි. බෝලය ගස යට නවතියි. නිමල් බෝලය ගනියි. ඔහු සතුටින් සෙල්ලම් කරයි.',
      contentEn:
          'Nimal has a red ball. Nimal goes to the garden. He kicks the ball. The ball stops under a tree. Nimal gets the ball. He plays happily.',
      gradeLevel: 1,
      difficulty: 'easy',
      wordCount: 22,
      vocabularyWordsSi: ['රතු', 'බෝලය', 'වත්ත', 'ගස'],
      vocabularyWordsEn: ['red', 'ball', 'garden', 'tree'],
      thumbnailUrl: '👦⚽',
    ),
    Story(
      id: 'g1_s4',
      titleSi: 'පාට සරුංගලය',
      titleEn: 'The Colourful Kite',
      contentSi:
          'අමාට පාට සරුංගලයක් ඇත. එය රතු සහ කහ පාටයි. අමා තාත්තා සමඟ පිට්ටනියට යයි. සුළඟ හමයි. සරුංගලය උඩ යයි. අමා සතුටින් අත්පුඩි ගසයි.',
      contentEn:
          'Ama has a colourful kite. It is red and yellow. Ama goes to the field with Father. The wind blows. The kite goes up. Ama claps happily.',
      gradeLevel: 1,
      difficulty: 'medium',
      wordCount: 23,
      vocabularyWordsSi: ['සරුංගලය', 'පාට', 'සුළඟ', 'උඩ'],
      vocabularyWordsEn: ['kite', 'red', 'wind', 'up'],
      thumbnailUrl: '🪁🌈',
    ),
    Story(
      id: 'g1_s5',
      titleSi: 'වැසි දවසේ කුඩය',
      titleEn: 'The Rainy-Day Umbrella',
      contentSi:
          'අද වැස්ස වසියි. දිනූ පාසල් යයි. අම්මා කහ කුඩයක් දෙයි. දිනූ කුඩය අල්ලයි. ඇය වතුර වළක් දකියි. දිනූ පරිස්සමින් පාසලට යයි.',
      contentEn:
          'Rain falls today. Dinu goes to school. Mother gives her a yellow umbrella. Dinu holds the umbrella. She sees a puddle. Dinu walks safely to school.',
      gradeLevel: 1,
      difficulty: 'medium',
      wordCount: 21,
      vocabularyWordsSi: ['වැස්ස', 'කුඩය', 'වතුර', 'පාසල'],
      vocabularyWordsEn: ['rain', 'umbrella', 'puddle', 'school'],
      thumbnailUrl: '☔🏫',
    ),

    // ── GRADE 2: longer stories with sequence, values and inference ─────────
    Story(
      id: 'g2_s1',
      titleSi: 'සිංහයා සහ මීයා',
      titleEn: 'The Lion and the Mouse',
      contentSi:
          'එක් දිනක් සිංහයෙක් ගසක් යට නිදා සිටියේය. කුඩා මීයෙක් ඔහු අසල සෙල්ලම් කළේය. මීයා සිංහයාගේ ඇඟ මතින් දිව ගියේය. සිංහයා අවදි වී මීයා අල්ලා ගත්තේය. “මට සමාව දෙන්න. දිනක මම ඔබට උදව් කරන්නම්,” මීයා කීවේය. සිංහයා මීයාට යන්න දුන්නේය. දින කිහිපයකට පසු සිංහයා දඩයක්කරුගේ දැලකට හසු විය. මීයා පැමිණ දැල සපා කපා සිංහයා බේරා ගත්තේය. කුඩා මිතුරෙකුටත් ලොකු උදව්වක් කළ හැකි බව සිංහයා ඉගෙන ගත්තේය.',
      contentEn:
          'One day, a lion was sleeping under a tree. A little mouse played nearby and ran over the lion. The lion woke up and caught the mouse. “Please forgive me. I may help you one day,” said the mouse. The lion let the mouse go. A few days later, the lion was caught in a hunter’s net. The mouse came and chewed through the net. The lion was free. He learnt that even a small friend can give great help.',
      gradeLevel: 2,
      difficulty: 'easy',
      wordCount: 81,
      vocabularyWordsSi: ['සිංහයා', 'මීයා', 'දැල', 'බේරා'],
      vocabularyWordsEn: ['lion', 'mouse', 'net', 'free'],
      thumbnailUrl: '🦁🐭',
    ),
    Story(
      id: 'g2_s2',
      titleSi: 'සෙනුලිගේ උදෑසන වත්ත',
      titleEn: 'Senuli’s Morning Garden',
      contentSi:
          'සෙනුලි සෑම උදෑසනකම පාසල් යාමට පෙර වත්තට ගියාය. ඇය මල් පැළවලට වතුර දැමුවාය. දිනක් කුඩා සමනලයෙක් රෝස මලක් මත වසා සිටිනු ඇය දුටුවාය. සෙනුලි සමනලයාට බිය නොවන ලෙස නිහඬව සිටියාය. පසුව ඇය වියළි කොළ එකතු කර වත්ත පිරිසිදු කළාය. ටික දිනකින් වත්ත පාට පාට මල්වලින් පිරුණි. දිනපතා කරන කුඩා වැඩකින් ලස්සන වෙනසක් ඇති කළ හැකි බව සෙනුලි තේරුම් ගත්තාය.',
      contentEn:
          'Every morning, Senuli visited the garden before school. She watered the flower plants. One day, she saw a little butterfly resting on a rose. Senuli stood quietly so she would not frighten it. Then she collected the dry leaves and cleaned the garden. After a few days, the garden was full of colourful flowers. Senuli understood that a small job done every day can make a beautiful difference.',
      gradeLevel: 2,
      difficulty: 'medium',
      wordCount: 70,
      vocabularyWordsSi: ['උදෑසන', 'සමනලයා', 'නිහඬව', 'පිරිසිදු'],
      vocabularyWordsEn: ['morning', 'butterfly', 'quietly', 'cleaned'],
      thumbnailUrl: '🌷🦋',
    ),
    Story(
      id: 'g2_s3',
      titleSi: 'නැති වූ පැන්සල',
      titleEn: 'The Lost Pencil',
      contentSi:
          'පන්ති කාමරයේ බිම වැටී තිබූ අලුත් පැන්සලක් රවිඳු දුටුවේය. එය තමාගේ නොවන බව ඔහු දැන සිටියේය. ඔහු පැන්සල ගුරුතුමියට භාර දුන්නේය. මඳ වේලාවකට පසු නෙත්මි තම පැන්සල සොයමින් සිටියාය. ගුරුතුමිය පැන්සල නෙත්මිට ආපසු දුන්නාය. නෙත්මි රවිඳුට ස්තුති කළාය. නිවැරදි දේ කිරීමෙන් මිතුරෙකුට උදව් කළ හැකි වීම ගැන රවිඳු සතුටු විය.',
      contentEn:
          'Ravindu saw a new pencil on the classroom floor. He knew it did not belong to him, so he gave it to the teacher. A little later, Nethmi was looking for her pencil. The teacher returned it to her. Nethmi thanked Ravindu. He was happy because doing the right thing had helped a friend.',
      gradeLevel: 2,
      difficulty: 'medium',
      wordCount: 57,
      vocabularyWordsSi: ['පැන්සල', 'භාර', 'ආපසු', 'නිවැරදි'],
      vocabularyWordsEn: ['pencil', 'belong', 'returned', 'right'],
      thumbnailUrl: '✏️🤝',
    ),
    Story(
      id: 'g2_s4',
      titleSi: 'එකමුතු කුරුල්ලෝ',
      titleEn: 'The Helpful Birds',
      contentSi:
          'වියළි කාලය පැමිණි විට කැලයේ කුඩා පොකුණ සිඳී ගියේය. කුරුල්ලන්ට බීමට ජලය සොයා ගැනීම අපහසු විය. නායක කුරුල්ලා සියලු දෙනා එක්රැස් කළේය. ඔවුහු වනාන්තරය වටා පියාසර කර පැරණි ළිඳක් සොයා ගත්හ. එක් කුරුල්ලෙකුට පමණක් ජලය ගෙන යා නොහැකි විය. එබැවින් ඔවුහු කොළවලට ජලය ටික ටික පුරවා එකට රැගෙන ගියහ. සියලු දෙනා එකමුතුව වැඩ කළ නිසා පිපාසිත සතුන්ට ජලය ලැබුණි.',
      contentEn:
          'When the dry season came, the little pond in the forest dried up. The birds found it difficult to get drinking water. Their leader gathered everyone. They flew around the forest and found an old well. One bird could not carry enough water alone. Therefore, they filled leaves with a little water and carried them together. Because the birds worked as a team, the thirsty animals received water.',
      gradeLevel: 2,
      difficulty: 'hard',
      wordCount: 70,
      vocabularyWordsSi: ['වියළි', 'එක්රැස්', 'එකමුතුව', 'පිපාසිත'],
      vocabularyWordsEn: ['difficult', 'gathered', 'together', 'thirsty'],
      thumbnailUrl: '🐦💧',
    ),
    Story(
      id: 'g2_s5',
      titleSi: 'පුස්තකාලයේ පොත',
      titleEn: 'The Library Book',
      contentSi:
          'කවිඳු පාසල් පුස්තකාලයෙන් සතුන් පිළිබඳ පොතක් ලබා ගත්තේය. එහි ලස්සන පින්තූර සහ අලුත් තොරතුරු තිබුණි. ඔහු දිනපතා පොතෙන් පිටු කිහිපයක් කියෙව්වේය. පොත අපිරිසිදු නොවන ලෙස කවිඳු එය කවරයකින් ආරක්ෂා කළේය. සතිය අවසානයේ ඔහු නියමිත දිනට පොත ආපසු භාර දුන්නේය. ඊළඟ දරුවාටත් පොත පිරිසිදුව කියවීමට හැකි විය. පොදු දේපළ වගකීමෙන් රැකබලා ගත යුතු බව කවිඳු ඉගෙන ගත්තේය.',
      contentEn:
          'Kavindu borrowed a book about animals from the school library. It had beautiful pictures and new facts. He read a few pages every day. Kavindu covered the book to keep it clean. At the end of the week, he returned it on time. The next child could also enjoy the clean book. Kavindu learnt that shared things must be treated responsibly.',
      gradeLevel: 2,
      difficulty: 'hard',
      wordCount: 63,
      vocabularyWordsSi: ['පුස්තකාලය', 'තොරතුරු', 'ආරක්ෂා', 'වගකීමෙන්'],
      vocabularyWordsEn: ['library', 'facts', 'returned', 'responsibly'],
      thumbnailUrl: '📚🐾',
    ),
  ];

  static List<Story> getStoriesForGrade(int gradeLevel) =>
      _stories.where((story) => story.gradeLevel == gradeLevel).toList();

  static List<Story> getAllStories() => List.unmodifiable(_stories);

  static Story? getStoryById(String id) {
    try {
      return _stories.firstWhere((story) => story.id == id);
    } catch (_) {
      return null;
    }
  }
}
