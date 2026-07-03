import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/teacher/presentation/class_management_screen.dart';
import 'package:fema/features/teacher/domain/class_models.dart';
import 'package:fema/features/teacher/domain/class_repository.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Minimal pump helper: ProviderScope + MaterialApp.
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void _setPhoneSize(WidgetTester tester) {
  // 600 × 960 logical px at 2x gives plenty of horizontal room for the
  // "Take attendance for …" CTA row and avoids overflow exceptions.
  tester.view.physicalSize = const Size(1200, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ---------------------------------------------------------------------------
// Fixture data — two classes, each with two students.
// ---------------------------------------------------------------------------
const _student1 = ClassStudent(
  id: 's1',
  name: 'Alice Mekonnen',
  grade: 'Grade 7',
  averageScore: 88,
  attendanceRate: 95,
);

const _student2 = ClassStudent(
  id: 's2',
  name: 'Bob Tadesse',
  grade: 'Grade 7',
  averageScore: 72,
  attendanceRate: 80,
);

const _student3 = ClassStudent(
  id: 's3',
  name: 'Carol Girma',
  grade: 'Grade 8',
  averageScore: 90,
  attendanceRate: 98,
);

const _student4 = ClassStudent(
  id: 's4',
  name: 'David Kebede',
  grade: 'Grade 8',
  averageScore: 65,
  attendanceRate: 70,
);

const _classMath = TeacherClass(
  id: 'cls1',
  name: 'Math Grade 7',
  subject: 'math',
  grade: 'Grade 7',
  students: [_student1, _student2],
);

const _classEnglish = TeacherClass(
  id: 'cls2',
  name: 'English Grade 8',
  subject: 'english',
  grade: 'Grade 8',
  students: [_student3, _student4],
);

/// Override teacherClassesProvider to emit the fixture list immediately.
List<Override> _classOverrides(List<TeacherClass> classes) => [
      teacherClassesProvider.overrideWith(
        (ref) => Stream.value(classes),
      ),
    ];

void main() {
  group('ClassManagementScreen', () {
    testWidgets('class names render in the Students segment header',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const ClassManagementScreen(),
        overrides: _classOverrides([_classMath, _classEnglish]),
      ));
      await tester.pump();
      await tester.pump(); // settle StreamProvider

      // The class section headers render the class name in upper-case
      expect(find.textContaining('MATH GRADE 7', skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('ENGLISH GRADE 8', skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('Students segment shows student names under their class headers',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const ClassManagementScreen(),
        overrides: _classOverrides([_classMath, _classEnglish]),
      ));
      await tester.pump();
      await tester.pump();

      // Students segment is active by default (index 0).
      // Scroll through the list to confirm all student rows are present.
      expect(find.text('Alice Mekonnen', skipOffstage: false), findsOneWidget);
      expect(find.text('Bob Tadesse', skipOffstage: false), findsOneWidget);
      expect(find.text('Carol Girma', skipOffstage: false), findsOneWidget);
      expect(find.text('David Kebede', skipOffstage: false), findsOneWidget);
    });

    testWidgets(
        'tapping Attendance segment shows per-class attendance sections',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const ClassManagementScreen(),
        overrides: _classOverrides([_classMath, _classEnglish]),
      ));
      await tester.pump();
      await tester.pump();

      // Switch to the Attendance segment
      await tester.tap(find.text('Attendance'));
      await tester.pump();

      // Attendance tab shows class names as section headers (not upper-case)
      expect(find.text('Math Grade 7', skipOffstage: false), findsOneWidget);
      expect(find.text('English Grade 8', skipOffstage: false), findsOneWidget);

      // Each section also shows the student count
      expect(find.textContaining('2 students', skipOffstage: false),
          findsAtLeast(1));
    });

    testWidgets('empty class list renders "No classes yet"', (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const ClassManagementScreen(),
        overrides: _classOverrides([]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('No classes yet'), findsOneWidget);
    });
  });
}
