import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/models.dart';

void main() {
  test('lesson carries order, transcript, and document fields', () {
    final l = Lesson(
      id: 'x', title: 't', description: 'd',
      order: 3, transcript: 'hello', documentUrl: 'https://x/y.pdf', documentName: 'y.pdf',
    );
    expect(l.order, 3);
    expect(l.transcript, 'hello');
    expect(l.documentName, 'y.pdf');
    expect(l.copyWith(isCompleted: true).order, 3);
  });

  test('course carries objectives and author', () {
    final c = Course(
      id: 'c', title: 't', description: 'd', subject: CourseSubject.math,
      grade: 'Grade 9', thumbnailUrl: '', lessons: const [],
      learningObjectives: const ['a', 'b'], authorName: 'Ms. Hanna',
    );
    expect(c.learningObjectives, ['a', 'b']);
    expect(c.authorName, 'Ms. Hanna');
  });
}
