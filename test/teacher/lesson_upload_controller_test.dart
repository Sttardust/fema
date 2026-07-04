import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/teacher/course_editor/domain/lesson_upload_controller.dart';

void main() {
  test('storage paths are uid-scoped and include uploadId', () {
    expect(
      LessonUploadController.videoPath(uid: 'u1', courseId: 'c1', lessonId: 'l1', uploadId: 'v1'),
      'lesson-videos/u1/c1/l1-v1.mp4',
    );
    expect(
      LessonUploadController.documentPath(
          uid: 'u1', courseId: 'c1', lessonId: 'l1', uploadId: 'v1', fileName: 'w s.pdf'),
      'lesson-docs/u1/c1/l1-v1-w_s.pdf',
    );
  });

  test('document extension gate', () {
    expect(LessonUploadController.isAllowedDocument('a.pdf'), true);
    expect(LessonUploadController.isAllowedDocument('a.docx'), true);
    expect(LessonUploadController.isAllowedDocument('a.doc'), true);
    expect(LessonUploadController.isAllowedDocument('a.exe'), false);
  });
}
