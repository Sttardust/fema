import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/services/firestore_service.dart';
import 'package:fema/features/library/domain/library_provider.dart';
import 'package:fema/features/library/domain/models.dart';
import 'package:fema/features/teacher/course_editor/domain/course_editor_repository.dart';
import 'package:fema/features/teacher/course_editor/presentation/my_courses_screen.dart';

class _FakeFirestoreService extends Fake implements FirestoreService {}

/// Repository whose mutations succeed without touching Firebase.
class _FakeCourseEditorRepository extends CourseEditorRepository {
  _FakeCourseEditorRepository() : super(_FakeFirestoreService());

  @override
  Future<void> setStatus(String courseId, bool published) async {}
}

/// Minimal pump helper: ProviderScope + MaterialApp (no router).
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ── Fixture courses ──
final _draftCourse = Course(
  id: 'course-draft-a',
  title: 'Draft Course A',
  description: 'A draft course for testing',
  subject: CourseSubject.math,
  grade: 'Grade 5',
  thumbnailUrl: '',
  lessons: const [],
  status: CourseStatus.draft,
);

final _publishedCourse = Course(
  id: 'course-published-b',
  title: 'Published Course B',
  description: 'A published course for testing',
  subject: CourseSubject.science,
  grade: 'Grade 6',
  thumbnailUrl: '',
  lessons: const [],
  status: CourseStatus.published,
);

void main() {
  group('MyCoursesScreen', () {
    testWidgets('shows both course titles and status chips when 2 courses exist',
        (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(
          const MyCoursesScreen(),
          overrides: [
            teacherCoursesProvider.overrideWith(
              (ref) async => [_draftCourse, _publishedCourse],
            ),
          ],
        ),
      );

      // Settle async data
      await tester.pump();
      await tester.pump();

      expect(find.text('Draft Course A'), findsOneWidget);
      expect(find.text('Published Course B'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
    });

    testWidgets('shows "No courses yet" empty state when course list is empty',
        (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(
          const MyCoursesScreen(),
          overrides: [
            teacherCoursesProvider.overrideWith(
              (ref) async => const <Course>[],
            ),
          ],
        ),
      );

      // Settle async data
      await tester.pump();
      await tester.pump();

      expect(find.text('No courses yet'), findsOneWidget);
    });

    testWidgets('publishing a course refreshes the student library provider',
        (tester) async {
      _setPhoneSize(tester);

      var studentFetches = 0;

      await tester.pumpWidget(
        _wrap(
          const MyCoursesScreen(),
          overrides: [
            teacherCoursesProvider.overrideWith(
              (ref) async => [_draftCourse],
            ),
            coursesProvider.overrideWith((ref) async {
              studentFetches++;
              return const <Course>[];
            }),
            courseEditorRepositoryProvider.overrideWithValue(
              _FakeCourseEditorRepository(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // Keep the student provider alive so invalidation triggers a refetch.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MyCoursesScreen)),
      );
      container.listen(coursesProvider, (_, _) {});
      await tester.pump();
      expect(studentFetches, 1);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(studentFetches, 2);
    });
  });
}
