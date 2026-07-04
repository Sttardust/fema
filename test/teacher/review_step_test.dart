// Pure widget test for ReviewStep — no Firebase required.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fema/features/library/domain/library_provider.dart';
import 'package:fema/features/library/domain/models.dart';
import 'package:fema/features/teacher/course_editor/domain/course_editor_repository.dart';
import 'package:fema/features/teacher/course_editor/presentation/review_step.dart';

// ---------------------------------------------------------------------------
// Fixture data
// ---------------------------------------------------------------------------

final _course = Course(
  id: 'c1',
  title: 'Chem 101',
  description: 'Introduction to chemistry concepts.',
  subject: CourseSubject.science,
  grade: 'Grade 10',
  thumbnailUrl: '',
  lessons: const [],
  status: CourseStatus.draft,
);

const _videoLessonWithTranscript = <String, dynamic>{
  'id': 'l1',
  'title': 'Atoms and Molecules',
  'description': 'Basics',
  'durationMinutes': 15,
  'order': 0,
  'videoUrl': 'https://storage.example.com/video.mp4',
  'transcript': 'Welcome to chemistry…',
  'contentHtml': null,
  'documentUrl': null,
  'documentName': null,
};

const _textLesson = <String, dynamic>{
  'id': 'l2',
  'title': 'Reading: Periodic Table',
  'description': 'Study the periodic table.',
  'durationMinutes': 20,
  'order': 1,
  'videoUrl': null,
  'transcript': null,
  'contentHtml': '<p>Read and annotate.</p>',
  'documentUrl': null,
  'documentName': null,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap({
  required List<Map<String, dynamic>> lessons,
}) {
  return ProviderScope(
    overrides: [
      // Provide a single draft course fixture.
      teacherCoursesProvider.overrideWith((_) async => [_course]),
      // Provide lessons fixture.
      courseEditorLessonsProvider.overrideWith(
        (ref, arg) async => lessons,
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: ReviewStep(courseId: 'c1'),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReviewStep', () {
    testWidgets(
        'Test A: 2 lessons — shows "2 lessons added", enabled Publish, '
        'Save as draft, and Delete course', (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(
        _wrap(lessons: [_videoLessonWithTranscript, _textLesson]),
      );

      // Resolve async providers.
      await tester.pump();
      await tester.pump();

      // Checklist: 2 lessons added
      expect(
          find.text('2 lessons added', skipOffstage: false), findsOneWidget);

      // Publish course PillButton is present
      expect(
          find.text('Publish course', skipOffstage: false), findsOneWidget);

      // Publish button should be enabled (lessons.isNotEmpty && !_busy).
      final publishBtn = find.text('Publish course', skipOffstage: false);
      final inkwell = find.ancestor(
        of: publishBtn,
        matching: find.byType(InkWell),
      );
      final inkwellWidget = tester.widget<InkWell>(inkwell.last);
      expect(inkwellWidget.onTap, isNotNull);

      // Save as draft & exit row is present
      expect(
          find.text('Save as draft & exit', skipOffstage: false),
          findsOneWidget);

      // Delete course row is present
      expect(find.text('Delete course', skipOffstage: false), findsOneWidget);
    });

    testWidgets(
        'Test B: empty lessons — shows "Add at least one lesson" '
        'and Publish button is disabled', (tester) async {
      _setPhoneSize(tester);

      await tester.pumpWidget(_wrap(lessons: []));

      // Resolve async providers.
      await tester.pump();
      await tester.pump();

      // Checklist warning row
      expect(
          find.text('Add at least one lesson', skipOffstage: false),
          findsOneWidget);

      // Publish course PillButton is present
      expect(
          find.text('Publish course', skipOffstage: false), findsOneWidget);

      // Publish button should be disabled (onTap == null).
      final publishBtn = find.text('Publish course', skipOffstage: false);
      final inkwell = find.ancestor(
        of: publishBtn,
        matching: find.byType(InkWell),
      );
      final inkwellWidget = tester.widget<InkWell>(inkwell.last);
      expect(inkwellWidget.onTap, isNull);
    });
  });
}
