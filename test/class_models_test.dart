import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/teacher/domain/class_models.dart';

void main() {
  test('TeacherClass computes derived student stats', () {
    const teacherClass = TeacherClass(
      id: 'math10a',
      name: 'Grade 10 Math - Section A',
      subject: 'Mathematics',
      grade: 'Grade 10',
      students: [
        ClassStudent(
          id: 's1',
          name: 'Kidus',
          grade: 'Grade 10',
          attendanceRate: 100,
        ),
        ClassStudent(
          id: 's2',
          name: 'Mahi',
          grade: 'Grade 10',
          attendanceRate: 80,
        ),
      ],
    );

    expect(teacherClass.studentCount, 2);
    expect(teacherClass.attendanceRate, 90);
  });

  test('ClassStudent parses firestore payload', () {
    final student = ClassStudent.fromMap('student-1', {
      'name': 'Abebe',
      'grade': 'Grade 9',
      'averageScore': 84,
      'attendanceRate': 95,
      'learningGoals': ['Improve algebra'],
    });

    expect(student.id, 'student-1');
    expect(student.averageScore, 84);
    expect(student.attendanceRate, 95);
    expect(student.learningGoals, ['Improve algebra']);
  });
}
