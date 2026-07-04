// Pure widget test for the wizard shell — no Firebase required.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fema/features/library/domain/library_provider.dart';
import 'package:fema/features/library/domain/models.dart';
import 'package:fema/features/teacher/course_editor/domain/course_editor_repository.dart';
import 'package:fema/features/teacher/course_editor/presentation/course_wizard_screen.dart';

Course _course(CourseStatus status) => Course(
      id: 'c1',
      title: 'Chem 101',
      description: 'Introduction to chemistry concepts.',
      subject: CourseSubject.science,
      grade: 'Grade 10',
      thumbnailUrl: '',
      lessons: const [],
      status: status,
    );

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(CourseStatus status) {
  return ProviderScope(
    overrides: [
      teacherCoursesProvider.overrideWith((_) async => [_course(status)]),
      courseEditorLessonsProvider.overrideWith(
        (ref, arg) async => const <Map<String, dynamic>>[],
      ),
    ],
    child: const MaterialApp(
      home: CourseWizardScreen(courseId: 'c1'),
    ),
  );
}

void main() {
  group('CourseWizardScreen saved tick', () {
    testWidgets('editing a draft shows the "Saved as draft" tick',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(CourseStatus.draft));
      await tester.pump();
      await tester.pump();

      expect(find.text('Saved as draft'), findsOneWidget);
    });

    testWidgets('editing a published course does not claim "Saved as draft"',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(CourseStatus.published));
      await tester.pump();
      await tester.pump();

      expect(find.text('Saved as draft'), findsNothing);
      expect(find.text('Saved'), findsOneWidget);
    });
  });
}
