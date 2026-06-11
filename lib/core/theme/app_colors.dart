import 'package:flutter/material.dart';

class AppColors {
  // Primary — brand violet from the FEMA Figma palette.
  static const Color primary = Color(0xFF6F28F4);
  static const Color primaryLight = Color(0xFFB28BF9);
  static const Color primaryDark = Color(0xFF4E1BB0);

  // Selection state used on the role cards, onboarding pills, etc.
  static const Color selectionFill = Color(0xFFD7F5E1); // mint
  static const Color selectionBorder = primary;

  // Secondary/Accent colors
  static const Color secondary = Color(0xFFFF7A59); // Salmon used in quiz
  static const Color accent = Color(0xFFFF9F1C); // Orange used for buttons/icons
  static const Color childrenModeBg = Color(0xFFE0F7F9); // Soft teal for children's mode

  // Neutral colors
  static const Color splashBg = Color(0xFFEEEEEE); // Splash + simple-canvas screens
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Colors.white;
  static const Color textBody = Color(0xFF2D3142);
  static const Color textHeadline = Color(0xFF0D1321);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
}
