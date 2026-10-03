// lib/screens/student_gate_screen.dart
// Post-auth routing hub: loads the signed-in account's student profiles from
// Firestore and decides where to go next — create the first one, choose
// from several, or jump straight into the app if there's exactly one.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../main_screen.dart';
import 'student_profile_setup_screen.dart';

class StudentGateScreen extends StatefulWidget {
  final String selectedLanguage;

  const StudentGateScreen({super.key, required this.selectedLanguage});

  @override
  State<StudentGateScreen> createState() => _StudentGateScreenState();
}

class _StudentGateScreenState extends State<StudentGateScreen> {
  List<Student>? _students;
  String? _error;

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _students = null;
    });
    try {
      final students = await StudentService().getStudentsForCurrentUser();
      if (!mounted) return;
      if (students.isEmpty) {
        _goToSetup();
        return;
      }
      if (students.length == 1) {
        await _continueAs(students.first);
        return;
      }
      setState(() => _students = students);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _goToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentProfileSetupScreen(
          selectedLanguage: widget.selectedLanguage,
        ),
      ),
    );
  }

  Future<void> _continueAs(Student student) async {
    await StorageService().setStudentId(student.id);
    await StorageService().setGradeLevel(student.gradeLevel);
    await StorageService().setLanguage(student.preferredLanguage);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${AppConstants.keyAvatar}_${student.id}',
      student.avatar,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreen(
          selectedLanguage: student.preferredLanguage,
          studentName: student.name,
          gradeLevel: student.gradeLevel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _isSi
                      ? 'දරුවන්ගේ තොරතුරු ලබාගැනීමට නොහැකි විය.'
                      : 'Could not load student profiles.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    _isSi ? 'නැවත උත්සාහ කරන්න' : 'Retry',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_students == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // 2+ students on this account: let them choose who's using the app now.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isSi ? 'කවුද කියවන්නේ?' : "Who's reading?",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._students!.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _studentTile(s),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _goToSetup,
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: Text(
              _isSi ? 'තවත් දරුවෙකු එකතු කරන්න' : 'Add another child',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentTile(Student s) {
    return GestureDetector(
      onTap: () => _continueAs(s),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(s.avatar, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isSi
                        ? 'ශ්‍රේණිය ${s.gradeLevel}'
                        : 'Grade ${s.gradeLevel}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
