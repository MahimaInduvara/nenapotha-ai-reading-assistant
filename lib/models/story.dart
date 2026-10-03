// lib/models/story.dart

class Story {
  final String id;
  final String titleSi;
  final String titleEn;
  final String contentSi;
  final String contentEn;
  final int gradeLevel;
  final String difficulty;
  final int wordCount;
  final List<String> vocabularyWordsSi;
  final List<String> vocabularyWordsEn;
  final String thumbnailUrl;
  final bool isCompleted;
  final double comprehensionScore;

  Story({
    required this.id,
    required this.titleSi,
    required this.titleEn,
    required this.contentSi,
    required this.contentEn,
    required this.gradeLevel,
    required this.difficulty,
    required this.wordCount,
    required this.vocabularyWordsSi,
    required this.vocabularyWordsEn,
    required this.thumbnailUrl,
    this.isCompleted = false,
    this.comprehensionScore = 0.0,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'].toString(),
      titleSi: json['title_si'] ?? '',
      titleEn: json['title_en'] ?? '',
      contentSi: json['content_si'] ?? '',
      contentEn: json['content_en'] ?? '',
      gradeLevel: json['grade_level'] ?? 1,
      difficulty: json['difficulty'] ?? 'easy',
      wordCount: json['word_count'] ?? 0,
      vocabularyWordsSi: json['vocabulary_si'] is List
          ? json['vocabulary_si'].cast<String>()
          : [],
      vocabularyWordsEn: json['vocabulary_en'] is List
          ? json['vocabulary_en'].cast<String>()
          : [],
      thumbnailUrl: json['thumbnail_url'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      comprehensionScore: (json['comprehension_score'] ?? 0).toDouble(),
    );
  }

  // Get display title based on language
  String getTitle(String language) {
    if (language == 'sinhala') return titleSi;
    if (language == 'english') return titleEn;
    return '$titleSi / $titleEn';
  }

  // Get display content based on language
  String getContent(String language) {
    if (language == 'sinhala') return contentSi;
    if (language == 'english') return contentEn;
    return '$contentSi\n\n$contentEn';
  }
}
