import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/library_provider.dart';
import 'package:fema/features/library/domain/models.dart';
import 'package:fema/features/library/presentation/course_details_screen.dart';
import 'package:fema/features/library/presentation/library_screen.dart';

/// Minimal ProviderScope + MaterialApp wrapper.
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

/// Set the tester surface to a phone-like size (390 × 844 logical px) so
/// the full-screen vertical layout doesn't overflow in tests.
void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Course _course() => Course(
      id: 'c1',
      title: 'Algebra Basics',
      description: 'desc',
      subject: CourseSubject.math,
      grade: 'Grade 9',
      thumbnailUrl: '',
      lessons: const [],
    );

void main() {
  group('Grade label rendering', () {
    testWidgets('library card shows the stored grade without a double prefix',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const LibraryScreen(),
        overrides: [
          coursesProvider.overrideWith((ref) async => [_course()]),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Grade Grade'), findsNothing);
      expect(find.textContaining('Grade 9'), findsOneWidget);
    });

    testWidgets(
        'course details meta chip shows the stored grade without a double prefix',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const CourseDetailsScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => _course()),
        ],
      ));
      await tester.pump();
      expect(find.textContaining('Grade Grade'), findsNothing);
      expect(find.text('Grade 9'), findsOneWidget);
    });
  });
}
