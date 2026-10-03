import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/redesign/learning_screen.dart';
import '../screens/coach/smart_learning_coach_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/profile/profile_tab_screen.dart';

class NavigationConfig {
  // Single source of truth - all navigation items defined ONCE
  static const List<NavItem> navItems = [
    NavItem(
      index: 0,
      labelEn: 'Home',
      labelSi: 'මුල් පිටුව',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    NavItem(
      index: 1,
      labelEn: 'Learn',
      labelSi: 'ඉගෙනීම',
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
    ),
    NavItem(
      index: 2,
      labelEn: 'My Coach',
      labelSi: 'පුහුණු මඟ',
      icon: Icons.route_outlined,
      activeIcon: Icons.route_rounded,
    ),
    NavItem(
      index: 3,
      labelEn: 'Progress',
      labelSi: 'ප්‍රගතිය',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
    ),
    NavItem(
      index: 4,
      labelEn: 'Profile',
      labelSi: 'පැතිකඩ',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  // Screen builder functions - NO hard coded instances
  static Widget buildScreen(
    int index, {
    required String selectedLanguage,
    required String studentName,
    required int gradeLevel,
    void Function(int)? onNavigate,
    ValueChanged<String>? onLanguageChanged,
    ValueChanged<String>? onStudentNameChanged,
    ValueChanged<int>? onGradeChanged,
  }) {
    switch (index) {
      case 0:
        return HomeScreen(
          selectedLanguage: selectedLanguage,
          studentName: studentName,
          gradeLevel: gradeLevel,
          onNavigate: onNavigate,
        );
      case 1:
        return LearningScreen(
          selectedLanguage: selectedLanguage,
          gradeLevel: gradeLevel,
          studentName: studentName,
        );
      case 2:
        return SmartLearningCoachScreen(
          selectedLanguage: selectedLanguage,
          gradeLevel: gradeLevel,
          studentName: studentName,
          onNavigate: onNavigate,
        );
      case 3:
        return ProgressScreen(
          selectedLanguage: selectedLanguage,
          studentName: studentName,
          gradeLevel: gradeLevel,
          onNavigate: onNavigate,
        );
      case 4:
        return ProfileTabScreen(
          selectedLanguage: selectedLanguage,
          studentName: studentName,
          gradeLevel: gradeLevel,
          onLanguageChanged: onLanguageChanged,
          onStudentNameChanged: onStudentNameChanged,
          onGradeChanged: onGradeChanged,
        );
      default:
        return HomeScreen(
          selectedLanguage: selectedLanguage,
          studentName: studentName,
          gradeLevel: gradeLevel,
          onNavigate: onNavigate,
        );
    }
  }
}

class NavItem {
  final int index;
  final String labelEn;
  final String labelSi;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.index,
    required this.labelEn,
    required this.labelSi,
    required this.icon,
    required this.activeIcon,
  });

  String getLabel(String language) {
    return language == 'si' || language == 'sinhala' ? labelSi : labelEn;
  }
}
