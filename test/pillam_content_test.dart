import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_assistant_app/screens/learning/models/grade_content.dart';
import 'package:reading_assistant_app/screens/learning/widgets/grade_2_content.dart';
import 'package:reading_assistant_app/widgets/task_picture.dart';

void main() {
  test('core pillam use the verified Grade 2 curriculum names', () {
    final namesBySign = {
      for (final item in Grade2Content.pillam.where(
        (item) => item.category == 'core',
      ))
        item.pillam: item.nameSi,
    };

    expect(namesBySign, {
      'ා': 'ඇලපිල්ල',
      'ැ': 'කෙටි ඇදපිල්ල',
      'ෑ': 'දික් ඇදපිල්ල',
      'ි': 'කෙටි ඉස්පිල්ල',
      'ී': 'දික් ඉස්පිල්ල',
      'ු': 'කෙටි පාපිල්ල',
      'ූ': 'දික් පාපිල්ල',
      'ෙ': 'කොම්බුව',
      'ේ': 'කොම්බුව සහ හල් කිරීම',
      'ො': 'කොම්බුව සහිත ඇලපිල්ල',
      'ෝ': 'කොම්බුව, ඇලපිල්ල සහිත හල් කිරීම',
      '්': 'හල් කිරීම',
    });
  });

  test('every naming question agrees with the shared pillam name', () {
    final namesBySign = {
      for (final item in Grade2Content.pillam.where(
        (item) => item.category == 'core',
      ))
        item.pillam: item.nameSi,
    };

    for (final question in Grade2Content.pillamNamingQuestions) {
      expect(
        question.options[question.correctIndex],
        namesBySign[question.pillam],
        reason: 'Wrong authored answer for ${question.pillam}',
      );
    }
  });

  test('pillam names do not contain the old malformed spellings', () {
    for (final item in Grade2Content.pillam) {
      expect(item.nameSi, isNot(contains('ැලපිල්ල')));
      expect(item.nameSi, isNot(contains('ැදපිල්ල')));
      expect(item.nameSi, isNot(contains('හල්පිල්ල')));
    }
  });

  testWidgets(
    'English navigation still displays educational pillam names in Sinhala',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Grade2ContentWidget(selectedLanguage: 'english'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ඇලපිල්ල'), findsWidgets);
      expect(find.text('කෙටි ඇදපිල්ල'), findsOneWidget);
      expect(find.text('කොම්බුව සහිත ඇලපිල්ල'), findsOneWidget);
      expect(find.text('Aela-pilla'), findsNothing);
      expect(find.text('aa'), findsNothing);
      expect(find.byType(TaskPicture), findsNWidgets(13));
      expect(find.text('ක  +  ◌ා  =  කා'), findsOneWidget);
    },
  );

  testWidgets('selecting a pillam scrolls its detail panel into view', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Grade2ContentWidget(selectedLanguage: 'sinhala')),
      ),
    );
    await tester.pumpAndSettle();

    final pillamScroll = find.byKey(const ValueKey('pillam_tab_scroll'));
    final target = find.text('දික් ඉස්පිල්ල');
    final controller = tester
        .widget<SingleChildScrollView>(pillamScroll)
        .controller!;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final offsetBeforeSelection = controller.offset;
    expect(offsetBeforeSelection, greaterThan(0));

    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(controller.offset, lessThan(offsetBeforeSelection));
    expect(find.text('ක  +  ◌ී  =  කී'), findsOneWidget);
  });
}
