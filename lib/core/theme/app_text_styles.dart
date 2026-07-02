import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get headlineLarge => GoogleFonts.figtree(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textHeadline,
      );

  static TextStyle get headlineMedium => GoogleFonts.figtree(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textHeadline,
      );

  static TextStyle get headlineSmall => GoogleFonts.figtree(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textHeadline,
      );

  static TextStyle get bodyLarge => GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textBody,
      );

  static TextStyle get bodyMedium => GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textBody,
      );

  static TextStyle get bodySmall => GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textBody,
      );

  static TextStyle get button => GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get caption => GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.grey,
      );
}
