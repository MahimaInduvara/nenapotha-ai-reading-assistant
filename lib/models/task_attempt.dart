// lib/models/task_attempt.dart
// A single completed practice-task run (e.g. one letter-recognition round),
// persisted so parents/teachers can see how a child is doing over time.

/// Human-friendly [English, Sinhala, emoji] per task type — the single
/// source of truth so progress_screen.dart, ActivityService's activity
/// feed, and ProgressInsightEngine can't drift out of sync on labels.
const Map<String, List<String>> taskTypeLabels = {
  'letter_recognition': ['Letter Recognition', 'අකුරු හඳුනා ගැනීම', '🔤'],
  'letter_matching': ['Letter Matching', 'අකුරු ගැලපීම', '🔗'],
  'pillam_fill': ['Pillam Fill-in', 'පිල්ලම් පුරවමු', '🧩'],
  'pillam_naming': ['Pillam Naming', 'පිල්ලම හඳුනාගමු', '🏷️'],
  'letter_tracing': ['Letter Tracing', 'අකුරු සටහන් කිරීම', '✏️'],
  'grade1_level_1': ['Level 1: Same Letter', 'මට්ටම 1: එකම අකුර', '👀'],
  'grade1_level_2': ['Level 2: Letter and Word', 'මට්ටම 2: අකුර සහ වචනය', '🔤'],
  'grade1_level_3': ['Level 3: Picture', 'මට්ටම 3: රූපයෙන් අකුරට', '🖼️'],
  'grade1_level_4': ['Level 4: Complete Word', 'මට්ටම 4: වචනය පුරවමු', '🧩'],
  'grade1_level_5': ['Level 5: Mastery', 'මට්ටම 5: අකුරු ශූරයා', '🏆'],
  'grade2_level_1': [
    'Level 1: Pillam Explorer',
    'මට්ටම 1: පිල්ලම් ගවේෂකයා',
    '🔤',
  ],
  'grade2_level_2': ['Level 2: Word Builder', 'මට්ටම 2: වචන ගොඩනඟන්නා', '🧩'],
  'grade2_level_3': [
    'Level 3: Picture Vocabulary',
    'මට්ටම 3: රූප වචන මාලාව',
    '🖼️',
  ],
  'grade2_level_4': [
    'Level 4: Sentence Builder',
    'මට්ටම 4: වාක්‍ය ගොඩනඟන්නා',
    '✍️',
  ],
  'grade2_level_5': [
    'Level 5: Reading Detective',
    'මට්ටම 5: කියවීමේ රහස් පරීක්ෂක',
    '🔎',
  ],
  'grade2_level_6': [
    'Level 6: Grade 2 Champion',
    'මට්ටම 6: දෙවන ශ්‍රේණියේ ශූරයා',
    '🏆',
  ],
};

/// One individual item within a task attempt — e.g. one letter shown during
/// a letter-recognition round, or one traced letter. Lets progress screens
/// answer "which specific letters does this student struggle with" instead
/// of only "they got 7/10 on some round" — the round-level score alone
/// can't identify which items were the misses.
class TaskItemResult {
  final String itemId; // the letter, pillam glyph, or word attempted
  final bool isCorrect;
  // ML classifier fields — only populated for letter_tracing (the
  // classifySinhalaLetter model's verdict); null for every other task type,
  // which score by simple equality, not a model prediction.
  final double? confidence;
  // Normalized visual similarity (0-1) between the learner's ink and the
  // rendered standard glyph. Unlike [confidence], this is available even
  // when the CNN has no verified class for the selected letter.
  final double? shapeSimilarity;
  final String? predictedLabel;
  final int? predictionClassId;
  final int? predictionOutputIndex;
  final double? inferenceMilliseconds;
  final String? modelVersion;

  const TaskItemResult({
    required this.itemId,
    required this.isCorrect,
    this.confidence,
    this.shapeSimilarity,
    this.predictedLabel,
    this.predictionClassId,
    this.predictionOutputIndex,
    this.inferenceMilliseconds,
    this.modelVersion,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'isCorrect': isCorrect,
    if (confidence != null) 'confidence': confidence,
    if (shapeSimilarity != null) 'shapeSimilarity': shapeSimilarity,
    if (predictedLabel != null) 'predictedLabel': predictedLabel,
    if (predictionClassId != null) 'predictionClassId': predictionClassId,
    if (predictionOutputIndex != null)
      'predictionOutputIndex': predictionOutputIndex,
    if (inferenceMilliseconds != null)
      'inferenceMilliseconds': inferenceMilliseconds,
    if (modelVersion != null) 'modelVersion': modelVersion,
  };

  factory TaskItemResult.fromJson(Map<String, dynamic> json) => TaskItemResult(
    itemId: json['itemId'] as String,
    isCorrect: json['isCorrect'] as bool,
    confidence: (json['confidence'] as num?)?.toDouble(),
    shapeSimilarity: (json['shapeSimilarity'] as num?)?.toDouble(),
    predictedLabel: json['predictedLabel'] as String?,
    predictionClassId: (json['predictionClassId'] as num?)?.toInt(),
    predictionOutputIndex: (json['predictionOutputIndex'] as num?)?.toInt(),
    inferenceMilliseconds: (json['inferenceMilliseconds'] as num?)?.toDouble(),
    modelVersion: json['modelVersion'] as String?,
  );
}

class TaskAttempt {
  final String taskType; // e.g. 'letter_recognition'
  final int grade;
  final String language; // 'sinhala' | 'english'
  final int score;
  final int total;
  final DateTime completedAt;
  // Per-item breakdown. Defaults to empty for attempts saved before this
  // field existed (old SharedPreferences entries won't have an 'items' key)
  // — fromJson treats a missing key the same as an empty round rather than
  // erroring, so existing saved history keeps loading.
  final List<TaskItemResult> items;

  const TaskAttempt({
    required this.taskType,
    required this.grade,
    required this.language,
    required this.score,
    required this.total,
    required this.completedAt,
    this.items = const [],
  });

  double get percentage => total > 0 ? score / total * 100 : 0;

  Map<String, dynamic> toJson() => {
    'taskType': taskType,
    'grade': grade,
    'language': language,
    'score': score,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory TaskAttempt.fromJson(Map<String, dynamic> json) => TaskAttempt(
    taskType: json['taskType'] as String,
    grade: json['grade'] as int,
    language: json['language'] as String,
    score: json['score'] as int,
    total: json['total'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
    items:
        (json['items'] as List?)
            ?.map(
              (i) =>
                  TaskItemResult.fromJson(Map<String, dynamic>.from(i as Map)),
            )
            .toList() ??
        const [],
  );
}
