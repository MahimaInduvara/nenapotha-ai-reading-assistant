// lib/screens/teacher_dashboard_screen.dart
// Real teacher landing screen: shows only students the signed-in teacher
// has linked via a join code (see StudentService.redeemJoinCode). No
// fabricated roster or invented performance numbers — this screen
// only ever displays data that's actually backed by Firestore.
//
// Detailed per-student analytics (comprehension and practice indicators)
// intentionally show an honest "not enough data yet" state rather than
// mock numbers, because reading-session/quiz persistence isn't built yet —
// once it is, this screen lights up with real activity automatically.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../utils/app_colors.dart';
import 'teacher_student_progress_screen.dart';
import 'text_difficulty_checker_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String selectedLanguage;
  const TeacherDashboardScreen({super.key, required this.selectedLanguage});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool get _isSi => widget.selectedLanguage == 'sinhala';

  List<Student>? _students;
  String? _error;
  final TextEditingController _studentSearchController =
      TextEditingController();
  String _studentQuery = '';
  int? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _students = null;
    });
    try {
      final students = await StudentService().getLinkedStudentsForTeacher();
      if (!mounted) return;
      setState(() => _students = students);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _addStudentByCode() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddStudentDialog(isSi: _isSi),
    );

    if (result == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSi ? 'සිසුවා එකතු කරන ලදී! 🎉' : 'Student added! 🎉',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isSi ? 'නික්මවීමට අවශ්‍යද?' : 'Log out?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_isSi ? 'අවලංගු' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _isSi ? 'නික්මෙන්න' : 'Log out',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSi ? '🏫 ගුරු පුවරුව' : '🏫 Teacher Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: _isSi ? 'නික්මෙන්න' : 'Log out',
            onPressed: _confirmLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: _isSi ? 'දළ දර්ශනය' : 'Overview'),
            Tab(text: _isSi ? 'සිසුන්' : 'Students'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStudentByCode,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _isSi ? 'සිසුවෙකු එකතු කරන්න' : 'Add Student',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
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
                    ? 'සිසුන් ලබාගැනීමට නොහැකි විය.'
                    : 'Could not load your students.',
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
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_students == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return TabBarView(
      controller: _tab,
      children: [_buildOverview(), _buildStudentList()],
    );
  }

  // ── TAB 1: Overview ──────────────────────────────────────────────────────

  Widget _buildOverview() {
    final students = _students!;
    final byGrade = <int, int>{};
    for (final s in students) {
      byGrade[s.gradeLevel] = (byGrade[s.gradeLevel] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildClassBanner(students.length),
          const SizedBox(height: 20),
          if (byGrade.isNotEmpty) ...[
            _buildSectionTitle(
              _isSi ? '📊 ශ්‍රේණි විශ්ලේෂණය' : '📊 Grade Breakdown',
            ),
            const SizedBox(height: 12),
            _buildGradeBreakdown(byGrade),
            const SizedBox(height: 20),
          ],
          _buildTextDifficultyTool(),
          const SizedBox(height: 20),
          _buildNoDataNotice(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextDifficultyTool() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TextDifficultyCheckerScreen(
              selectedLanguage: widget.selectedLanguage,
            ),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE9F9F7), Color(0xFFF2EFFF)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCFC8FA)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSi
                          ? 'පාඨ අපහසුතා පරීක්ෂකය'
                          : 'Text Difficulty Checker',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF252842),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isSi
                          ? 'පාඨයක් 1 හෝ 2 ශ්‍රේණියට ගැළපේදැයි පරීක්ෂා කරන්න'
                          : 'Estimate whether a passage suits Grade 1 or 2',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Text('👥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isSi ? 'සම්බන්ධිත සිසුන්' : 'Linked Students',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBreakdown(Map<int, int> byGrade) {
    final gradeColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
    ];
    final entries = byGrade.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.map((e) {
        final g = e.key;
        final n = e.value;
        final color = gradeColors[(g - 1).clamp(0, 4)];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$g',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isSi ? 'ශ්‍රේණිය $g' : 'Grade $g',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                _isSi ? '$n සිසුන්' : '$n student${n == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoDataNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSi
                  ? 'අවබෝධතාව, කියවීමේ වේගය සහ අවදානම් විශ්ලේෂණය සිසුන් යෙදුම භාවිතා කිරීම ආරම්භ කළ පසු මෙහි පෙන්වනු ඇත.'
                  : 'Comprehension, reading-speed, and additional-practice indicators will appear here once enough real activity is available.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Students ───────────────────────────────────────────────────────

  Widget _buildStudentList() {
    final students = _students!;
    if (students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            const Center(child: Text('🏫', style: TextStyle(fontSize: 56))),
            const SizedBox(height: 16),
            Text(
              _isSi ? 'තවම සිසුන් නැත' : 'No students yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSi
                  ? 'දෙමව්පියෙකුගෙන් ලැබුණු කේතයක් ඇතුළත් කිරීමට පහළින් "සිසුවෙකු එකතු කරන්න" ඔබන්න.'
                  : 'Tap "Add Student" below and enter a code shared by a parent.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final query = _studentQuery.trim().toLowerCase();
    final visibleStudents =
        students
            .where(
              (student) =>
                  student.name.toLowerCase().contains(query) &&
                  (_selectedGrade == null ||
                      student.gradeLevel == _selectedGrade),
            )
            .toList()
          ..sort((a, b) {
            final gradeOrder = a.gradeLevel.compareTo(b.gradeLevel);
            return gradeOrder != 0
                ? gradeOrder
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    final availableGrades =
        students.map((student) => student.gradeLevel).toSet().toList()..sort();
    final visibleGrades =
        visibleStudents.map((student) => student.gradeLevel).toSet().toList()
          ..sort();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          TextField(
            controller: _studentSearchController,
            onChanged: (value) => setState(() => _studentQuery = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _isSi
                  ? 'සිසුවාගේ නමෙන් සොයන්න'
                  : 'Search by student name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _studentQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _isSi ? 'මකන්න' : 'Clear search',
                      onPressed: () {
                        _studentSearchController.clear();
                        setState(() => _studentQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _gradeFilterChip(
                  label: _isSi ? 'සියලු ශ්‍රේණි' : 'All grades',
                  grade: null,
                  count: students.length,
                ),
                ...availableGrades.map(
                  (grade) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _gradeFilterChip(
                      label: _isSi ? '$grade ශ්‍රේණිය' : 'Grade $grade',
                      grade: grade,
                      count: students
                          .where((student) => student.gradeLevel == grade)
                          .length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (visibleStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_search_rounded,
                    size: 52,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSi
                        ? 'මෙම නමට සම්බන්ධිත සිසුවෙකු නැත'
                        : 'No linked student matches that name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final grade in visibleGrades) ...[
              _gradeSectionHeader(
                grade,
                visibleStudents
                    .where((student) => student.gradeLevel == grade)
                    .length,
              ),
              const SizedBox(height: 9),
              ...visibleStudents
                  .where((student) => student.gradeLevel == grade)
                  .map(_studentCard),
              const SizedBox(height: 5),
            ],
        ],
      ),
    );
  }

  Widget _gradeFilterChip({
    required String label,
    required int? grade,
    required int count,
  }) {
    final selected = _selectedGrade == grade;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedGrade = grade),
      avatar: Icon(
        grade == null ? Icons.groups_rounded : Icons.school_rounded,
        size: 18,
        color: selected ? Colors.white : AppColors.primary,
      ),
      label: Text('$label ($count)'),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    );
  }

  Widget _gradeSectionHeader(int grade, int count) {
    final color = grade == 1 ? AppColors.coral : AppColors.teal;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$grade',
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _isSi ? '$grade ශ්‍රේණිය' : 'Grade $grade',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isSi ? '$count සිසුන්' : '$count student${count == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _studentCard(Student s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TeacherStudentProgressScreen(
                student: s,
                selectedLanguage: widget.selectedLanguage,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(s.avatar, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _isSi
                            ? 'ශ්‍රේණිය ${s.gradeLevel} • ප්‍රගතිය බලන්න'
                            : 'Grade ${s.gradeLevel} • View progress',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
  );
}

/// A proper StatefulWidget for the "Add Student" dialog — `isBusy`/`errorText`
/// need to survive rebuilds triggered mid-flow (while the redeem call is in
/// flight), which a StatefulBuilder with locals declared inside its builder
/// closure can't do: those locals reset to their initial value on every
/// rebuild, so the busy spinner would immediately flip back to "idle".
class _AddStudentDialog extends StatefulWidget {
  final bool isSi;
  const _AddStudentDialog({required this.isSi});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _controller = TextEditingController();
  bool _isBusy = false;
  String? _errorText;

  bool get _isSi => widget.isSi;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isBusy = true;
      _errorText = null;
    });
    try {
      await StudentService().redeemJoinCode(code);
      if (mounted) Navigator.pop(context, true);
    } on JoinCodeNotFoundException {
      setState(() {
        _isBusy = false;
        _errorText = _isSi
            ? 'මෙම කේතයට සිසුවෙකු නොමැත.'
            : 'No student found with that code.';
      });
    } catch (e) {
      setState(() {
        _isBusy = false;
        _errorText = _isSi ? 'අනපේක්ෂිත දෝෂයක්' : 'Unexpected error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isSi ? 'සිසුවෙකු එකතු කරන්න' : 'Add a Student',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSi
                ? 'දෙමව්පියා ලබා දුන් කේතය ඇතුළත් කරන්න.'
                : 'Enter the join code the parent shared with you.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.poppins(
              fontSize: 20,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'ABC123',
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context, false),
          child: Text(_isSi ? 'අවලංගු' : 'Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isBusy ? null : _submit,
          child: _isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isSi ? 'එකතු කරන්න' : 'Add',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
