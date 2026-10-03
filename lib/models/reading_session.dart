// lib/models/reading_session.dart
// Tracks a single completed reading activity,
// and persists to Firestore (students/{id}/readingSessions) so Home,
// Profile, Progress, and the AI Assistant can all show real activity
// instead of mock numbers.

import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingSession {
  final String id;
  final String storyId;
  final String titleEn;
  final String titleSi;
  final int gradeLevel;
  final String language; // 'sinhala' | 'english'
  final DateTime startTime;
  DateTime? endTime;

  // Core metrics
  int helpRequestsCount = 0;
  double comprehensionScore = 0.0;
  int pagesCompleted = 0;
  int totalPages = 0;
  int pointsEarned = 0;
  int starsEarned = 0;

  int get durationSeconds =>
      endTime != null ? endTime!.difference(startTime).inSeconds : 0;

  double get completionRate =>
      totalPages > 0 ? (pagesCompleted / totalPages) : 0.0;

  ReadingSession({
    this.id = '',
    required this.storyId,
    this.titleEn = '',
    this.titleSi = '',
    required this.gradeLevel,
    this.language = 'english',
    required this.startTime,
  });

  Map<String, dynamic> toJson() => {
    'story_id': storyId,
    'grade_level': gradeLevel,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'help_requests': helpRequestsCount,
    'comprehension_score': comprehensionScore,
    'pages_completed': pagesCompleted,
    'total_pages': totalPages,
  };

  Map<String, dynamic> toFirestoreMap() => {
    'storyId': storyId,
    'titleEn': titleEn,
    'titleSi': titleSi,
    'gradeLevel': gradeLevel,
    'language': language,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    'helpRequestsCount': helpRequestsCount,
    'comprehensionScore': comprehensionScore,
    'pagesCompleted': pagesCompleted,
    'totalPages': totalPages,
    'pointsEarned': pointsEarned,
    'starsEarned': starsEarned,
  };

  factory ReadingSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final start = (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final session =
        ReadingSession(
            id: doc.id,
            storyId: data['storyId'] ?? '',
            titleEn: data['titleEn'] ?? '',
            titleSi: data['titleSi'] ?? '',
            gradeLevel: data['gradeLevel'] ?? 1,
            language: data['language'] == 'sinhala' ? 'sinhala' : 'english',
            startTime: start,
          )
          ..endTime = (data['endTime'] as Timestamp?)?.toDate()
          ..helpRequestsCount = data['helpRequestsCount'] ?? 0
          ..comprehensionScore = (data['comprehensionScore'] ?? 0.0).toDouble()
          ..pagesCompleted = data['pagesCompleted'] ?? 0
          ..totalPages = data['totalPages'] ?? 0
          ..pointsEarned = data['pointsEarned'] ?? 0
          ..starsEarned = data['starsEarned'] ?? 0;
    return session;
  }
}
