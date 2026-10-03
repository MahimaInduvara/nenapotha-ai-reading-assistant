import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// One privacy-minimised day summary. It records whether the learning app was
/// opened and how many activities were completed, but never stores screen
/// content, raw handwriting, photos, chat messages, or passwords.
class DailyActivityLog {
  final String dateKey;
  final int appOpenCount;
  final int activitiesCompleted;
  final int taskAttempts;
  final int readingSessions;
  final int quizAttempts;
  final DateTime? lastActiveAt;

  const DailyActivityLog({
    required this.dateKey,
    required this.appOpenCount,
    required this.activitiesCompleted,
    required this.taskAttempts,
    required this.readingSessions,
    required this.quizAttempts,
    required this.lastActiveAt,
  });

  bool get wasOpened => appOpenCount > 0;
  bool get hasLearningActivity => activitiesCompleted > 0;

  factory DailyActivityLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return DailyActivityLog(
      dateKey: data['dateKey'] as String? ?? doc.id,
      appOpenCount: (data['appOpenCount'] as num?)?.toInt() ?? 0,
      activitiesCompleted: (data['activitiesCompleted'] as num?)?.toInt() ?? 0,
      taskAttempts: (data['taskAttempts'] as num?)?.toInt() ?? 0,
      readingSessions: (data['readingSessions'] as num?)?.toInt() ?? 0,
      quizAttempts: (data['quizAttempts'] as num?)?.toInt() ?? 0,
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }
}

class DailyActivityService {
  static final DailyActivityService _instance =
      DailyActivityService._internal();
  factory DailyActivityService() => _instance;
  DailyActivityService._internal();

  // Resolve Firestore lazily so constructing the service does not make local
  // learning screens depend on Firebase having already been initialised.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String dateKey([DateTime? date]) {
    final value = (date ?? DateTime.now()).toLocal();
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>>? _todayRef() {
    final studentId = StorageService().getStudentId();
    if (studentId == null || studentId.isEmpty) return null;
    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('dailyActivity')
        .doc(dateKey());
  }

  Future<void> recordAppOpened() async {
    final ref = _todayRef();
    if (ref == null) return;
    try {
      await ref.set({
        'dateKey': dateKey(),
        'appOpenCount': FieldValue.increment(1),
        'activitiesCompleted': FieldValue.increment(0),
        'taskAttempts': FieldValue.increment(0),
        'readingSessions': FieldValue.increment(0),
        'quizAttempts': FieldValue.increment(0),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Daily app-open sync deferred: $error');
    }
  }

  Future<void> recordCompletedActivity(String kind) async {
    final ref = _todayRef();
    if (ref == null) return;
    final counter = switch (kind) {
      'reading' => 'readingSessions',
      'quiz' => 'quizAttempts',
      _ => 'taskAttempts',
    };
    try {
      final counters = <String, dynamic>{
        'dateKey': dateKey(),
        'appOpenCount': FieldValue.increment(0),
        'activitiesCompleted': FieldValue.increment(1),
        'taskAttempts': FieldValue.increment(0),
        'readingSessions': FieldValue.increment(0),
        'quizAttempts': FieldValue.increment(0),
        'lastActiveAt': FieldValue.serverTimestamp(),
      };
      counters[counter] = FieldValue.increment(1);
      await ref.set(counters, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Daily completed-activity sync deferred: $error');
    }
  }

  Future<List<DailyActivityLog>> getLogs(
    String studentId, {
    int days = 30,
  }) async {
    final snapshot = await _firestore
        .collection('students')
        .doc(studentId)
        .collection('dailyActivity')
        .orderBy('dateKey', descending: true)
        .limit(days.clamp(1, 90))
        .get();
    return snapshot.docs.map(DailyActivityLog.fromFirestore).toList();
  }
}
