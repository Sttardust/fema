import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/lesson_video_controller.dart';

void main() {
  test('rejects empty or non-http video urls', () {
    expect(LessonVideoController.isPlayableUrl(null), false);
    expect(LessonVideoController.isPlayableUrl(''), false);
    expect(LessonVideoController.isPlayableUrl('notaurl'), false);
    expect(LessonVideoController.isPlayableUrl('https://firebasestorage.googleapis.com/v0/b/x/o/y.mp4?alt=media'), true);
  });
}
