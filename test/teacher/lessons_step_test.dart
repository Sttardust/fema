// Pure widget test for LessonsStep and showLessonSheet — no Firebase required.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fema/features/teacher/course_editor/domain/course_editor_repository.dart';
import 'package:fema/features/teacher/course_editor/presentation/lessons_step.dart';

// ---------------------------------------------------------------------------
// Fixture data
// ---------------------------------------------------------------------------

const _videoLesson = <String, dynamic>{
  'id': 'l1',
  'title': 'Introduction to Fractions',
  'description': 'Basics of fractions',
  'durationMinutes': 12,
  'order': 0,
  'videoUrl': 'https://storage.example.com/video.mp4',
  'transcript': 'Welcome to fractions…',
  'contentHtml': null,
  'documentUrl': 'https://storage.example.com/worksheet.pdf',
  'documentName': 'worksheet.pdf',
};

const _textLesson = <String, dynamic>{
  'id': 'l2',
  'title': 'Reading Comprehension',
  'description': 'How to read effectively',
  'durationMinutes': 20,
  'order': 1,
  'videoUrl': null,
  'transcript': null,
  'contentHtml': '<p>Read carefully and take notes.</p>',
  'documentUrl': null,
  'documentName': null,
};

const _emptyLesson = <String, dynamic>{
  'id': 'l3',
  'title': 'Coming Soon',
  'description': '',
  'durationMinutes': 0,
  'order': 2,
  'videoUrl': null,
  'transcript': null,
  'contentHtml': null,
  'documentUrl': null,
  'documentName': null,
};

final _fixtures = [_videoLesson, _textLesson, _emptyLesson];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<Override> _lessonsOverride(List<Map<String, dynamic>> data) => [
      courseEditorLessonsProvider.overrideWith(
        (ref, arg) async => data,
      ),
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LessonsStep', () {
    testWidgets('renders 3 lesson titles, correct status lines, and attach icon',
        (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(
          LessonsStep(courseId: 'c1', onContinue: () {}),
          overrides: _lessonsOverride(_fixtures),
        ),
      );

      // Wait for the FutureProvider to resolve.
      await tester.pump();
      await tester.pump();

      // All three lesson titles render.
      expect(
          find.text('Introduction to Fractions', skipOffstage: false),
          findsOneWidget);
      expect(
          find.text('Reading Comprehension', skipOffstage: false),
          findsOneWidget);
      expect(find.text('Coming Soon', skipOffstage: false), findsOneWidget);

      // Status lines.
      expect(
          find.text('Video · 12 min', skipOffstage: false), findsOneWidget);
      expect(find.text('Text lesson', skipOffstage: false), findsOneWidget);
      expect(find.text('No content yet', skipOffstage: false), findsOneWidget);

      // attach_file icon — only the video lesson has a documentUrl.
      expect(
          find.byIcon(Icons.attach_file, skipOffstage: false), findsOneWidget);

      // Continue button should be enabled (lessons.isNotEmpty).
      final continueBtn = find.text('Continue', skipOffstage: false);
      expect(continueBtn, findsOneWidget);

      // Verify the Continue PillButton's InkWell has a non-null onTap (enabled).
      final inkwell = find.ancestor(
        of: continueBtn,
        matching: find.byType(InkWell),
      );
      final inkwellWidget = tester.widget<InkWell>(inkwell.last);
      expect(inkwellWidget.onTap, isNotNull);
    });

    testWidgets('empty lesson list shows EmptyStateView and disabled Continue',
        (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(
          LessonsStep(courseId: 'c1', onContinue: () {}),
          overrides: _lessonsOverride([]),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(
          find.text(
            'No lessons yet — add your first lesson',
            skipOffstage: false,
          ),
          findsOneWidget);

      // Continue should be disabled (onTap == null).
      final continueBtn = find.text('Continue', skipOffstage: false);
      expect(continueBtn, findsOneWidget);

      final inkwell = find.ancestor(
        of: continueBtn,
        matching: find.byType(InkWell),
      );
      final inkwellWidget = tester.widget<InkWell>(inkwell.last);
      expect(inkwellWidget.onTap, isNull);
    });

    testWidgets(
        'tapping Add lesson opens sheet with title and video upload zone; '
        'tapping Text segment shows Lesson content field', (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(
          LessonsStep(courseId: 'c1', onContinue: () {}),
          overrides: _lessonsOverride(_fixtures),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Tap the "Add lesson" button.
      await tester.tap(find.text('Add lesson'));
      await tester.pumpAndSettle();

      // Sheet title renders.
      expect(find.text('Add lesson', skipOffstage: false), findsWidgets);

      // Video upload zone is visible (idle state shows 'Upload video').
      expect(find.text('Upload video', skipOffstage: false), findsOneWidget);

      // Switch to Text segment.
      await tester.tap(find.text('Text', skipOffstage: false));
      await tester.pumpAndSettle();

      // 'Lesson content' label appears.
      expect(find.text('Lesson content', skipOffstage: false), findsOneWidget);

      // Upload video zone disappears.
      expect(find.text('Upload video', skipOffstage: false), findsNothing);
    });

    testWidgets('lesson sheet accepts a pasted video link', (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(
          LessonsStep(courseId: 'c1', onContinue: () {}),
          overrides: _lessonsOverride(_fixtures),
        ),
      );

      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Add lesson'));
      await tester.pumpAndSettle();

      // Idle zone offers the link alternative.
      await tester.tap(find.text('Paste video link instead', skipOffstage: false));
      await tester.pumpAndSettle();

      // Dialog: confirm is disabled until a valid http(s) URL is entered.
      final addLink = find.text('Add link');
      expect(addLink, findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('video-link-field')), 'not a url');
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(
        find.ancestor(of: addLink, matching: find.byType(TextButton)),
      ).onPressed, isNull);

      await tester.enterText(
          find.byKey(const Key('video-link-field')),
          'https://cdn.example.com/lesson.mp4');
      await tester.pumpAndSettle();
      await tester.tap(addLink);
      await tester.pumpAndSettle();

      // Zone flips to the linked/done state.
      expect(find.text('Video linked', skipOffstage: false), findsOneWidget);
      expect(find.text('Upload video', skipOffstage: false), findsNothing);
    });
  });
}
