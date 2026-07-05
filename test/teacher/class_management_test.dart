import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/services/firestore_service.dart';
import 'package:fema/features/auth/domain/auth_repository.dart';
import 'package:fema/features/teacher/presentation/class_management_screen.dart';
import 'package:fema/features/teacher/domain/class_models.dart';
import 'package:fema/features/teacher/domain/class_repository.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'teacher-1';
}

class _FakeFirestoreService extends Fake implements FirestoreService {}

/// Records createClass calls without touching Firebase.
class _RecordingClassRepo extends TeacherClassRepository {
  _RecordingClassRepo() : super(_FakeFirestoreService());

  Map<String, dynamic>? created;

  @override
  Future<String> createClass({
    required String teacherId,
    required String subject,
    required String grade,
    String? name,
    String? section,
  }) async {
    created = {
      'teacherId': teacherId,
      'subject': subject,
      'grade': grade,
      'name': name,
      'section': section,
    };
    return 'new-class-id';
  }
}

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

    testWidgets('empty state offers New class and opens the create sheet',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const ClassManagementScreen(),
        overrides: _classOverrides([]),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('New class').first);
      await tester.pumpAndSettle();

      expect(find.text('Create class'), findsOneWidget);
      expect(find.text('Choose a subject'), findsOneWidget);
      expect(find.text('Choose a grade'), findsOneWidget);
    });

    testWidgets('creating a class calls the repository with the chosen fields',
        (tester) async {
      _setPhoneSize(tester);
      final repo = _RecordingClassRepo();

      await tester.pumpWidget(_wrap(
        const ClassManagementScreen(),
        overrides: [
          ..._classOverrides([]),
          teacherClassRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        ],
      ));
      await tester.pump();
      await tester.pump();

      // Keep the auth stream alive so it resolves before the create tap —
      // in the app the router watches it; in the test nothing else does.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ClassManagementScreen)),
      );
      container.listen(authStateProvider, (_, _) {});
      await tester.pump();

      await tester.tap(find.text('New class').first);
      await tester.pumpAndSettle();

      // Create is disabled until subject and grade are chosen.
      await tester.tap(find.text('Create class'));
      await tester.pumpAndSettle();
      expect(repo.created, isNull);

      await tester.tap(find.byType(DropdownButton<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Math').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grade 7').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create class'));
      await tester.pumpAndSettle();

      expect(repo.created, isNotNull);
      expect(repo.created!['teacherId'], 'teacher-1');
      expect(repo.created!['subject'], 'math');
      expect(repo.created!['grade'], 'Grade 7');
      // Sheet closed after creating.
      expect(find.text('Create class'), findsNothing);
    });
  });
}
