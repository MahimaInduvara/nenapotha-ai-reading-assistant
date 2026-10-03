// lib/services/student_service.dart
// Firestore CRUD for student profiles, scoped to the signed-in account via
// ownerUid (enforced both here and in firestore.rules), plus the
// teacher-linking flow (join codes) that grants a non-owning account
// read-only access to a specific student — entirely via Firestore security
// rules, no Cloud Function required (this project is on the free Spark
// plan, which can't deploy Cloud Functions without a Blaze upgrade).

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';

/// Thrown by [StudentService.redeemJoinCode] when the code doesn't match
/// any student — distinct from a generic Firestore/permission error so the
/// UI can show "no student found with that code" specifically.
class JoinCodeNotFoundException implements Exception {
  const JoinCodeNotFoundException();
}

class StudentService {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');
  CollectionReference<Map<String, dynamic>> get _joinCodes =>
      _firestore.collection('joinCodes');

  // Unambiguous alphabet — no 0/O or 1/I, so a code copied by
  // hand doesn't get mixed up. 32^6 ≈ 1 billion combinations is more than
  // enough headroom to skip a uniqueness check for an app this size; a
  // collision is astronomically unlikely.
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 6;

  String _generateJoinCode() {
    final rnd = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)],
    ).join();
  }

  Future<List<Student>> getStudentsForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await _students.where('ownerUid', isEqualTo: uid).get();
    return snapshot.docs.map(Student.fromFirestore).toList();
  }

  /// Loads one student profile that the current account is allowed to read.
  /// Firestore rules remain the source of truth for owner/teacher access.
  Future<Student?> getStudentById(String studentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || studentId.trim().isEmpty) return null;
    final snapshot = await _students.doc(studentId.trim()).get();
    if (!snapshot.exists) return null;
    return Student.fromFirestore(snapshot);
  }

  Future<Student> createStudent({
    required String name,
    required String avatar,
    required int gradeLevel,
    required String preferredLanguage,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'Cannot create a student profile without a signed-in account.',
      );
    }
    final now = DateTime.now();
    final joinCode = _generateJoinCode();
    final docRef = await _students.add({
      'ownerUid': uid,
      'name': name,
      'avatar': avatar,
      'gradeLevel': gradeLevel,
      'preferredLanguage': preferredLanguage,
      'joinCode': joinCode,
      'createdAt': Timestamp.fromDate(now),
    });

    // Written as a second, separate call (not batched with the create
    // above) because firestore.rules verifies this student doc already
    // exists before allowing the joinCodes doc to be created — a rule
    // checking exists()/get() inside an atomic batch only sees state as of
    // before the batch commits, so batching these two writes together
    // would make the joinCodes rule fail.
    await _joinCodes.doc(joinCode).set({
      'studentId': docRef.id,
      'ownerUid': uid,
    });

    return Student(
      id: docRef.id,
      ownerUid: uid,
      name: name,
      avatar: avatar,
      gradeLevel: gradeLevel,
      preferredLanguage: preferredLanguage,
      joinCode: joinCode,
      createdAt: now,
    );
  }

  /// Updates editable profile fields for a student owned by the signed-in
  /// account. Firestore rules enforce ownership; teachers remain read-only.
  Future<void> updateStudentProfile({
    required String studentId,
    String? name,
    String? avatar,
    int? gradeLevel,
    String? preferredLanguage,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'Cannot update a student profile without a signed-in account.',
      );
    }

    final updates = <String, dynamic>{};
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      updates['name'] = cleanName;
    }
    if (avatar != null && avatar.isNotEmpty) updates['avatar'] = avatar;
    if (gradeLevel != null) updates['gradeLevel'] = gradeLevel.clamp(1, 2);
    if (preferredLanguage != null) {
      updates['preferredLanguage'] = preferredLanguage == 'sinhala'
          ? 'sinhala'
          : 'english';
    }
    if (updates.isEmpty) return;

    await _students.doc(studentId).update(updates);
  }

  /// Looks up [code] in joinCodes (a `get` by known document ID — allowed
  /// for any signed-in user by firestore.rules, since `list`/browsing that
  /// collection is blocked and codes aren't guessable) and links the
  /// current account as a teacher on that student. Throws
  /// [JoinCodeNotFoundException] if the code doesn't exist.
  Future<void> redeemJoinCode(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Must be signed in to redeem a join code.');
    }

    final joinDoc = await _joinCodes.doc(code.trim().toUpperCase()).get();
    if (!joinDoc.exists) {
      throw const JoinCodeNotFoundException();
    }

    final studentId = joinDoc.data()!['studentId'] as String;
    await _students.doc(studentId).collection('teacherLinks').doc(uid).set({
      'teacherUid': uid,
      'linkedAt': FieldValue.serverTimestamp(),
    });
  }

  /// All students the current (teacher) account has linked via a join code.
  /// Uses a collection-group query over every students/{id}/teacherLinks
  /// subcollection, filtered to links belonging to this account (allowed by
  /// firestore.rules), then loads each linked student's actual profile.
  Future<List<Student>> getLinkedStudentsForTeacher() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final links = await _firestore
        .collectionGroup('teacherLinks')
        .where('teacherUid', isEqualTo: uid)
        .get();

    final studentDocs = await Future.wait(
      links.docs.map((link) => link.reference.parent.parent!.get()),
    );

    return studentDocs
        .where((doc) => doc.exists)
        .map(Student.fromFirestore)
        .toList();
  }
}
