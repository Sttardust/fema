import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum _PillButtonVariant { filled, outlined }

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final _PillButtonVariant _variant;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  }) : _variant = _PillButtonVariant.filled;

  const PillButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  }) : _variant = _PillButtonVariant.outlined;

  bool get _isDisabled => !enabled || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final isFilled = _variant == _PillButtonVariant.filled;

    final Color fillColor = _isDisabled
        ? AppColors.greyLight
        : (isFilled ? AppColors.primary : AppColors.surface);

    final Color labelColor = _isDisabled
        ? AppColors.grey
        : (isFilled ? Colors.white : AppColors.textBody);

    final Color iconColor = _isDisabled
        ? AppColors.grey
        : (isFilled ? Colors.white : AppColors.primary);

    final List<BoxShadow> shadows = (_isDisabled || !isFilled)
        ? []
        : [
            const BoxShadow(
              color: AppColors.primaryShadow,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ];

    final BoxDecoration decoration = BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(27),
      border: isFilled && !_isDisabled
          ? null
          : Border.all(color: AppColors.greyLight),
      boxShadow: shadows,
    );

    final TextStyle labelStyle = isFilled
        ? GoogleFonts.figtree(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: labelColor,
          )
        : GoogleFonts.figtree(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          );

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
        ],
        Text(label, style: labelStyle),
      ],
    );

    return Container(
      height: 54,
      width: double.infinity,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: _isDisabled ? null : onPressed,
          child: Center(child: content),
        ),
      ),
    );
  }
}
