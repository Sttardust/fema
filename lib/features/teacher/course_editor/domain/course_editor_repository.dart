// ignore_for_file: use_null_aware_elements
// Firestore merge-set requires keys to be ABSENT (not null) for partial updates.
// Null-aware element syntax (?'key': value) includes null-valued entries, which
// would overwrite existing fields. The if-null guard pattern is intentional here.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';

class CourseEditorRepository {
  final FirestoreService _service;

  CourseEditorRepository(this._service);

  // ---------------------------------------------------------------------------
  // Static pure helpers
  // ---------------------------------------------------------------------------

  static int nextOrder(Iterable<int> existingOrders) =>
      existingOrders.isEmpty
          ? 0
          : (existingOrders.reduce((a, b) => a > b ? a : b) + 1);

  static Map<String, int> reorderPayload(List<String> lessonIdsInNewOrder) =>
      {for (var i = 0; i < lessonIdsInNewOrder.length; i++) lessonIdsInNewOrder[i]: i};

  static Map<String, dynamic> draftPayload({
    required String title,
    required String description,
    required String subject,
    required String grade,
    required String ownerId,
    String? authorName,
    List<String> learningObjectives = const [],
  }) =>
      {
        'title': title,
        'description': description,
        'subject': subject,
        'grade': grade,
        'ownerId': ownerId,
        'status': 'draft',
        'thumbnailUrl': '',
        'rating': 0,
        'totalStudents': 0,
        'authorName': authorName,
        'learningObjectives': learningObjectives,
      };

  // ---------------------------------------------------------------------------
  // Instance methods
  // ---------------------------------------------------------------------------

  Future<String> createDraft({
    required String title,
    required String description,
    required String subject,
    required String grade,
    required String ownerId,
    String? authorName,
    List<String> learningObjectives = const [],
  }) =>
      _service.saveCourse(draftPayload(
        title: title,
        description: description,
        subject: subject,
        grade: grade,
        ownerId: ownerId,
        authorName: authorName,
        learningObjectives: learningObjectives,
      ));

  Future<void> updateBasics(
    String courseId, {
    String? title,
    String? description,
    String? subject,
    String? grade,
    List<String>? learningObjectives,
  }) =>
      _service.saveCourse({
        'id': courseId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (subject != null) 'subject': subject,
        if (grade != null) 'grade': grade,
        if (learningObjectives != null) 'learningObjectives': learningObjectives,
      });

  Future<void> saveLesson(
    String courseId, {
    String? lessonId,
    required String title,
    required String description,
    required int durationMinutes,
    required int order,
    String? videoUrl,
    String? transcript,
    String? contentHtml,
    String? documentUrl,
    String? documentName,
  }) =>
      _service.saveLesson(courseId, {
        if (lessonId != null) 'id': lessonId,
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'order': order,
        'videoUrl': videoUrl,
        'transcript': transcript,
        'contentHtml': contentHtml,
        'documentUrl': documentUrl,
        'documentName': documentName,
      });

  Future<void> applyReorder(String courseId, Map<String, int> orders) async {
    for (final e in orders.entries) {
      await _service.saveLesson(courseId, {'id': e.key, 'order': e.value});
    }
  }

  Future<void> deleteLesson(String courseId, String lessonId) =>
      _service.deleteLesson(courseId, lessonId);

  Future<void> setStatus(String courseId, bool published) =>
      _service.updateCourseStatus(courseId, published ? 'published' : 'draft');

  Future<void> deleteCourse(String courseId) => _service.deleteCourse(courseId);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final courseEditorRepositoryProvider = Provider<CourseEditorRepository>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return CourseEditorRepository(service);
});

final courseEditorLessonsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) async {
  final service = ref.watch(firestoreServiceProvider);
  final raw = await service.getLessons(courseId);
  final entries = raw.asMap().entries.toList()
    ..sort((a, b) {
      final ao = (a.value['order'] as int?) ?? 0;
      final bo = (b.value['order'] as int?) ?? 0;
      final byOrder = ao.compareTo(bo);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
  return entries.map((e) => e.value).toList();
});
