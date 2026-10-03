import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/screens/redesign/language_selection_screen.dart';
import 'package:reading_assistant_app/theme/app_theme.dart';

void main() {
  testWidgets('language selection renders both supported languages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LanguageSelectionScreen()),
    );

    expect(find.text('Choose your\nlearning language'), findsOneWidget);
    expect(
      find.text('All app instructions will appear in English.'),
      findsOneWidget,
    );
    expect(find.text('ඔබේ ඉගෙනුම්\nභාෂාව තෝරන්න'), findsNothing);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('Select a language'), findsOneWidget);
    expect(find.textContaining('Grade 3'), findsNothing);
  });
}
