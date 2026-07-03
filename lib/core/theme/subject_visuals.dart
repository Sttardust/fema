import 'package:flutter/material.dart';
import '../../features/library/domain/models.dart';
import 'app_colors.dart';

IconData subjectIcon(CourseSubject subject) {
  switch (subject) {
    case CourseSubject.math:
      return Icons.calculate;
    case CourseSubject.science:
      return Icons.science;
    case CourseSubject.english:
      return Icons.menu_book;
    case CourseSubject.amharic:
      return Icons.translate;
    case CourseSubject.socialStudies:
      return Icons.public;
    case CourseSubject.other:
      return Icons.school;
  }
}

Color subjectTint(CourseSubject subject) =>
    AppColors.subjectTints[subject.index % AppColors.subjectTints.length];
