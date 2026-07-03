import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// FEMA brand mark: a lantern (kuraz) with a flame cut-out — the light of
/// knowledge. Mirrors `component/Lantern Mark` in design/fema-design.pen.
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
    return CustomPaint(
      size: Size.square(size),
      painter: _LanternPainter(color ?? AppColors.primary),
    );
  }
}

class _LanternPainter extends CustomPainter {
  final Color color;
  const _LanternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    // Glyph spans y 0.75–20.2 in the 24-unit box; nudge to optical center.
    canvas.translate(0, 1.5);

    final path = Path()..fillType = PathFillType.evenOdd;

    // Handle
    path.moveTo(12, 0.75);
    path.cubicTo(9.9, 0.75, 8.25, 2.2, 8.25, 4);
    path.lineTo(9.75, 4);
    path.cubicTo(9.75, 3, 10.7, 2.25, 12, 2.25);
    path.cubicTo(13.3, 2.25, 14.25, 3, 14.25, 4);
    path.lineTo(15.75, 4);
    path.cubicTo(15.75, 2.2, 14.1, 0.75, 12, 0.75);
    path.close();

    // Cap
    path.moveTo(7.5, 4.5);
    path.lineTo(16.5, 4.5);
    path.cubicTo(16.9, 4.5, 17.2, 4.8, 17.2, 5.2);
    path.lineTo(17.2, 5.6);
    path.cubicTo(17.2, 6, 16.9, 6.3, 16.5, 6.3);
    path.lineTo(7.5, 6.3);
    path.cubicTo(7.1, 6.3, 6.8, 6, 6.8, 5.6);
    path.lineTo(6.8, 5.2);
    path.cubicTo(6.8, 4.8, 7.1, 4.5, 7.5, 4.5);
    path.close();

    // Body
    path.moveTo(8.2, 7);
    path.lineTo(15.8, 7);
    path.cubicTo(16.5, 7, 17, 7.5, 17, 8.2);
    path.lineTo(17, 15.8);
    path.cubicTo(17, 16.5, 16.5, 17, 15.8, 17);
    path.lineTo(8.2, 17);
    path.cubicTo(7.5, 17, 7, 16.5, 7, 15.8);
    path.lineTo(7, 8.2);
    path.cubicTo(7, 7.5, 7.5, 7, 8.2, 7);
    path.close();

    // Flame cut-out
    path.moveTo(12, 9.2);
    path.cubicTo(13.1, 10.4, 14, 11.5, 14, 12.7);
    path.cubicTo(14, 13.9, 13.1, 14.8, 12, 14.8);
    path.cubicTo(10.9, 14.8, 10, 13.9, 10, 12.7);
    path.cubicTo(10, 11.5, 10.9, 10.4, 12, 9.2);
    path.close();

    // Base
    path.moveTo(7, 17.8);
    path.lineTo(17, 17.8);
    path.cubicTo(17.55, 17.8, 18, 18.25, 18, 18.8);
    path.lineTo(18, 19.2);
    path.cubicTo(18, 19.75, 17.55, 20.2, 17, 20.2);
    path.lineTo(7, 20.2);
    path.cubicTo(6.45, 20.2, 6, 19.75, 6, 19.2);
    path.lineTo(6, 18.8);
    path.cubicTo(6, 18.25, 6.45, 17.8, 7, 17.8);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LanternPainter oldDelegate) => oldDelegate.color != color;
}

/// Lockup: logo + "FEMA" wordmark side-by-side. Used in app bars and the
/// About screen header.
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
          'FEMA',
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
