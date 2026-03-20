import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/models.dart';

void main() {
  test('Course can represent teacher-owned draft content', () {
    final course = Course(
      id: 'course-1',
      title: 'Physics Foundations',
      description: 'Introductory course',
      subject: CourseSubject.science,
      grade: 'Grade 10',
      thumbnailUrl: '',
      lessons: const [],
      ownerId: 'teacher-123',
      status: CourseStatus.draft,
    );

    expect(course.ownerId, 'teacher-123');
    expect(course.status, CourseStatus.draft);
    expect(course.progress, 0);
  });
}
