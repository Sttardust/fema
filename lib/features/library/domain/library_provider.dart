import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import 'models.dart';

class CourseRepository {
  final FirestoreService _firestoreService;
  CourseRepository(this._firestoreService);

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

  Future<String> saveCourse(Course course, {bool isDraft = true}) async {
    final data = {
      if (course.id.isNotEmpty) 'id': course.id,
      'title': course.title,
      'description': course.description,
      'subject': course.subject.name,
      'grade': course.grade,
      'thumbnailUrl': course.thumbnailUrl,
      'status': isDraft ? 'draft' : 'published',
      'rating': course.rating,
      'totalStudents': course.totalStudents,
    };
    
    final courseId = await _firestoreService.saveCourse(data);
    
    for (var lesson in course.lessons) {
      await _firestoreService.saveLesson(courseId, {
        if (lesson.id.isNotEmpty) 'id': lesson.id,
        'title': lesson.title,
        'description': lesson.description,
        'videoUrl': lesson.videoUrl,
        'contentHtml': lesson.contentHtml,
        'durationMinutes': lesson.durationMinutes,
      });
    }
    
    return courseId;
  }

  CourseSubject _parseSubject(String? subject) {
    switch (subject?.toLowerCase()) {
      case 'math':
      case 'mathematics': return CourseSubject.math;
      case 'science': return CourseSubject.science;
      case 'english': return CourseSubject.english;
      case 'socialstudies': return CourseSubject.socialStudies;
      case 'amharic': return CourseSubject.amharic;
      default: return CourseSubject.other;
    }
  }
}

final courseRepositoryProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CourseRepository(firestoreService);
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourses();
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);
final selectedLessonProvider = StateProvider<Lesson?>((ref) => null);
