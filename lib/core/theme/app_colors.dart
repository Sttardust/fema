import 'package:flutter/material.dart';

class AppColors {
  // Brand — indigo, from the Pencil MVP design system.
  static const Color primary = Color(0xFF4B0082);
  static const Color primaryLight = Color(0xFF7A42B5);
  static const Color primaryDark = Color(0xFF38005F);
  static const Color primarySoft = Color(0xFFEFE7F8);

  // Selection state used on role cards, grade tiles, chips.
  static const Color selectionFill = primarySoft;
  static const Color selectionBorder = primary;

  // Legacy accents kept for hidden (non-MVP) screens; muted to palette tints.
  static const Color secondary = Color(0xFF8F5BC4);
  static const Color accent = Color(0xFFB187DD);
  static const Color childrenModeBg = primarySoft;

  // Neutrals
  static const Color splashBg = Color(0xFFF5F2FA);
  static const Color background = Color(0xFFF5F2FA);
  static const Color surface = Colors.white;
  static const Color textBody = Color(0xFF211936);
  static const Color textHeadline = Color(0xFF211936);
  static const Color grey = Color(0xFF8B84A0);
  static const Color greyLight = Color(0xFFE7E2F1);

  // Subject thumbnail tints (flat fills, no gradients)
  static const List<Color> subjectTints = [
    Color(0xFF4B0082),
    Color(0xFF6D35A6),
    Color(0xFF8F5BC4),
    Color(0xFFB187DD),
  ];

  // Semantic
  static const Color success = Color(0xFF2BB37A);
  static const Color error = Color(0xFFC0392B);
  static const Color errorSoft = Color(0xFFFDF2F2);
  static const Color warning = Color(0xFFE5A63C);

  // Card shadow: #1C1633 at 5%
  static const Color cardShadow = Color(0x0D1C1633);
  // Primary button shadow: #4B0082 at 25%
  static const Color primaryShadow = Color(0x404B0082);
}
