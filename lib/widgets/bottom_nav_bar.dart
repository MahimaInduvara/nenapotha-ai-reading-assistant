import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/navigation_config.dart';
import '../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String selectedLanguage;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF20213A).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 74,
              backgroundColor: AppColors.surface,
              indicatorColor: Colors.transparent,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return GoogleFonts.notoSansSinhala(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  size: states.contains(WidgetState.selected) ? 25 : 23,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onTap,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: NavigationConfig.navItems
                  .map((item) {
                    final accent = switch (item.index) {
                      0 => AppColors.coral,
                      1 => AppColors.teal,
                      2 => AppColors.primary,
                      3 => AppColors.blue,
                      _ => const Color(0xFFF09A31),
                    };
                    return NavigationDestination(
                      icon: item.index == 2
                          ? Image.asset(
                              'assets/images/branding/nenapotha_logo.png',
                              width: 27,
                              height: 27,
                            )
                          : Icon(item.icon),
                      selectedIcon: Container(
                        width: 45,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: item.index == 2
                            ? Image.asset(
                                'assets/images/branding/nenapotha_logo.png',
                                width: 31,
                                height: 31,
                              )
                            : Icon(item.activeIcon, color: accent, size: 26),
                      ),
                      label: item.getLabel(selectedLanguage),
                      tooltip: item.getLabel(selectedLanguage),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}
