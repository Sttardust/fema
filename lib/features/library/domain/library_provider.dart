import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class LibraryRepository {
  final FirestoreService _firestoreService;
  LibraryRepository(this._firestoreService);

  Future<List<Course>> getCourses() async {
    try {
      final courseData = await _firestoreService.getCourses();
      List<Course> courses = [];
      
      for (var data in courseData) {
        final lessonsData = await _firestoreService.getLessons(data['id']);
        final lessons = lessonsData.map((l) => Lesson(
          id: l['id'],
          title: l['title'] ?? '',
          description: l['description'] ?? '',
          videoUrl: l['videoUrl'],
          contentHtml: l['contentHtml'],
          durationMinutes: l['durationMinutes'] ?? 15,
          isCompleted: false, // In a real app, track per user
        )).toList();

        courses.add(Course(
          id: data['id'],
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          subject: _parseSubject(data['subject']),
          grade: data['grade'] ?? 'General',
          thumbnailUrl: data['thumbnailUrl'] ?? '',
          lessons: lessons,
          rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
          totalStudents: data['totalStudents'] ?? 0,
        ));
      }
      return courses;
    } catch (e) {
      return []; // Fallback/Error handling
    }
  }

  CourseSubject _parseSubject(String? subject) {
    switch (subject?.toLowerCase()) {
      case 'math': return CourseSubject.math;
      case 'science': return CourseSubject.science;
      case 'english': return CourseSubject.english;
      case 'socialstudies': return CourseSubject.socialStudies;
      case 'amharic': return CourseSubject.amharic;
      default: return CourseSubject.other;
    }
  }
}

final libraryRepositoryProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return LibraryRepository(firestoreService);
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.getCourses();
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);
final selectedLessonProvider = StateProvider<Lesson?>((ref) => null);
