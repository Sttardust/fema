// Pure widget test for BasicsStep — no Firebase required.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fema/features/teacher/course_editor/presentation/basics_step.dart';

/// Minimal pump helper.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('BasicsStep', () {
    testWidgets(
        'Continue button is disabled initially; filling title+subject+grade enables it '
        'and tapping captures correct data', (tester) async {
      _setPhoneSize(tester);

      BasicsData? captured;

      await tester.pumpWidget(
        _wrap(
          BasicsStep(
            onSubmit: (d) async => captured = d,
          ),
        ),
      );

      // 1. Continue should be disabled initially (no title, subject, grade).
      //    PillButton is disabled when _canSubmit == false — InkWell.onTap is null.
      //    Tap it and verify captured stays null.
      await tester.tap(find.text('Continue'), warnIfMissed: false);
      await tester.pump();
      expect(captured, isNull);

      // 2. Enter title
      await tester.enterText(
        find.byType(TextField).first,
        'Test Course Title',
      );
      await tester.pump();

      // 3. Select subject 'Science'
      // Tap on the dropdown container rather than the obscured hint text.
      await tester.tap(find.text('Choose a subject'), warnIfMissed: false);
      await tester.pumpAndSettle();
      // The dropdown adds an overlay; the display label appears twice — once in
      // the field (hidden under overlay) and once in the menu.  Tap the last one.
      await tester.tap(find.text('Science').last);
      await tester.pumpAndSettle();

      // 4. Select grade 'Grade 10'
      await tester.tap(find.text('Choose a grade'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grade 10').last);
      await tester.pumpAndSettle();

      // 5. Continue should now be enabled — tap it.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.title, equals('Test Course Title'));
      expect(captured!.subject, equals('science'));
      expect(captured!.grade, equals('Grade 10'));
    });

    testWidgets('Adding an objective row and tapping Continue captures it',
        (tester) async {
      _setPhoneSize(tester);

      BasicsData? captured;

      await tester.pumpWidget(
        _wrap(
          BasicsStep(
            onSubmit: (d) async => captured = d,
          ),
        ),
      );

      // Fill required fields first.
      await tester.enterText(find.byType(TextField).first, 'Course with Obj');
      await tester.pump();

      await tester.tap(find.text('Choose a subject'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Math').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose a grade'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grade 5').last);
      await tester.pumpAndSettle();

      // Tap 'Add objective'
      await tester.tap(find.text('Add objective'));
      await tester.pumpAndSettle();

      // Enter objective text — the new row's TextField is the last one.
      final objField = find.byType(TextField).last;
      await tester.enterText(objField, 'Objective A');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.learningObjectives, equals(['Objective A']));
    });

    testWidgets('initial BasicsData prefills the form correctly', (tester) async {
      _setPhoneSize(tester);

      const initial = BasicsData(
        title: 'Pre-filled Title',
        description: 'Pre-filled description',
        subject: 'english',
        grade: 'Grade 7',
        learningObjectives: ['Obj 1'],
      );

      await tester.pumpWidget(
        _wrap(
          BasicsStep(
            initial: initial,
            onSubmit: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title field is pre-filled
      expect(find.text('Pre-filled Title'), findsOneWidget);

      // Subject dropdown shows 'English'
      expect(find.text('English'), findsOneWidget);

      // Grade shows Grade 7
      expect(find.text('Grade 7'), findsOneWidget);
    });
  });
}
