// lib/services/auth_service.dart
// Thin wrapper around Firebase Authentication. Also mirrors a minimal
// profile document to `users/{uid}` in Firestore on sign-up so the account
// has a queryable record beyond the auth token itself.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// [role] is 'parent' or 'teacher' — set once at sign-up and used to route
  /// the account to the right home screen (StudentGateScreen vs
  /// TeacherDashboardScreen) on every subsequent login.
  Future<User?> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  /// Reads the account's role from `users/{uid}`. Defaults to 'parent' for
  /// accounts with no role on record — covers anonymous "skip/child mode"
  /// sessions, which never write a users doc at all.
  Future<String> getRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'parent';
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] as String? ?? 'parent';
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// "Skip / child mode" — creates a real, backend-tracked anonymous account
  /// instead of a purely local/hardcoded session, so student profiles saved
  /// this way still live in Firestore under a genuine uid.
  Future<User?> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();
}
