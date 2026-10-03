import 'dart:async';

import 'package:flutter/material.dart';
import 'config/navigation_config.dart';
import 'services/daily_activity_service.dart';
import 'services/task_progress_service.dart';
import 'widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final String selectedLanguage;
  final String studentName;
  final int gradeLevel;

  const MainScreen({
    super.key,
    required this.selectedLanguage,
    required this.studentName,
    required this.gradeLevel,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late String _selectedLanguage;
  late String _studentName;
  late int _gradeLevel;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedLanguage = _normaliseLanguage(widget.selectedLanguage);
    _studentName = widget.studentName;
    _gradeLevel = widget.gradeLevel.clamp(1, 2);
    _screens = _buildScreens();
    unawaited(_recordStudentAppOpen());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recordStudentAppOpen());
    }
  }

  Future<void> _recordStudentAppOpen() async {
    await Future.wait([
      DailyActivityService().recordAppOpened(),
      TaskProgressService().syncCurrentStudentAttempts(),
    ]);
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final updated = _normaliseLanguage(widget.selectedLanguage);
    if (updated != _selectedLanguage) {
      _selectedLanguage = updated;
      _replaceScreens();
    }
  }

  String _normaliseLanguage(String language) =>
      language == 'sinhala' || language == 'si' ? 'sinhala' : 'english';

  List<Widget> _buildScreens() => List.generate(
    NavigationConfig.navItems.length,
    (index) => NavigationConfig.buildScreen(
      index,
      selectedLanguage: _selectedLanguage,
      studentName: _studentName,
      gradeLevel: _gradeLevel,
      onNavigate: _onNavigate,
      onLanguageChanged: _onLanguageChanged,
      onStudentNameChanged: _onStudentNameChanged,
      onGradeChanged: _onGradeChanged,
    ),
  );

  void _replaceScreens() {
    final replacements = _buildScreens();
    for (var i = 0; i < replacements.length; i++) {
      _screens[i] = replacements[i];
    }
  }

  void _onLanguageChanged(String language) {
    final normalised = _normaliseLanguage(language);
    if (normalised == _selectedLanguage) return;
    setState(() {
      _selectedLanguage = normalised;
      _replaceScreens();
    });
  }

  void _onStudentNameChanged(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName == _studentName) return;
    setState(() {
      _studentName = cleanName;
      _replaceScreens();
    });
  }

  void _onGradeChanged(int grade) {
    final safeGrade = grade.clamp(1, 2);
    if (safeGrade == _gradeLevel) return;
    setState(() {
      _gradeLevel = safeGrade;
      _replaceScreens();
    });
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        selectedLanguage: _selectedLanguage,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
