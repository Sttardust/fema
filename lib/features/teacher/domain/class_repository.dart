import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_repository.dart';
import 'class_models.dart';

class TeacherClassRepository {
  TeacherClassRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<TeacherClass>> watchTeacherClasses(String teacherId) {
    return _firestoreService.watchTeacherClasses(teacherId).asyncMap((classData) async {
      final classes = <TeacherClass>[];

      for (final data in classData) {
        final studentsData = await _firestoreService.getClassStudents(data['id'] as String);
        final students = studentsData
            .map((student) => ClassStudent.fromMap(
                  student['id'] as String,
                  student,
                ))
            .toList();

        classes.add(
          TeacherClass.fromMap(
            data['id'] as String,
            data,
            students: students,
          ),
        );
      }

      return classes;
    });
  }

  Future<void> saveAttendance(String classId, Map<String, bool> attendance) {
    return _firestoreService.saveAttendance(classId, DateTime.now(), attendance);
  }
}

final teacherClassRepositoryProvider = Provider<TeacherClassRepository>((ref) {
  return TeacherClassRepository(ref.watch(firestoreServiceProvider));
});

final teacherClassesProvider = StreamProvider<List<TeacherClass>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    return Stream.value(const []);
  }

  return ref.watch(teacherClassRepositoryProvider).watchTeacherClasses(user.uid);
});
