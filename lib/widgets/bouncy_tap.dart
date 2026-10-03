// lib/widgets/bouncy_tap.dart
// A small scale-down-on-press wrapper — reads as more playful/tactile than a
// flat GestureDetector, used across the kid-facing Grade 1 letter/word UI.

import 'package:flutter/material.dart';

class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyTap({super.key, required this.child, required this.onTap});

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  double _scale = 1.0;

  void _setScale(double value) {
    if (mounted) setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.9),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
