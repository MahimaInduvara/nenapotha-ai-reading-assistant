// lib/screens/profile_screen.dart
// ReadBuddy — Student Profile & Settings

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/student_progress.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/student_service.dart';
import '../utils/app_colors.dart';
import '../widgets/readbuddy_background.dart';
import 'research/trace_training_collector_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String selectedLanguage;
  final String studentName;
  final int gradeLevel;
  final ValueChanged<String>? onLanguageChanged;
  final ValueChanged<String>? onStudentNameChanged;
  final ValueChanged<int>? onGradeChanged;

  const ProfileScreen({
    super.key,
    required this.selectedLanguage,
    required this.studentName,
    required this.gradeLevel,
    this.onLanguageChanged,
    this.onStudentNameChanged,
    this.onGradeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatars = ['🐶', '🐱', '🦁', '🐻', '👧🏽', '👦🏽'];

  late String _name;
  late int _grade;
  late String _language; // 'sinhala' | 'english'
  String _avatar = '🐶';
  String? _profilePhotoPath;
  bool _photoBusy = false;
  String? _joinCode;
  bool _joinCodeLoading = true;
  late StudentProgress _progress;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isSi => _language == 'sinhala';
  String get _studentId => StorageService().getStudentId() ?? '';
  String get _avatarKey => '${AppConstants.keyAvatar}_$_studentId';
  String get _profilePhotoKey =>
      '${AppConstants.keyProfilePhotoPath}_$_studentId';
  String get _studentNameKey => '${AppConstants.keyStudentName}_$_studentId';

  @override
  void initState() {
    super.initState();
    _name = widget.studentName;
    _grade = widget.gradeLevel;
    _language = widget.selectedLanguage == 'sinhala' ? 'sinhala' : 'english';
    _progress = StudentProgress.empty(
      studentId: StorageService().getStudentId() ?? '',
      studentName: _name,
      gradeLevel: _grade,
    );
    _loadProgress();
    _loadSavedPrefs();
    _loadJoinCode();
  }

  Future<void> _loadJoinCode() async {
    if (_studentId.isEmpty) {
      if (mounted) setState(() => _joinCodeLoading = false);
      return;
    }
    try {
      final student = await StudentService().getStudentById(_studentId);
      if (!mounted) return;
      setState(() {
        _joinCode = student?.joinCode.trim();
        _joinCodeLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _joinCodeLoading = false);
    }
  }

  Future<void> _copyJoinCode() async {
    final code = _joinCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _showPhotoMessage(_isSi ? 'ශිෂ්‍ය කේතය copy කළා' : 'Student code copied');
  }

  Future<void> _loadProgress() async {
    final studentId = StorageService().getStudentId();
    if (studentId == null) return;
    final progress = await ActivityService().computeProgress(
      studentId: studentId,
      studentName: _name,
      gradeLevel: _grade,
    );
    if (mounted) setState(() => _progress = progress);
  }

  Future<void> _loadSavedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    var savedPhotoPath = prefs.getString(_profilePhotoKey);
    var savedAvatar = prefs.getString(_avatarKey);

    // One-time migration for profiles created before media keys were scoped
    // by student ID. Removing the legacy keys prevents a later child from
    // inheriting this child's local photo or avatar.
    if (_studentId.isNotEmpty && savedPhotoPath == null) {
      savedPhotoPath = prefs.getString(AppConstants.keyProfilePhotoPath);
      if (savedPhotoPath != null) {
        await prefs.setString(_profilePhotoKey, savedPhotoPath);
        await prefs.remove(AppConstants.keyProfilePhotoPath);
      }
    }
    if (_studentId.isNotEmpty && savedAvatar == null) {
      savedAvatar = prefs.getString(AppConstants.keyAvatar);
      if (savedAvatar != null) {
        await prefs.setString(_avatarKey, savedAvatar);
        await prefs.remove(AppConstants.keyAvatar);
      }
    }
    final hasSavedPhoto =
        savedPhotoPath != null && await File(savedPhotoPath).exists();
    if (savedPhotoPath != null && !hasSavedPhoto) {
      await prefs.remove(_profilePhotoKey);
    }
    if (!mounted) return;
    setState(() {
      _avatar = savedAvatar ?? _avatar;
      _profilePhotoPath = hasSavedPhoto ? savedPhotoPath : null;
    });
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<bool> _syncRemoteProfile({
    String? name,
    String? avatar,
    int? gradeLevel,
    String? preferredLanguage,
  }) async {
    if (_studentId.isEmpty) return false;
    try {
      await StudentService().updateStudentProfile(
        studentId: _studentId,
        name: name,
        avatar: avatar,
        gradeLevel: gradeLevel,
        preferredLanguage: preferredLanguage,
      );
      return true;
    } catch (_) {
      if (mounted) {
        _showPhotoMessage(
          _isSi
              ? 'පැතිකඩ Firebase වෙත සුරැකීමට නොහැකි වුණා. නැවත උත්සාහ කරන්න.'
              : 'Could not sync the profile. Please try again.',
          isError: true,
        );
      }
      return false;
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showProfilePictureSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSi ? 'පැතිකඩ පින්තූරය' : 'Profile picture',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _isSi
                          ? 'මෙම උපාංගයේ පමණක් සුරැකේ'
                          : 'Stored only on this device',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _photoSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: _isSi ? 'ගැලරිය' : 'Gallery',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _chooseProfilePhoto(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _photoSourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: _isSi ? 'කැමරාව' : 'Camera',
                      color: AppColors.teal,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _chooseProfilePhoto(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              if (_profilePhotoPath != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _removeProfilePhoto(showConfirmation: true);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(_isSi ? 'පින්තූරය ඉවත් කරන්න' : 'Remove photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              Text(
                _isSi ? 'අවතාරයක් තෝරන්න' : 'Choose an avatar instead',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _avatars.map((a) {
                  final selected = a == _avatar && _profilePhotoPath == null;
                  return GestureDetector(
                    onTap: () => _chooseAvatar(sheetContext, a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(a, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _photoBusy ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Directory> _profilePhotoDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}profile',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  String _safeImageExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final extension = name.substring(dot).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
    return allowed.contains(extension) ? extension : '.jpg';
  }

  Future<void> _chooseProfilePhoto(ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (picked == null) return;

      final directory = await _profilePhotoDirectory();
      final extension = _safeImageExtension(picked.name);
      final safeStudentId = _studentId.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final destination = File(
        '${directory.path}${Platform.pathSeparator}child_profile_$safeStudentId$extension',
      );
      final oldPath = _profilePhotoPath;
      await File(picked.path).copy(destination.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profilePhotoKey, destination.path);
      if (oldPath != null && oldPath != destination.path) {
        await _deleteOwnedProfilePhoto(oldPath);
      }
      if (!mounted) return;
      setState(() => _profilePhotoPath = destination.path);
      _showPhotoMessage(
        _isSi ? 'පැතිකඩ පින්තූරය සුරැකිණි' : 'Profile picture saved',
      );
    } catch (_) {
      if (!mounted) return;
      _showPhotoMessage(
        _isSi
            ? 'පින්තූරය තෝරාගැනීමට නොහැකි වුණා'
            : 'Could not choose that picture. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _chooseAvatar(BuildContext sheetContext, String avatar) async {
    Navigator.pop(sheetContext);
    final oldAvatar = _avatar;
    await _removeProfilePhoto();
    await _saveString(_avatarKey, avatar);
    if (mounted) setState(() => _avatar = avatar);
    if (!await _syncRemoteProfile(avatar: avatar)) {
      await _saveString(_avatarKey, oldAvatar);
      if (mounted) setState(() => _avatar = oldAvatar);
    }
  }

  Future<void> _removeProfilePhoto({bool showConfirmation = false}) async {
    final oldPath = _profilePhotoPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilePhotoKey);
    if (oldPath != null) await _deleteOwnedProfilePhoto(oldPath);
    if (!mounted) return;
    setState(() => _profilePhotoPath = null);
    if (showConfirmation) {
      _showPhotoMessage(
        _isSi ? 'පින්තූරය ඉවත් කළා' : 'Profile picture removed',
      );
    }
  }

  Future<void> _deleteOwnedProfilePhoto(String path) async {
    final directory = await _profilePhotoDirectory();
    final directoryPath = '${directory.absolute.path}${Platform.pathSeparator}';
    final file = File(path).absolute;
    if (!file.path.startsWith(directoryPath)) return;
    if (await file.exists()) await file.delete();
  }

  void _showPhotoMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
  }

  void _editName() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isSi ? 'නම වෙනස් කරන්න' : 'Edit your name',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: _isSi ? 'නම ඇතුළත් කරන්න' : 'Enter your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isSi ? 'අවලංගු' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newName = controller.text.trim();
              Navigator.pop(context);
              if (newName.isEmpty || newName == _name) return;
              final oldName = _name;
              setState(() => _name = newName);
              await _saveString(_studentNameKey, newName);
              if (await _syncRemoteProfile(name: newName)) {
                widget.onStudentNameChanged?.call(newName);
              } else {
                await _saveString(_studentNameKey, oldName);
                if (mounted) setState(() => _name = oldName);
              }
            },
            child: Text(
              _isSi ? 'සුරකින්න' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setGrade(int grade) async {
    final safeGrade = grade.clamp(1, 2);
    if (safeGrade == _grade) return;
    final oldGrade = _grade;
    setState(() => _grade = safeGrade);
    await _saveInt(AppConstants.keyGradeLevel, safeGrade);
    if (await _syncRemoteProfile(gradeLevel: safeGrade)) {
      widget.onGradeChanged?.call(safeGrade);
    } else {
      await _saveInt(AppConstants.keyGradeLevel, oldGrade);
      if (mounted) setState(() => _grade = oldGrade);
    }
  }

  Future<void> _setLanguage(String language) async {
    if (language != 'english' && language != 'sinhala') return;
    if (language == _language) return;
    final oldLanguage = _language;
    setState(() => _language = language);
    await StorageService().setLanguage(language);
    if (await _syncRemoteProfile(preferredLanguage: language)) {
      widget.onLanguageChanged?.call(language);
    } else {
      await StorageService().setLanguage(oldLanguage);
      if (mounted) setState(() => _language = oldLanguage);
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
        content: Text(
          _isSi
              ? 'ඔබට නැවත පිවිසීමට භාෂාව සහ ශ්‍රේණිය නැවත තෝරාගත යුතුය.'
              : 'You\'ll need to pick your language and grade again next time.',
          style: GoogleFonts.poppins(),
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

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(body, style: GoogleFonts.poppins(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isSi ? 'හරි' : 'Got it'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isSi ? '👤 පැතිකඩ' : '👤 My Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ReadBuddyBackground(
        accent: AppColors.sunshine,
        secondaryAccent: AppColors.coral,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildTeacherConnectionCard(),
              const SizedBox(height: 24),
              _buildSectionTitle(_isSi ? '🌐 භාෂාව' : '🌐 Language'),
              const SizedBox(height: 12),
              _buildLanguagePicker(),
              const SizedBox(height: 12),
              _buildProfileOption(
                emoji: '🎓',
                title: _isSi ? 'ශ්‍රේණිය' : 'Grade level',
                subtitle: _isSi
                    ? 'දැනට $_grade ශ්‍රේණිය'
                    : 'Currently Grade $_grade',
                color: AppColors.teal,
                child: _buildGradePicker(),
              ),
              const SizedBox(height: 12),
              _buildProfileOption(
                emoji: '⚙️',
                title: _isSi ? 'උදව් සහ තොරතුරු' : 'Help and information',
                subtitle: _isSi
                    ? 'අවශ්‍ය විට විවෘත කරන්න'
                    : 'Open only when needed',
                color: AppColors.blue,
                child: _buildMoreMenu(),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                _buildProfileOption(
                  emoji: '🧪',
                  title: _isSi ? 'පර්යේෂණ මෙවලම්' : 'Research tools',
                  subtitle: _isSi
                      ? 'Debug build එකේ පමණක් පෙනේ'
                      : 'Visible in debug builds only',
                  color: AppColors.warning,
                  child: _buildCard(
                    child: _menuTile(
                      icon: Icons.draw_rounded,
                      color: AppColors.primary,
                      label: _isSi
                          ? 'CNN පුහුණු දත්ත එකතු කරන්න'
                          : 'CNN Training Data Collector',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TraceTrainingCollectorScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _buildLogoutButton(),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${AppConstants.appName} • v${AppConstants.appVersion}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherConnectionCard() {
    final code = _joinCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF9F7), Color(0xFFF1EFFF)],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSi
                          ? 'ගුරුවරයා සමඟ සම්බන්ධ කරන්න'
                          : 'Connect with a teacher',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isSi
                          ? 'මෙම කේතය විශ්වාසවන්ත ගුරුවරයාට දෙන්න'
                          : 'Share this code with the trusted teacher',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: _joinCodeLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : code == null || code.isEmpty
                ? Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isSi
                              ? 'කේතය ලබාගත නොහැක. අන්තර්ජාලය පරීක්ෂා කර නැවත උත්සාහ කරන්න.'
                              : 'Could not load the code. Check the internet and retry.',
                          style: GoogleFonts.notoSansSinhala(fontSize: 10.5),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _joinCodeLoading = true);
                          _loadJoinCode();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.primary,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          code.split('').join(' '),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _copyJoinCode,
                        tooltip: _isSi ? 'කේතය copy කරන්න' : 'Copy code',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 19),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildProfileOption({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            title,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
          iconColor: color,
          collapsedIconColor: color,
          children: [child],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showProfilePictureSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: _profilePhotoPath == null
                      ? null
                      : FileImage(File(_profilePhotoPath!)),
                  child: _profilePhotoPath == null
                      ? Text(_avatar, style: const TextStyle(fontSize: 40))
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _photoBusy
                          ? Icons.hourglass_top_rounded
                          : Icons.camera_alt,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _editName,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 16, color: Colors.white70),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSi
                      ? 'ශ්‍රේණිය $_grade • ${_progress.totalPoints} ලකුණු'
                      : 'Grade $_grade • ${_progress.totalPoints} Points',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_progress.totalStars}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_progress.currentStreak} ${_isSi ? "දින" : "Days"}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _buildLanguagePicker() {
    final options = [
      ('english', _isSi ? 'ඉංග්‍රීසි' : 'English', '🇬🇧'),
      ('sinhala', _isSi ? 'සිංහල' : 'Sinhala', '🇱🇰'),
    ];
    return _buildCard(
      child: Row(
        children: options.map((o) {
          final selected = _language == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setLanguage(o.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Text(o.$3, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      o.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGradePicker() {
    return _buildCard(
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: AppConstants.gradeLevels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final grade = AppConstants.gradeLevels[i];
            final selected = _grade == grade;
            return GestureDetector(
              onTap: () => _setGrade(grade),
              child: Container(
                width: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  '$grade',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: selected ? Colors.white : AppColors.black,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return _buildCard(
      child: Column(
        children: [
          _menuTile(
            icon: Icons.help_rounded,
            color: const Color(0xFFFF9800),
            label: _isSi ? 'උදව් සහ සහාය' : 'Help & Support',
            onTap: () => _showInfoDialog(
              _isSi ? 'උදව් සහ සහාය' : 'Help & Support',
              _isSi
                  ? '"පුහුණු මඟ" ටැබය ඔබේ සත්‍ය ප්‍රතිඵල අනුව ඊළඟ හොඳම පුහුණුව පෙන්වයි.'
                  : 'The "My Coach" tab uses your recorded results to show the best practice to do next.',
            ),
          ),
          const Divider(height: 20),
          _menuTile(
            icon: Icons.info_rounded,
            color: const Color(0xFF4CAF50),
            label: _isSi ? 'මෙම යෙදුම ගැන' : 'About This App',
            onTap: () => _showInfoDialog(
              AppConstants.appName,
              _isSi
                  ? 'අනුවාදය ${AppConstants.appVersion}\n\nළමුන්ට සිංහල හා ඉංග්‍රීසි කියවීමේ හැකියාව වර්ධනය කරගැනීමට උපකාර කරන AI බලගැන්වූ කියවීමේ සහායක යෙදුමකි.'
                  : 'Version ${AppConstants.appVersion}\n\nAn AI-powered reading companion that helps kids build Sinhala and English reading skills through stories, quizzes, and vocabulary practice.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          _isSi ? 'නික්මෙන්න' : 'Log Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
