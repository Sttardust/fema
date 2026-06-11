import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FEMA brand mark: two overlapping rounded diamonds in primary purple,
/// the back one rendered at lower opacity. Matches the Figma "Splash Screen"
/// and "Role selection" mockups. Sizes scale with [size].
class AppLogo extends StatelessWidget {
  /// Total bounding-box width of the mark. Height is the same.
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final tile = size * 0.46;
    final offset = size * 0.20;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back diamond — lighter, offset right
          Positioned(
            left: offset,
            child: Transform.rotate(
              angle: 0.7853981633974483, // 45°
              child: Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(size * 0.06),
                ),
              ),
            ),
          ),
          // Front diamond — solid
          Positioned(
            right: offset,
            child: Transform.rotate(
              angle: 0.7853981633974483,
              child: Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(size * 0.06),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lockup: logo + "Fema" wordmark side-by-side. Used in app bars and the
/// role-selection header.
class AppLogoLockup extends StatelessWidget {
  final double logoSize;
  final double textSize;
  final Color? color;

  const AppLogoLockup({
    super.key,
    this.logoSize = 32,
    this.textSize = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize, color: c),
        SizedBox(width: logoSize * 0.25),
        Text(
          'Fema',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w800,
            color: c,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
