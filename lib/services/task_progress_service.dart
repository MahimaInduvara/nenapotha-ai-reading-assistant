// lib/services/task_progress_service.dart
// Local persistence for practice-task attempts (letter recognition, and
// whatever grade 2/3 tasks follow) — keyed per student so multiple profiles
// on one device don't mix histories.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_attempt.dart';
import 'daily_activity_service.dart';
import 'storage_service.dart';
import 'trace_evaluation_service.dart';

/// A [ChangeNotifier] (rather than a one-shot fetch) so screens like Progress
/// — which MainScreen keeps alive in an IndexedStack and never rebuilds on
/// tab switch — can listen and refresh the moment a new attempt is saved,
/// instead of relying on a re-visit that may never trigger a rebuild.
class TaskProgressService extends ChangeNotifier {
  static final TaskProgressService _instance = TaskProgressService._internal();
  factory TaskProgressService() => _instance;
  TaskProgressService._internal();

  // Cap history so a long-lived install doesn't grow the pref value forever.
  static const int _maxAttemptsPerStudent = 200;

  // Resolve Firestore only when a cloud operation actually runs. Keeping the
  // singleton lazy lets offline/widget-only screens build without requiring a
  // Firebase app merely to read local progress.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String _keyFor(String studentId) => 'task_attempts_$studentId';

  String _migrationKeyFor(String studentId) =>
      'task_attempts_cloud_synced_$studentId';

  String get _studentId => StorageService().getStudentId() ?? 'guest';

  Future<void> saveAttempt(TaskAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(_studentId);
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(attempt.toJson()));
    final capped = existing.length > _maxAttemptsPerStudent
        ? existing.sublist(existing.length - _maxAttemptsPerStudent)
        : existing;
    await prefs.setStringList(key, capped);
    await Future.wait([
      _syncAttemptHistory(studentId: _studentId, rawAttempts: capped),
      DailyActivityService().recordCompletedActivity('task'),
    ]);
    notifyListeners();
  }

  /// One-time migration of the active student's existing local summaries.
  Future<void> syncCurrentStudentAttempts() async {
    final studentId = StorageService().getStudentId();
    if (studentId == null || studentId.isEmpty || studentId == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyFor(studentId)) ?? const <String>[];
    await _syncAttemptHistory(studentId: studentId, rawAttempts: raw);
  }

  Future<void> _syncAttemptHistory({
    required String studentId,
    required List<String> rawAttempts,
  }) async {
    if (studentId.isEmpty || studentId == 'guest' || rawAttempts.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final migrationComplete =
        prefs.getBool(_migrationKeyFor(studentId)) ?? false;
    final source = migrationComplete ? <String>[rawAttempts.last] : rawAttempts;
    final attempts = source
        .map(
          (raw) => TaskAttempt.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        )
        .toList(growable: false);

    try {
      final batch = _firestore.batch();
      for (final attempt in attempts) {
        final ref = _firestore
            .collection('students')
            .doc(studentId)
            .collection('taskAttempts')
            .doc(_cloudDocumentId(attempt));
        batch.set(ref, _sanitizedCloudMap(attempt));
      }
      await batch.commit();
      if (!migrationComplete) {
        await prefs.setBool(_migrationKeyFor(studentId), true);
      }
    } catch (error) {
      // The local record remains available offline. A later opening/activity
      // retries the deterministic write without creating duplicates.
      debugPrint('Task progress cloud sync deferred: $error');
    }
  }

  String _cloudDocumentId(TaskAttempt attempt) {
    final safeType = attempt.taskType.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    return '${attempt.completedAt.microsecondsSinceEpoch}_$safeType';
  }

  /// Strict allow-list: no raw image/strokes, predicted class, model version,
  /// inference time, profile photo, message, email, or credential is sent.
  Map<String, dynamic> _sanitizedCloudMap(TaskAttempt attempt) => {
    'taskType': attempt.taskType,
    'grade': attempt.grade,
    'language': attempt.language,
    'score': attempt.score,
    'total': attempt.total,
    'completedAt': Timestamp.fromDate(attempt.completedAt),
    'items': attempt.items
        .map(
          (item) => {
            'itemId': item.itemId,
            'isCorrect': item.isCorrect,
            if (item.shapeSimilarity != null)
              'shapeSimilarity': item.shapeSimilarity,
          },
        )
        .toList(growable: false),
  };

  TaskAttempt _fromFirestoreMap(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    final completedAt = normalized['completedAt'];
    if (completedAt is Timestamp) {
      normalized['completedAt'] = completedAt.toDate().toIso8601String();
    }
    return TaskAttempt.fromJson(normalized);
  }

  Future<List<TaskAttempt>> getStudentAttempts(
    String studentId, {
    String? taskType,
    int? grade,
    String? language,
  }) async {
    final isActiveStudent = StorageService().getStudentId() == studentId;
    if (isActiveStudent) await syncCurrentStudentAttempts();

    final snapshot = await _firestore
        .collection('students')
        .doc(studentId)
        .collection('taskAttempts')
        .orderBy('completedAt', descending: true)
        .limit(_maxAttemptsPerStudent)
        .get();
    final combined = <String, TaskAttempt>{};
    for (final doc in snapshot.docs) {
      final attempt = _fromFirestoreMap(doc.data());
      combined[_fingerprint(attempt)] = attempt;
    }
    if (isActiveStudent) {
      for (final attempt in await getAttempts()) {
        combined[_fingerprint(attempt)] = attempt;
      }
    }

    final attempts =
        combined.values
            .where((a) => taskType == null || a.taskType == taskType)
            .where((a) => grade == null || a.grade == grade)
            .where((a) => language == null || a.language == language)
            .toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return attempts;
  }

  String _fingerprint(TaskAttempt attempt) =>
      '${attempt.completedAt.microsecondsSinceEpoch}|${attempt.taskType}|'
      '${attempt.score}|${attempt.total}';

  Future<List<TaskAttempt>> getAttempts({
    String? taskType,
    int? grade,
    String? language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyFor(_studentId)) ?? [];
    final attempts =
        raw
            .map(
              (s) =>
                  TaskAttempt.fromJson(jsonDecode(s) as Map<String, dynamic>),
            )
            .where((a) => taskType == null || a.taskType == taskType)
            .where((a) => grade == null || a.grade == grade)
            .where((a) => language == null || a.language == language)
            .toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return attempts;
  }

  Future<TaskAttempt?> getBest({
    required String taskType,
    required int grade,
    String? language,
  }) async {
    final attempts = await getAttempts(
      taskType: taskType,
      grade: grade,
      language: language,
    );
    if (attempts.isEmpty) return null;
    return attempts.reduce((a, b) => b.percentage > a.percentage ? b : a);
  }

  Future<TraceEvaluationSummary> getTraceEvaluationSummary() async {
    final attempts = await getAttempts(taskType: 'letter_tracing');
    return TraceEvaluationService.summarize(attempts);
  }

  /// Builds a de-identified local export. No student ID or raw drawing is
  /// included; external sharing still requires supervisor/ethics approval.
  Future<Map<String, Object?>> buildSanitizedTraceEvaluationExport() async {
    final attempts = await getAttempts(taskType: 'letter_tracing');
    return TraceEvaluationService.buildSanitizedExport(attempts);
  }
}
