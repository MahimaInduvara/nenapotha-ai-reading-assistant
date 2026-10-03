import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentCoachingRecord {
  final String weeklyGoal;
  final String teacherNote;
  final int targetActivitiesPerWeek;
  final DateTime? updatedAt;

  const StudentCoachingRecord({
    this.weeklyGoal = '',
    this.teacherNote = '',
    this.targetActivitiesPerWeek = 4,
    this.updatedAt,
  });

  factory StudentCoachingRecord.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const StudentCoachingRecord();
    return StudentCoachingRecord(
      weeklyGoal: data['weeklyGoal'] as String? ?? '',
      teacherNote: data['teacherNote'] as String? ?? '',
      targetActivitiesPerWeek:
          (data['targetActivitiesPerWeek'] as num?)?.toInt() ?? 4,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class StudentCoachingRecordService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _recordRef(String studentId) {
    final teacherUid = _auth.currentUser?.uid;
    if (teacherUid == null) throw StateError('Teacher sign-in is required.');
    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('coachingPlans')
        .doc(teacherUid);
  }

  Future<StudentCoachingRecord> getRecord(String studentId) async {
    final snapshot = await _recordRef(studentId).get();
    return StudentCoachingRecord.fromMap(snapshot.data());
  }

  Future<StudentCoachingRecord> saveRecord({
    required String studentId,
    required String weeklyGoal,
    required String teacherNote,
    required int targetActivitiesPerWeek,
  }) async {
    final teacherUid = _auth.currentUser?.uid;
    if (teacherUid == null) throw StateError('Teacher sign-in is required.');
    final cleanGoal = weeklyGoal.trim();
    final cleanNote = teacherNote.trim();
    final target = targetActivitiesPerWeek.clamp(1, 7);
    await _recordRef(studentId).set({
      'teacherUid': teacherUid,
      'weeklyGoal': cleanGoal,
      'teacherNote': cleanNote,
      'targetActivitiesPerWeek': target,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return StudentCoachingRecord(
      weeklyGoal: cleanGoal,
      teacherNote: cleanNote,
      targetActivitiesPerWeek: target,
      updatedAt: DateTime.now(),
    );
  }
}
