import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/readbuddy_background.dart';
import '../student_gate_screen.dart';
import '../teacher_dashboard_screen.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    Future<void>.delayed(const Duration(milliseconds: 2300), _routeNext);
  }

  Future<void> _routeNext() async {
    if (!mounted) return;
    final loggedIn = AuthService().currentUser != null;
    final language = StorageService().getLanguage();
    final role = StorageService().getAccountRole();
    final Widget destination;
    if (!loggedIn) {
      destination = const LanguageSelectionScreen();
    } else if (role == 'teacher') {
      destination = TeacherDashboardScreen(selectedLanguage: language);
    } else {
      destination = StudentGateScreen(selectedLanguage: language);
    }
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(opacity: animation, child: destination),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSi = StorageService().getLanguage() == 'sinhala';
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _orb(240, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _orb(270, AppColors.coral.withValues(alpha: 0.22)),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      ScaleTransition(
                        scale: _scale,
                        child: const ReadBuddyLogo(size: 112, onDark: true),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'NenaPotha AI',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSi
                            ? 'ඔබේ පුංචි කියවීමේ චාරිකාව'
                            : 'Your little reading adventure',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          isSi
                              ? 'කියවමු  •  පුහුණු වෙමු  •  දියුණු වෙමු'
                              : 'Read  •  Practise  •  Grow',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansSinhala(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isSi
                            ? '1 සහ 2 ශ්‍රේණි දරුවන් සඳහා'
                            : 'Made for Grade 1 & 2 learners',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
