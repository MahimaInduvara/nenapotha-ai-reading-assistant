import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/screens/learning/widgets/grade_1_content.dart';

void main() {
  Widget subject({
    required String interfaceLanguage,
    required String learningLanguage,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Grade1ContentWidget(
          selectedLanguage: interfaceLanguage,
          learningLanguage: learningLanguage,
          showHeader: false,
        ),
      ),
    );
  }

  testWidgets('English interface can teach Sinhala letters', (tester) async {
    await tester.pumpWidget(
      subject(interfaceLanguage: 'english', learningLanguage: 'sinhala'),
    );
    await tester.pump();

    expect(find.text('📖 Letters'), findsOneWidget);
    expect(find.text('අ'), findsWidgets);
  });

  testWidgets('Sinhala interface can teach English letters', (tester) async {
    await tester.pumpWidget(
      subject(interfaceLanguage: 'sinhala', learningLanguage: 'english'),
    );
    await tester.pump();

    expect(find.text('📖 අකුරු'), findsOneWidget);
    expect(find.text('A'), findsWidgets);
  });
}
