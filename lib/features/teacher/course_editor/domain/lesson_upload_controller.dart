import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Storage upload orchestration for lesson media. Pure path/validation
/// helpers are static (unit-tested); upload methods return the raw
/// [UploadTask] so the UI drives progress and cancellation.
class LessonUploadController {
  static String videoPath({
    required String uid,
    required String courseId,
    required String lessonId,
    required String uploadId,
  }) =>
      'lesson-videos/$uid/$courseId/$lessonId-$uploadId.mp4';

  static String documentPath({
    required String uid,
    required String courseId,
    required String lessonId,
    required String uploadId,
    required String fileName,
  }) =>
      'lesson-docs/$uid/$courseId/$lessonId-$uploadId-${sanitizeFileName(fileName)}';

  static String sanitizeFileName(String name) => name.replaceAll(RegExp(r'\s+'), '_');

  static bool isAllowedDocument(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx');
  }

  static String mimeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/msword';
  }

  UploadTask startVideoUpload({
    required String uid,
    required String courseId,
    required String lessonId,
    required String uploadId,
    required File file,
  }) =>
      FirebaseStorage.instance
          .ref(videoPath(uid: uid, courseId: courseId, lessonId: lessonId, uploadId: uploadId))
          .putFile(file, SettableMetadata(contentType: 'video/mp4'));

  UploadTask startDocumentUpload({
    required String uid,
    required String courseId,
    required String lessonId,
    required String uploadId,
    required String fileName,
    required File file,
  }) =>
      FirebaseStorage.instance
          .ref(documentPath(
              uid: uid,
              courseId: courseId,
              lessonId: lessonId,
              uploadId: uploadId,
              fileName: fileName))
          .putFile(file, SettableMetadata(contentType: mimeFor(fileName)));

  /// True only for URLs [FirebaseStorage.refFromURL] can resolve — gs:// or
  /// Firebase Storage download URLs. Legacy seeds may point at external hosts.
  static bool isStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'gs') return uri.host.isNotEmpty;
    return uri.scheme == 'https' && uri.host == 'firebasestorage.googleapis.com';
  }

  /// Best-effort delete of the object a download URL points at. Missing
  /// objects and non-Storage URLs (legacy/external seeds) are fine — a
  /// cleanup failure must never abort the lesson/course delete around it.
  static Future<void> deleteByUrl(String downloadUrl) async {
    if (!isStorageUrl(downloadUrl)) return;
    try {
      await FirebaseStorage.instance.refFromURL(downloadUrl).delete();
    } catch (_) {
      // object-not-found or permission on legacy paths — nothing to clean up
    }
  }
}
