// lib/models/student.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// A student profile stored in the `students` Firestore collection, owned by
/// exactly one parent/teacher account (see [ownerUid]). One account can own
/// several student profiles (e.g. a parent with multiple children, or a
/// teacher's class).
///
/// [joinCode] lets a *different* account (typically a teacher) gain read
/// access to this profile without ever owning it — see
/// StudentService.redeemJoinCode and the teacherLinks rule in
/// firestore.rules.
class Student {
  final String id;
  final String ownerUid;
  final String name;
  final String avatar;
  final int gradeLevel;
  final String preferredLanguage; // 'sinhala' | 'english'
  final String joinCode;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.avatar,
    required this.gradeLevel,
    required this.preferredLanguage,
    required this.joinCode,
    required this.createdAt,
  });

  factory Student.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Student(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      name: data['name'] ?? '',
      avatar: data['avatar'] ?? '🐶',
      gradeLevel: data['gradeLevel'] ?? 1,
      preferredLanguage: data['preferredLanguage'] == 'sinhala'
          ? 'sinhala'
          : 'english',
      joinCode: data['joinCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'avatar': avatar,
      'gradeLevel': gradeLevel,
      'preferredLanguage': preferredLanguage,
      'joinCode': joinCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
