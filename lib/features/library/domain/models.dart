import 'package:flutter/foundation.dart';

enum CourseSubject { math, science, english, socialStudies, amharic, other }

class Lesson {
  final String id;
  final String title;
  final String description;
  final String? videoUrl;
  final String? contentHtml;
  final int durationMinutes;
  final bool isCompleted;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    this.videoUrl,
    this.contentHtml,
    this.durationMinutes = 15,
    this.isCompleted = false,
  });

  Lesson copyWith({
    bool? isCompleted,
  }) {
    return Lesson(
      id: id,
      title: title,
      description: description,
      videoUrl: videoUrl,
      contentHtml: contentHtml,
      durationMinutes: durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final CourseSubject subject;
  final String grade;
  final String thumbnailUrl;
  final List<Lesson> lessons;
  final double rating;
  final int totalStudents;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.grade,
    required this.thumbnailUrl,
    required this.lessons,
    this.rating = 4.5,
    this.totalStudents = 100,
  });

  int get completedLessons => lessons.where((l) => l.isCompleted).length;
  double get progress => lessons.isEmpty ? 0 : completedLessons / lessons.length;
}
