// lib/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Language preference
  Future<void> setLanguage(String language) async {
    final normalised = language == 'sinhala' || language == 'si'
        ? 'sinhala'
        : 'english';
    await _prefs.setString(AppConstants.keyLanguage, normalised);
  }

  String getLanguage() {
    final saved = _prefs.getString(AppConstants.keyLanguage);
    return saved == 'sinhala' || saved == 'si' ? 'sinhala' : 'english';
  }

  // Student ID
  Future<void> setStudentId(String studentId) async {
    await _prefs.setString(AppConstants.keyStudentId, studentId);
  }

  String? getStudentId() {
    return _prefs.getString(AppConstants.keyStudentId);
  }

  // Grade level
  Future<void> setGradeLevel(int grade) async {
    await _prefs.setInt(AppConstants.keyGradeLevel, grade);
  }

  int getGradeLevel() {
    return _prefs.getInt(AppConstants.keyGradeLevel) ?? 1;
  }

  // Last grade opened in the Learning Hub. This is intentionally separate
  // from the child's profile grade so exploring another grade does not edit
  // account information.
  Future<void> setLearningGrade(int grade) async {
    await _prefs.setInt(AppConstants.keyLearningGrade, grade.clamp(1, 2));
  }

  int getLearningGrade({required int fallback}) {
    return (_prefs.getInt(AppConstants.keyLearningGrade) ?? fallback).clamp(
      1,
      2,
    );
  }

  // Curriculum language is separate from the app's interface language. An
  // English-medium child can therefore learn Sinhala letters, and a child
  // using Sinhala navigation can practise English letters.
  Future<void> setLearningLanguage(String language) async {
    final normalized = language == 'sinhala' || language == 'si'
        ? 'sinhala'
        : 'english';
    await _prefs.setString(AppConstants.keyLearningLanguage, normalized);
  }

  String getLearningLanguage({required String fallback}) {
    final saved = _prefs.getString(AppConstants.keyLearningLanguage);
    if (saved == 'sinhala' || saved == 'si') return 'sinhala';
    if (saved == 'english' || saved == 'en') return 'english';
    return fallback == 'sinhala' || fallback == 'si' ? 'sinhala' : 'english';
  }

  // Account role — cached locally after login/signup so SplashScreen can
  // route to the right home screen without an extra Firestore round-trip
  // on every app open.
  Future<void> setAccountRole(String role) async {
    await _prefs.setString(AppConstants.keyAccountRole, role);
  }

  String getAccountRole() {
    return _prefs.getString(AppConstants.keyAccountRole) ?? 'parent';
  }

  // First launch
  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(AppConstants.keyIsFirstLaunch, value);
  }

  bool isFirstLaunch() {
    return _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
