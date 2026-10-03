import 'package:flutter/material.dart';

class AppColors {
  // Shared ReadBuddy brand colours. Individual sections use the coral, teal,
  // violet, and blue accents while navigation stays consistently indigo.
  static const primary = Color(0xFF5B4CF0);
  static const primaryDark = Color(0xFF3F35B5);
  static const primarySoft = Color(0xFFEDEBFF);
  static const secondary = Color(0xFFFF7557);
  static const coral = Color(0xFFFF7557);
  static const teal = Color(0xFF13A89E);
  static const blue = Color(0xFF3784F7);
  static const sunshine = Color(0xFFFFC857);
  static const success = Color(0xFF20A464);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE5484D);
  static const background = Color(0xFFF6F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F2F8);
  static const textPrimary = Color(0xFF20213A);
  static const textSecondary = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const white = Colors.white;
  static const black = textPrimary;
  static const grey = Colors.grey;

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF8B5CF6)],
  );

  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, Color(0xFFFFA26B)],
  );

  static const gradientCool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, Color(0xFF5AC8FA)],
  );

  // A rotating "kid friendly" palette for per-item accenting in children's
  // learning screens (e.g. Grade 1 letters/words) — cycle with index % length
  // so each item gets its own personality instead of one flat color.
  static const kidPalette = [
    Color(0xFFFF6B6B), // coral
    Color(0xFFFF9F43), // orange
    Color(0xFFFECA57), // yellow
    Color(0xFF1DD1A1), // green
    Color(0xFF54A0FF), // blue
    Color(0xFF9C88FF), // purple
    Color(0xFFFF6B9D), // pink
  ];

  static Color kidColorFor(int index) => kidPalette[index % kidPalette.length];
}
