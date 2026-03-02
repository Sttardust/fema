import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class LibraryRepository {
  // Mock data for now, would fetch from Firestore in a real app
  Future<List<Course>> getCourses() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      Course(
        id: '1',
        title: 'Introduction to Algebra',
        description: 'Master the basics of algebra, including variables, equations, and inequalities.',
        subject: CourseSubject.math,
        grade: 'Grade 8',
        thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=500&q=80',
        lessons: [
          Lesson(id: '11', title: 'What is a Variable?', description: 'Introduction to symbols in math.'),
          Lesson(id: '12', title: 'Solving Simple Equations', description: 'One-step equation solving.'),
          Lesson(id: '13', title: 'Introduction to Functions', description: 'Mapping inputs to outputs.'),
        ],
      ),
      Course(
        id: '2',
        title: 'Ethiopian History: The Aksumite Empire',
        description: 'Explore the rise and fall of one of the greatest ancient African civilizations.',
        subject: CourseSubject.socialStudies,
        grade: 'Grade 9',
        thumbnailUrl: 'https://images.unsplash.com/photo-1523050853064-8521a3089851?w=500&q=80',
        lessons: [
          Lesson(id: '21', title: 'The Origins of Aksum', description: 'Early settlements and trade.'),
          Lesson(id: '22', title: 'The Golden Age of Aksum', description: 'King Ezana and Christianity.'),
        ],
      ),
      Course(
        id: '3',
        title: 'Basic Biology: Cell Structures',
        description: 'Understand the building blocks of life.',
        subject: CourseSubject.science,
        grade: 'Grade 7',
        thumbnailUrl: 'https://images.unsplash.com/photo-1530210124550-912dc1381cb8?w=500&q=80',
        lessons: [
          Lesson(id: '31', title: 'Prokaryotic vs Eukaryotic Cells', description: 'Defining cell types.'),
          Lesson(id: '32', title: 'The Role of Mitochondria', description: 'Powerhouse of the cell.'),
        ],
      ),
    ];
  }
}

final libraryRepositoryProvider = Provider((ref) => LibraryRepository());

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.getCourses();
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);
final selectedLessonProvider = StateProvider<Lesson?>((ref) => null);
