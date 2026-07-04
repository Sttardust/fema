import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/teacher/course_editor/domain/course_editor_repository.dart';

void main() {
  test('nextOrder appends after the max existing order', () {
    expect(CourseEditorRepository.nextOrder([0, 1, 2]), 3);
    expect(CourseEditorRepository.nextOrder([]), 0);
    expect(CourseEditorRepository.nextOrder([5, 2]), 6);
  });

  test('reorderPayload renumbers 0..n-1 in the new sequence', () {
    expect(CourseEditorRepository.reorderPayload(['b', 'a', 'c']),
        {'b': 0, 'a': 1, 'c': 2});
  });

  test('draftPayload shapes the create document', () {
    final p = CourseEditorRepository.draftPayload(
      title: 'T', description: 'D', subject: 'science', grade: 'Grade 10',
      ownerId: 'uid1', authorName: 'Ms. H', learningObjectives: ['x'],
    );
    expect(p['status'], 'draft');
    expect(p['rating'], 0);
    expect(p['totalStudents'], 0);
    expect(p['thumbnailUrl'], '');
    expect(p['authorName'], 'Ms. H');
    expect(p['learningObjectives'], ['x']);
  });
}
