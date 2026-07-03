import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/home/presentation/home_screen.dart';
import 'package:fema/features/library/domain/library_provider.dart';
import 'package:fema/features/library/domain/models.dart';
import 'package:fema/features/auth/domain/auth_repository.dart';
import 'package:fema/features/profile/domain/user_profile_repository.dart';
import 'package:fema/features/onboarding/domain/onboarding_provider.dart';

/// Minimal pump helper: ProviderScope + MaterialApp.
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

/// Set an iPad-sized viewport (768 × 1024 logical, 1x) so the UI has plenty
/// of horizontal space and the "Popular courses  /  See all" row never
/// overflows during tests.
void _setTabletSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(768, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ---------------------------------------------------------------------------
// Fixture courses
// ---------------------------------------------------------------------------
final _mathCourse = Course(
  id: 'c1',
  title: 'Algebra Basics',
  description: 'Introduction to algebra',
  subject: CourseSubject.math,
  grade: 'Grade 7',
  thumbnailUrl: '',
  lessons: [
    Lesson(
      id: 'l1',
      title: 'Variables',
      description: 'What is a variable?',
      videoUrl: null,
      durationMinutes: 15,
    ),
  ],
);

final _englishCourse = Course(
  id: 'c2',
  title: 'Grammar Essentials',
  description: 'Core grammar concepts',
  subject: CourseSubject.english,
  grade: 'Grade 6',
  thumbnailUrl: '',
  lessons: [
    Lesson(
      id: 'l2',
      title: 'Nouns',
      description: 'What is a noun?',
      videoUrl: null,
      durationMinutes: 12,
    ),
  ],
);

// Guest-mode overrides: null auth state, null profile, fixture courses.
List<Override> _guestOverrides(List<Course> courses) => [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
      coursesProvider.overrideWith((ref) async => courses),
      homeTabProvider.overrideWith((ref) => 0),
    ];

void main() {
  group('HomeScreen — guest mode', () {
    testWidgets('shows guest greeting "Hi there" and guest banner visible',
        (tester) async {
      _setTabletSize(tester);
      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        overrides: _guestOverrides([_mathCourse, _englishCourse]),
      ));
      // First pump lets the widget build; second settles the async FutureProvider.
      await tester.pump();
      await tester.pump();

      // Guest greeting rendered in the header column
      expect(find.textContaining('Hi there'), findsOneWidget);

      // Guest banner contains the "browsing as a guest" message
      expect(
        find.textContaining('browsing as a guest'),
        findsOneWidget,
      );
    });

    testWidgets('both course cards render in the grid', (tester) async {
      _setTabletSize(tester);
      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        overrides: _guestOverrides([_mathCourse, _englishCourse]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Algebra Basics'), findsOneWidget);
      expect(find.text('Grammar Essentials'), findsOneWidget);
    });

    testWidgets('tapping Math chip filters to Algebra Basics only',
        (tester) async {
      _setTabletSize(tester);
      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        overrides: _guestOverrides([_mathCourse, _englishCourse]),
      ));
      await tester.pump();
      await tester.pump();

      // Verify both visible before filtering
      expect(find.text('Algebra Basics'), findsOneWidget);
      expect(find.text('Grammar Essentials'), findsOneWidget);

      // Tap the "Math" subject chip
      await tester.tap(find.text('Math'));
      await tester.pump();

      // Only the math course should remain
      expect(find.text('Algebra Basics'), findsOneWidget);
      expect(find.text('Grammar Essentials'), findsNothing);
    });

    testWidgets('empty course list renders "No courses yet"', (tester) async {
      _setTabletSize(tester);
      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        overrides: _guestOverrides([]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('No courses yet'), findsOneWidget);
    });
  });
}
