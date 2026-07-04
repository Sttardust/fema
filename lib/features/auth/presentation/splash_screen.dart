import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';

/// Brand splash, shown while the app boots (min 2s via the router's splash
/// gate). Mirrors the "Splash" frame in fema-design.pen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 34,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const AppLogo(size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'FEMA',
                    style: GoogleFonts.figtree(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learn anywhere, anytime',
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      color: const Color(0xB3FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 88),
                child: _LoaderDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderDots extends StatefulWidget {
  const _LoaderDots();

  @override
  State<_LoaderDots> createState() => _LoaderDotsState();
}

class _LoaderDotsState extends State<_LoaderDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == active ? Colors.white : const Color(0x4DFFFFFF),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
