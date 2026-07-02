import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PillTextField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool focused;
  final ValueChanged<String>? onChanged;

  const PillTextField({
    super.key,
    required this.hint,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.focused = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.greyLight,
          width: focused ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.grey),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: GoogleFonts.figtree(
                fontSize: 14,
                color: AppColors.textBody,
              ),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
