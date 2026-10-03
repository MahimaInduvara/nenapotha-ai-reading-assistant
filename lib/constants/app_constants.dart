// lib/constants/app_constants.dart

class AppConstants {
  // API Endpoints
  static const String baseUrl = 'http://localhost:5000/api';
  static const String storiesEndpoint = '$baseUrl/stories';
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String progressEndpoint = '$baseUrl/progress';

  // App Info
  static const String appName = 'NenaPotha AI';
  static const String appVersion = '1.0.0';

  // Reading Settings
  static const double sinhalaFontSize = 28.0;
  static const double englishFontSize = 24.0;
  static const double lineHeight = 1.8;

  // Grade Levels — this app only has content for Grade 1 and 2.
  static const List<int> gradeLevels = [1, 2];

  // Shared Preferences Keys
  static const String keyLanguage = 'selected_language';
  static const String keyStudentId = 'student_id';
  static const String keyGradeLevel = 'grade_level';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyStudentName = 'student_name';
  static const String keyAvatar = 'student_avatar';
  static const String keyProfilePhotoPath = 'student_profile_photo_path';
  static const String keyAccountRole = 'account_role'; // 'parent' | 'teacher'
  static const String keyLearningGrade = 'active_learning_grade';
  static const String keyLearningLanguage = 'learning_content_language';

  // Story Difficulty
  static const List<String> difficulties = ['easy', 'medium', 'hard'];

  // Language Options
  static const String langSinhala = 'sinhala';
  static const String langEnglish = 'english';
}
