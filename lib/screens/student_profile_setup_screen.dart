import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/student_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../main_screen.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  final String selectedLanguage;

  const StudentProfileSetupScreen({super.key, required this.selectedLanguage});

  @override
  State<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  String? _selectedAvatar;
  String? _pickedPhotoPath;
  int? _selectedGrade;
  bool _isSaving = false;
  bool _photoBusy = false;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _avatars = ['🐶', '🐱', '🦁', '🐻', '👧🏽', '👦🏽'];
  final List<int> _grades = AppConstants.gradeLevels;
  bool get _isSi => widget.selectedLanguage == 'sinhala';
  String _copy(String english, String sinhala) => _isSi ? sinhala : english;

  Future<void> _completeSetup() async {
    if (_isSaving) return;
    if (!(_formKey.currentState!.validate() &&
        (_selectedAvatar != null || _pickedPhotoPath != null) &&
        _selectedGrade != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Please fill all details! We need to know you better. 🌟',
              'කරුණාකර සියලු තොරතුරු පුරවන්න! අපි ඔබව හඳුනාගනිමු. 🌟',
            ),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.pinkAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final student = await StudentService().createStudent(
        name: _nameController.text.trim(),
        // A child's photo never leaves the device. Teachers see this neutral
        // fallback avatar unless the family chose one of the emoji avatars.
        avatar: _selectedAvatar ?? '🧒',
        gradeLevel: _selectedGrade!,
        preferredLanguage: widget.selectedLanguage,
      );
      await StorageService().setStudentId(student.id);
      await StorageService().setGradeLevel(student.gradeLevel);
      await StorageService().setLanguage(student.preferredLanguage);
      await StorageService().setFirstLaunch(false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${AppConstants.keyAvatar}_${student.id}',
        student.avatar,
      );
      await _persistSelectedPhoto(prefs, student.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            selectedLanguage: student.preferredLanguage,
            studentName: student.name,
            gradeLevel: student.gradeLevel,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Could not save your profile. Please try again.',
              'ඔබේ පැතිකඩ සුරැකීමට නොහැකි විය. නැවත උත්සාහ කරන්න.',
            ),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _copy('Set Up Profile', 'පැතිකඩ සකසන්න'),
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepDot(true),
                    _buildStepLine(true),
                    _buildStepDot(true),
                    _buildStepLine(false),
                    _buildStepDot(false),
                  ],
                ),
                const SizedBox(height: 30),

                // Greeting Character
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("🦉", style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 0,
                          child: Text(
                            _copy(
                              "Let's make this app\nyours!",
                              'මේ යෙදුම ඔබට\nගැළපෙන ලෙස සකසමු!',
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Profile picture / avatar selection
                _buildSectionTitle(
                  _copy(
                    '1. Add a photo or choose an avatar',
                    '1. ඡායාරූපයක් එක් කරන්න හෝ රූපයක් තෝරන්න',
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: _buildPhotoPicker()),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    _copy(
                      'Your photo stays only on this device 🔒',
                      'ඔබේ ඡායාරූපය මෙම උපාංගයේ පමණක් සුරැකේ 🔒',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _avatars.map((avatar) {
                    bool isSelected =
                        _pickedPhotoPath == null && _selectedAvatar == avatar;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _pickedPhotoPath = null;
                        _selectedAvatar = avatar;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey[300]!,
                            width: 3,
                          ),
                          boxShadow: isSelected
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
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),

                // Name Input
                _buildSectionTitle(
                  _copy("2. What's your name?", '2. ඔබේ නම කුමක්ද?'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: _copy(
                      'Enter your nickname',
                      'ඔබේ කෙටි නම ඇතුළත් කරන්න',
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return _copy(
                        'Please enter a valid name!',
                        'නිවැරදි නමක් ඇතුළත් කරන්න!',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Grade Selection
                _buildSectionTitle(
                  _copy(
                    '3. What grade are you in?',
                    '3. ඔබ ඉගෙන ගන්නේ කුමන ශ්‍රේණියේද?',
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _grades.map((grade) {
                      bool isSelected = _selectedGrade == grade;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(_copy('Grade $grade', 'ශ්‍රේණිය $grade')),
                          labelStyle: GoogleFonts.poppins(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGrade = grade);
                            }
                          },
                          backgroundColor: AppColors.white,
                          selectedColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 50),

                // Finish Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _completeSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _copy("Let's Go! 🚀", 'අපි පටන් ගනිමු! 🚀'),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final hasPhoto = _pickedPhotoPath != null;
    return Column(
      children: [
        InkWell(
          onTap: _photoBusy ? null : _showPhotoSourceSheet,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.file(
                          File(_pickedPhotoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: _photoBusy
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _photoBusy ? null : _showPhotoSourceSheet,
          icon: Icon(
            hasPhoto ? Icons.edit_rounded : Icons.photo_camera_rounded,
            size: 19,
          ),
          label: Text(
            hasPhoto
                ? _copy('Change photo', 'ඡායාරූපය වෙනස් කරන්න')
                : _copy('Add my photo', 'මගේ ඡායාරූපය එක් කරන්න'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(Icons.face_rounded, color: AppColors.primary, size: 50),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
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
                _copy('Choose a photo', 'ඡායාරූපයක් තෝරන්න'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _photoSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: _copy('Gallery', 'ගැලරිය'),
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _choosePhoto(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _photoSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: _copy('Camera', 'කැමරාව'),
                      color: AppColors.teal,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _choosePhoto(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              if (_pickedPhotoPath != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() => _pickedPhotoPath = null);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(_copy('Remove photo', 'ඡායාරූපය ඉවත් කරන්න')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePhoto(ImageSource source) async {
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
      if (picked == null || !mounted) return;
      setState(() => _pickedPhotoPath = picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Could not open that photo. Please try again.',
              'ඡායාරූපය විවෘත කිරීමට නොහැකි වුණා. නැවත උත්සාහ කරන්න.',
            ),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  String _safeImageExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final extension = path.substring(dot).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
    return allowed.contains(extension) ? extension : '.jpg';
  }

  Future<void> _persistSelectedPhoto(
    SharedPreferences prefs,
    String studentId,
  ) async {
    final photoKey = '${AppConstants.keyProfilePhotoPath}_$studentId';
    final sourcePath = _pickedPhotoPath;
    if (sourcePath == null) {
      await prefs.remove(photoKey);
      return;
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}profile',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    final extension = _safeImageExtension(sourcePath);
    final safeStudentId = studentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destination = File(
      '${directory.path}${Platform.pathSeparator}child_profile_$safeStudentId$extension',
    );
    await File(sourcePath).copy(destination.path);
    await prefs.setString(photoKey, destination.path);
  }

  Widget _buildStepDot(bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 40,
      height: 4,
      color: active ? AppColors.primary : AppColors.grey[300],
    );
  }
}
