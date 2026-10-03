import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Shared calm background used by high-level ReadBuddy screens.
class ReadBuddyBackground extends StatelessWidget {
  final Widget child;
  final bool decorated;
  final Color accent;
  final Color secondaryAccent;

  const ReadBuddyBackground({
    super.key,
    required this.child,
    this.decorated = true,
    this.accent = AppColors.primary,
    this.secondaryAccent = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFBF7),
                accent.withValues(alpha: 0.095),
                secondaryAccent.withValues(alpha: 0.075),
                const Color(0xFFF7F4FF),
              ],
              stops: const [0, 0.34, 0.68, 1],
            ),
          ),
        ),
        if (decorated) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PlayfulPatternPainter(
                  accent: accent,
                  secondaryAccent: secondaryAccent,
                ),
              ),
            ),
          ),
          Positioned(
            top: -105,
            right: -85,
            child: _SoftOrb(size: 255, color: accent.withValues(alpha: 0.10)),
          ),
          Positioned(
            left: -75,
            bottom: 70,
            child: _SoftOrb(
              size: 185,
              color: secondaryAccent.withValues(alpha: 0.085),
            ),
          ),
        ],
        child,
      ],
    );
  }
}

class _PlayfulPatternPainter extends CustomPainter {
  final Color accent;
  final Color secondaryAccent;

  const _PlayfulPatternPainter({
    required this.accent,
    required this.secondaryAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final secondPaint = Paint()
      ..color = secondaryAccent.withValues(alpha: 0.095)
      ..style = PaintingStyle.fill;

    final dots = <(double, double, double, bool)>[
      (0.08, 0.11, 5.0, false),
      (0.90, 0.19, 3.5, true),
      (0.06, 0.37, 3.0, true),
      (0.93, 0.48, 5.0, false),
      (0.11, 0.70, 4.0, false),
      (0.88, 0.82, 3.0, true),
      (0.25, 0.93, 4.5, true),
    ];
    for (final dot in dots) {
      canvas.drawCircle(
        Offset(size.width * dot.$1, size.height * dot.$2),
        dot.$3,
        dot.$4 ? secondPaint : dotPaint,
      );
    }

    _drawSparkle(
      canvas,
      Offset(size.width * 0.84, size.height * 0.32),
      9,
      secondPaint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.16, size.height * 0.55),
      7,
      dotPaint,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * 0.22,
        center.dy - radius * 0.22,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.22,
        center.dy + radius * 0.22,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.22,
        center.dy + radius * 0.22,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.22,
        center.dy - radius * 0.22,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlayfulPatternPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.secondaryAccent != secondaryAccent;
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class ReadBuddyLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const ReadBuddyLogo({super.key, this.size = 76, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NenaPotha AI logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onDark ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: onDark ? 0.18 : 0.10),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.12),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: Image.asset(
            'assets/images/branding/nenapotha_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
