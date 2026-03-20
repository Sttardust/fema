import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<Map<String, dynamic>?> watchUserProfileData(String uid) {
    return getUserProfile(uid).map((snapshot) => snapshot.data());
  }

  Stream<List<Map<String, dynamic>>> watchTeacherClasses(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> getClassStudents(String classId) async {
    final snapshot = await _db.collection('classes').doc(classId).collection('students').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getCourses({
    String? ownerId,
    String? status,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('courses');
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getLessons(String courseId) async {
    final snapshot = await _db.collection('courses').doc(courseId).collection('lessons').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<String> saveCourse(Map<String, dynamic> data) async {
    final docRef = data['id'] != null 
        ? _db.collection('courses').doc(data['id'])
        : _db.collection('courses').doc();
    
    await docRef.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    return docRef.id;
  }

  Future<void> updateCourseStatus(String courseId, String status) async {
    await _db.collection('courses').doc(courseId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveLesson(String courseId, Map<String, dynamic> data) async {
    final docRef = data['id'] != null
        ? _db.collection('courses').doc(courseId).collection('lessons').doc(data['id'])
        : _db.collection('courses').doc(courseId).collection('lessons').doc();
    
    await docRef.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAttendance(String classId, DateTime date, Map<String, bool> attendance) async {
    final dateStr = "${date.year}-${date.month}-${date.day}";
    await _db.collection('classes').doc(classId).collection('attendance').doc(dateStr).set({
      'date': Timestamp.fromDate(date),
      'records': attendance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChildUsername(String uid, int childIndex, String username) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final children = List<Map<String, dynamic>>.from(data['children'] ?? []);
    
    if (childIndex < children.length) {
      children[childIndex] = {
        ...children[childIndex],
        'username': username,
      };
      
      await _db.collection('users').doc(uid).update({
        'children': children,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firestoreProvider));
});
