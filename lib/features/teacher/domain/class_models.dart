class ClassStudent {
  final String id;
  final String name;
  final String grade;
  final double averageScore;
  final double attendanceRate;
  final List<String> learningGoals;

  const ClassStudent({
    required this.id,
    required this.name,
    required this.grade,
    this.averageScore = 0,
    this.attendanceRate = 0,
    this.learningGoals = const [],
  });

  factory ClassStudent.fromMap(String id, Map<String, dynamic> data) {
    return ClassStudent(
      id: id,
      name: data['name'] as String? ?? 'Unnamed Student',
      grade: data['grade'] as String? ?? 'Unknown Grade',
      averageScore: (data['averageScore'] as num?)?.toDouble() ?? 0,
      attendanceRate: (data['attendanceRate'] as num?)?.toDouble() ?? 0,
      learningGoals: (data['learningGoals'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class TeacherClass {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final String? section;
  final double averageScore;
  final List<ClassStudent> students;

  const TeacherClass({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    this.section,
    this.averageScore = 0,
    this.students = const [],
  });

  int get studentCount => students.length;

  double get attendanceRate {
    if (students.isEmpty) return 0;
    final total = students.fold<double>(0, (sum, student) => sum + student.attendanceRate);
    return total / students.length;
  }

  factory TeacherClass.fromMap(
    String id,
    Map<String, dynamic> data, {
    List<ClassStudent> students = const [],
  }) {
    final subject = data['subject'] as String? ?? 'General';
    final grade = data['grade'] as String? ?? 'General';
    final section = data['section'] as String?;
    final fallbackName = section == null || section.isEmpty
        ? '$grade $subject'
        : '$grade $subject - $section';

    return TeacherClass(
      id: id,
      name: data['name'] as String? ?? fallbackName,
      subject: subject,
      grade: grade,
      section: section,
      averageScore: (data['averageScore'] as num?)?.toDouble() ?? 0,
      students: students,
    );
  }
}
