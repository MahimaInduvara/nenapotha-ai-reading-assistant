import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/config/navigation_config.dart';
import 'package:reading_assistant_app/screens/redesign/language_selection_screen.dart';
import 'package:reading_assistant_app/screens/profile_screen.dart';
import 'package:reading_assistant_app/theme/app_theme.dart';
import 'package:reading_assistant_app/utils/app_colors.dart';
import 'package:reading_assistant_app/widgets/bottom_nav_bar.dart';

void main() {
  test('navigation labels understand the stored Sinhala language value', () {
    expect(NavigationConfig.navItems.first.getLabel('sinhala'), 'මුල් පිටුව');
    expect(NavigationConfig.navItems.first.getLabel('si'), 'මුල් පිටුව');
    expect(NavigationConfig.navItems.first.getLabel('english'), 'Home');
  });

  testWidgets('redesigned language cards expose a clear selected state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LanguageSelectionScreen()),
    );

    expect(find.text('Select a language'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first),
      isNotNull,
    );
  });

  testWidgets('selecting Sinhala localizes the language screen immediately', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LanguageSelectionScreen()),
    );

    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    expect(find.text('ඔබේ ඉගෙනුම්\nභාෂාව තෝරන්න'), findsOneWidget);
    expect(find.text('ඉදිරියට යන්න'), findsOneWidget);
    expect(
      find.text('All app instructions will appear in English.'),
      findsNothing,
    );
  });

  test('profile screen receives the app-wide language callback', () {
    void onLanguageChanged(String _) {}

    final screen = NavigationConfig.buildScreen(
      4,
      selectedLanguage: 'english',
      studentName: 'Reader',
      gradeLevel: 1,
      onLanguageChanged: onLanguageChanged,
    );

    expect(screen, isA<ProfileScreen>());
    expect(
      (screen as ProfileScreen).onLanguageChanged,
      same(onLanguageChanged),
    );
  });

  testWidgets('floating navigation presents all five main areas', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            selectedLanguage: 'english',
            onTap: (index) => selected = index,
          ),
        ),
      ),
    );

    for (final label in ['Home', 'Learn', 'My Coach', 'Progress', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/branding/nenapotha_logo.png',
      ),
      findsWidgets,
    );
    await tester.tap(find.text('My Coach'));
    expect(selected, 2);
  });

  testWidgets('floating navigation localizes every main area to Sinhala', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            selectedLanguage: 'sinhala',
            onTap: (_) {},
          ),
        ),
      ),
    );

    for (final label in [
      'මුල් පිටුව',
      'ඉගෙනීම',
      'පුහුණු මඟ',
      'ප්‍රගතිය',
      'පැතිකඩ',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  test(
    'theme uses the shared NenaPotha brand and accessible control height',
    () {
      final theme = AppTheme.light;
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(
        theme.elevatedButtonTheme.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(48),
      );
    },
  );
}
