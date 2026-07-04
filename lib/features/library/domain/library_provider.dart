import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_repository.dart';
import 'models.dart';

class CourseRepository {
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;
  CourseRepository(this._firestoreService, this._authRepository);

  Future<List<Course>> getCourses({
    String? ownerId,
    bool publishedOnly = false,
  }) async {
    try {
      final courseData = await _firestoreService.getCourses(
        ownerId: ownerId,
        status: publishedOnly ? CourseStatus.published.name : null,
      );
      List<Course> courses = [];
      
      for (var data in courseData) {
        final lessonsData = await _firestoreService.getLessons(data['id']);
        final builtLessons = lessonsData.map((l) => Lesson(
          id: l['id'],
          title: l['title'] ?? '',
          description: l['description'] ?? '',
          videoUrl: l['videoUrl'],
          contentHtml: l['contentHtml'],
          durationMinutes: l['durationMinutes'] ?? 15,
          isCompleted: false, // In a real app, track per user
          order: l['order'] ?? 0,
          transcript: l['transcript'] as String?,
          documentUrl: l['documentUrl'] as String?,
          documentName: l['documentName'] as String?,
        )).toList();

        // Sort by (order, fetchIndex) so ordered lessons are sequenced correctly
        // while legacy lessons (all order == 0) preserve fetch order.
        final entries = builtLessons.asMap().entries.toList()
          ..sort((a, b) {
            final byOrder = a.value.order.compareTo(b.value.order);
            return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
          });
        final lessons = entries.map((e) => e.value).toList();

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
          ownerId: data['ownerId'] as String?,
          status: _parseStatus(data['status'] as String?),
          learningObjectives: List<String>.from(data['learningObjectives'] ?? const []),
          authorName: data['authorName'] as String?,
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
      'ownerId': course.ownerId ?? _authRepository.currentUser?.uid,
      'title': course.title,
      'description': course.description,
      'subject': course.subject.name,
      'grade': course.grade,
      'thumbnailUrl': course.thumbnailUrl,
      'status': isDraft ? CourseStatus.draft.name : CourseStatus.published.name,
      'rating': course.rating,
      'totalStudents': course.totalStudents,
      'learningObjectives': course.learningObjectives,
      'authorName': course.authorName,
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
        'order': lesson.order,
        'transcript': lesson.transcript,
        'documentUrl': lesson.documentUrl,
        'documentName': lesson.documentName,
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

  CourseStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return CourseStatus.draft;
      case 'published':
      default:
        return CourseStatus.published;
    }
  }
}

final courseRepositoryProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return CourseRepository(firestoreService, authRepository);
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourses(publishedOnly: true);
});

final teacherCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    return const <Course>[];
  }

  return repository.getCourses(ownerId: user.uid);
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);
final selectedLessonProvider = StateProvider<Lesson?>((ref) => null);
