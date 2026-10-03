// lib/screens/parent_login_screen.dart
// Real Firebase Authentication for the parent/teacher portal. Runs right
// after language selection and before any student profile exists — the
// signed-in account is what student profiles get linked to in Firestore.
//
// Role ('parent' | 'teacher') is chosen once at sign-up and determines
// where the account lands after auth: a parent goes through
// StudentGateScreen to create/select their own child's profile; a teacher
// goes straight to TeacherDashboardScreen, which shows only students
// they've linked via a join code (see StudentService.redeemJoinCode).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import 'student_gate_screen.dart';
import 'teacher_dashboard_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  final String selectedLanguage;

  const ParentLoginScreen({super.key, required this.selectedLanguage});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSignUp = false;
  bool _isBusy = false;
  String _selectedRole = 'parent'; // 'parent' | 'teacher' — sign-up only

  bool get _isSi => widget.selectedLanguage == 'sinhala';

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return _isSi
            ? 'වලංගු නොවන විද්‍යුත් තැපැල් ලිපිනයකි.'
            : 'That email address is not valid.';
      case 'user-not-found':
        return _isSi
            ? 'මෙම විද්‍යුත් තැපෑලට ගිණුමක් නොමැත.'
            : 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return _isSi ? 'මුරපදය වැරදිය.' : 'Incorrect password.';
      case 'email-already-in-use':
        return _isSi
            ? 'මෙම විද්‍යුත් තැපෑල දැනටමත් භාවිතයේ ඇත.'
            : 'That email is already registered — try logging in instead.';
      case 'weak-password':
        return _isSi
            ? 'මුරපදය ඉතා දුර්වලයි (අවම අකුරු 6ක්).'
            : 'Password is too weak (minimum 6 characters).';
      case 'network-request-failed':
        return _isSi
            ? 'අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කරන්න.'
            : 'Check your internet connection and try again.';
      case 'too-many-requests':
        return _isSi
            ? 'උත්සාහයන් ගණන වැඩිය. පසුව උත්සාහ කරන්න.'
            : 'Too many attempts — please try again later.';
      default:
        return _isSi
            ? 'දෝෂයක් සිදු විය: ${e.message}'
            : 'Something went wrong: ${e.message}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      String role;
      if (_isSignUp) {
        await AuthService().signUp(
          email: _emailController.text,
          password: _passwordController.text,
          role: _selectedRole,
        );
        role = _selectedRole;
      } else {
        await AuthService().signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        role = await AuthService().getRole();
      }
      await _routeByRole(role);
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(e));
    } catch (e) {
      _showError(_isSi ? 'අනපේක්ෂිත දෝෂයක්: $e' : 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _skipForChildren() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await AuthService().signInAnonymously();
      await _routeByRole('parent'); // guest/child mode is always parent-side
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(e));
    } catch (e) {
      _showError(_isSi ? 'අනපේක්ෂිත දෝෂයක්: $e' : 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError(
        _isSi
            ? 'මුලින්ම වලංගු විද්‍යුත් තැපෑලක් ඇතුළත් කරන්න.'
            : 'Enter a valid email address first.',
      );
      return;
    }
    setState(() => _isBusy = true);
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSi
                ? 'මුරපදය යළි පිහිටුවීමේ විද්‍යුත් තැපෑලක් යවා ඇත.'
                : 'Password reset email sent.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _routeByRole(String role) async {
    await StorageService().setAccountRole(role);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => role == 'teacher'
            ? TeacherDashboardScreen(selectedLanguage: widget.selectedLanguage)
            : StudentGateScreen(selectedLanguage: widget.selectedLanguage),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Child/Guest Mode Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    onPressed: _isBusy ? null : _skipForChildren,
                    icon: const Text("👦👧", style: TextStyle(fontSize: 20)),
                    label: Text(
                      _isSi ? "මඟහරින්න (දරු ප්‍රකාරය)" : "Skip (Child Mode)",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Header
                Icon(
                  Icons.shield_outlined,
                  size: 80,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  _isSignUp
                      ? (_isSi
                            ? "දෙමව්පිය/ගුරු ලියාපදිංචිය"
                            : "Parent/Teacher Registration")
                      : (_isSi
                            ? "දෙමව්පිය/ගුරු පිවිසුම"
                            : "Parent/Teacher Portal"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isSignUp
                      ? (_isSi
                            ? "ඔබේ දරුවාගේ ප්‍රගතිය නිරීක්ෂණය කිරීමට ගිණුමක් සාදන්න."
                            : "Create an account to track your child's progress.")
                      : (_isSi
                            ? "විස්තරාත්මක විශ්ලේෂණ බැලීමට පිවිසෙන්න."
                            : "Login to view detailed analytics and manage settings."),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                if (_isSignUp) ...[
                  _buildRolePicker(),
                  const SizedBox(height: 24),
                ],

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: _isSi ? "විද්‍යුත් තැපෑල" : "Email Address",
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return _isSi
                          ? 'වලංගු විද්‍යුත් තැපෑලක් ඇතුළත් කරන්න'
                          : 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: _isSi ? "මුරපදය" : "Password",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return _isSi
                          ? 'මුරපදයේ අවම අකුරු 6ක් තිබිය යුතුය'
                          : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                if (!_isSignUp) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isBusy ? null : _forgotPassword,
                      child: Text(
                        _isSi ? "මුරපදය අමතකද?" : "Forgot Password?",
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Login / Signup Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: _isBusy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isSignUp
                                ? (_isSi ? "ගිණුම සාදන්න" : "Create Account")
                                : (_isSi ? "පිවිසෙන්න" : "Secure Login"),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // Toggle Login / Signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp
                          ? (_isSi
                                ? "දැනටමත් ගිණුමක් තිබේද? "
                                : "Already have an account? ")
                          : (_isSi
                                ? "ගිණුමක් නැද්ද? "
                                : "Don't have an account? "),
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                    GestureDetector(
                      onTap: _isBusy
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? (_isSi ? "පිවිසෙන්න" : "Login")
                            : (_isSi ? "ලියාපදිංචි වන්න" : "Sign up"),
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolePicker() {
    return Row(
      children: [
        Expanded(
          child: _roleOption(
            'parent',
            _isSi ? "දෙමව්පිය" : "Parent",
            Icons.family_restroom_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _roleOption(
            'teacher',
            _isSi ? "ගුරුවරයා" : "Teacher",
            Icons.school_rounded,
          ),
        ),
      ],
    );
  }

  Widget _roleOption(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
