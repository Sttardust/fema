import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/library_provider.dart';
import 'package:fema/features/library/domain/models.dart';
import 'package:fema/features/library/presentation/video_player_screen.dart';

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

void main() {
  group('VideoPlayerScreen', () {
    testWidgets('shows "No lesson selected" when no lesson is set',
        (tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedLessonProvider.overrideWith((ref) => null),
          selectedCourseProvider.overrideWith((ref) => null),
        ],
      ));
      await tester.pump();
      expect(find.text('No lesson selected'), findsOneWidget);
    });

    testWidgets(
        'shows "Video unavailable" for a lesson with null videoUrl',
        (tester) async {
      _setPhoneSize(tester);
      final course = Course(
        id: 'c1',
        title: 'Test Course',
        description: 'desc',
        subject: CourseSubject.math,
        grade: 'Grade 5',
        thumbnailUrl: '',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Intro Lesson',
            description: 'desc',
            videoUrl: null,
            durationMinutes: 10,
          ),
        ],
      );
      final lesson = course.lessons.first;

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));

      // Allow initState / didChangeDependencies to run.
      await tester.pump();
      // Allow any async microtasks to settle.
      await tester.pump();

      expect(find.text('Video unavailable'), findsOneWidget);
    });

    testWidgets('renders lesson title and course info in heading',
        (tester) async {
      _setPhoneSize(tester);
      final course = Course(
        id: 'c2',
        title: 'Science 101',
        description: 'desc',
        subject: CourseSubject.science,
        grade: 'Grade 6',
        thumbnailUrl: '',
        lessons: [
          Lesson(
            id: 'l2',
            title: 'Forces and Motion',
            description: 'desc',
            videoUrl: null,
            durationMinutes: 20,
          ),
        ],
      );
      final lesson = course.lessons.first;

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Forces and Motion'), findsOneWidget);
      // Course subtitle contains course title
      expect(find.textContaining('Science 101'), findsWidgets);
      // Chip tabs are rendered
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
    });

    testWidgets('shows "Lesson 1 of 1" nav label', (tester) async {
      _setPhoneSize(tester);
      final course = Course(
        id: 'c3',
        title: 'Math Basics',
        description: 'desc',
        subject: CourseSubject.math,
        grade: 'Grade 4',
        thumbnailUrl: '',
        lessons: [
          Lesson(
            id: 'l3',
            title: 'Addition',
            description: 'desc',
            videoUrl: null,
            durationMinutes: 5,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => course.lessons.first),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Lesson 1 of 1'), findsOneWidget);
    });

    testWidgets('Previous and Next buttons are rendered for single lesson',
        (tester) async {
      _setPhoneSize(tester);
      final lesson = Lesson(
        id: 'l4',
        title: 'Lesson One',
        description: 'desc',
        videoUrl: null,
        durationMinutes: 10,
      );
      final course = Course(
        id: 'c4',
        title: 'Course',
        description: 'desc',
        subject: CourseSubject.math,
        grade: 'Grade 5',
        thumbnailUrl: '',
        lessons: [lesson],
      );

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));
      await tester.pump();
      await tester.pump();

      // Both navigation buttons are rendered (disabled for a single-lesson course).
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    // ── Task 9 tests ──────────────────────────────────────────────────────────

    testWidgets(
        'text lesson renders body text and does NOT show "Video unavailable"',
        (tester) async {
      _setPhoneSize(tester);
      const bodyText = 'A mixture is a combination of two or more substances.';
      final lesson = Lesson(
        id: 'lt1',
        title: 'What is a Mixture?',
        description: 'desc',
        videoUrl: null,
        contentHtml: bodyText,
        durationMinutes: 8,
      );
      final course = Course(
        id: 'ct1',
        title: 'Chemistry Basics',
        description: 'desc',
        subject: CourseSubject.science,
        grade: 'Grade 7',
        thumbnailUrl: '',
        lessons: [lesson],
      );

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text(bodyText), findsOneWidget);
      expect(find.text('Video unavailable'), findsNothing);
    });

    testWidgets('transcript tab shows transcript text when present',
        (tester) async {
      _setPhoneSize(tester);
      const transcriptText =
          'Today we cover the water cycle in detail.';
      final lesson = Lesson(
        id: 'lt2',
        title: 'The Water Cycle',
        description: 'desc',
        videoUrl: 'https://example.com/video.mp4',
        transcript: transcriptText,
        durationMinutes: 15,
      );
      final course = Course(
        id: 'ct2',
        title: 'Earth Science',
        description: 'desc',
        subject: CourseSubject.science,
        grade: 'Grade 6',
        thumbnailUrl: '',
        lessons: [lesson],
      );

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));
      await tester.pump();
      await tester.pump();

      // Tap the 'Transcript' chip to switch tabs.
      await tester.tap(find.text('Transcript'));
      await tester.pumpAndSettle();

      expect(find.text(transcriptText), findsOneWidget);
    });

    testWidgets('transcript tab shows empty state when transcript is null',
        (tester) async {
      _setPhoneSize(tester);
      final lesson = Lesson(
        id: 'lt3',
        title: 'Intro',
        description: 'desc',
        videoUrl: null,
        transcript: null,
        durationMinutes: 5,
      );
      final course = Course(
        id: 'ct3',
        title: 'Math',
        description: 'desc',
        subject: CourseSubject.math,
        grade: 'Grade 5',
        thumbnailUrl: '',
        lessons: [lesson],
      );

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Transcript'));
      await tester.pumpAndSettle();

      expect(find.text('No transcript yet'), findsOneWidget);
    });

    testWidgets('worksheet row shows documentName when documentUrl is set',
        (tester) async {
      _setPhoneSize(tester);
      final lesson = Lesson(
        id: 'lw1',
        title: 'Forces Lab',
        description: 'desc',
        videoUrl: null,
        documentUrl: 'https://example.com/worksheet.pdf',
        documentName: 'worksheet.pdf',
        durationMinutes: 12,
      );
      final course = Course(
        id: 'cw1',
        title: 'Physics',
        description: 'desc',
        subject: CourseSubject.science,
        grade: 'Grade 8',
        thumbnailUrl: '',
        lessons: [lesson],
      );

      await tester.pumpWidget(_wrap(
        const VideoPlayerScreen(),
        overrides: [
          selectedCourseProvider.overrideWith((ref) => course),
          selectedLessonProvider.overrideWith((ref) => lesson),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('worksheet.pdf'), findsOneWidget);
    });
  });
}
