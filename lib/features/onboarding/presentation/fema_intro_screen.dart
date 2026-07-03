import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Entry screen for unauthenticated users. Auto-advancing 3-page carousel
/// over a dark gradient + smoke backdrop ("Welcome v2" in fema-design.pen),
/// with "Get started" (signup), "Browse as guest" (home), and a sign-in
/// footer at the bottom.
class FemaIntroScreen extends StatefulWidget {
  const FemaIntroScreen({super.key});

  @override
  State<FemaIntroScreen> createState() => _FemaIntroScreenState();
}

class _FemaIntroScreenState extends State<FemaIntroScreen> {
  static const _autoAdvance = Duration(seconds: 4);
  // Background pans left as slides advance (parallax), per the design.
  static const _parallaxPerPage = 103.5;

  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  final List<_IntroPage> _pages = const [
    _IntroPage(
      title: 'Learn anywhere,\nanytime',
      description:
          'Video lessons for Grades 1–12, made for Ethiopian students. Learn at your own pace.',
    ),
    _IntroPage(
      title: 'Real lessons,\nreal teachers',
      description:
          'Watch curriculum-aligned video lessons made for the Ethiopian classroom.',
    ),
    _IntroPage(
      title: 'Teachers run\ntheir classroom',
      description:
          'Classes, students, and attendance — all in one place for every teacher.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_autoAdvance, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_pageController.hasClients) return;
    final next = (_currentPage + 1) % _pages.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  double get _pageOffset =>
      _pageController.hasClients && _pageController.position.haveDimensions
          ? _pageController.page ?? _currentPage.toDouble()
          : _currentPage.toDouble();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF08061C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF08061C), Color(0xFF1E0A40), Color(0xFF3D0072)],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Smoke backdrop with horizontal parallax
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                return Positioned(
                  left: -_pageOffset * _parallaxPerPage,
                  top: 0,
                  bottom: 0,
                  width: size.width * 1.53,
                  child: Image.asset(
                    'assets/images/welcome_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            // Content over a bottom scrim
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF240C4A), Color(0xFF240C4A), Color(0x00240C4A)],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 150,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemBuilder: (context, index) => _pages[index],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = _currentPage == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active ? Colors.white : const Color(0x40FFFFFF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      _WhitePillButton(
                        label: 'Get started',
                        onTap: () => context.go('/signup'),
                      ),
                      const SizedBox(height: 12),
                      _GhostPillButton(
                        label: 'Browse as guest',
                        onTap: () => context.go('/home'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: GoogleFonts.figtree(
                              fontSize: 13,
                              color: const Color(0x70FFFFFF),
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String title;
  final String description;

  const _IntroPage({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.figtree(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: GoogleFonts.figtree(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFFC4B0E0),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WhitePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WhitePillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.figtree(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D0072),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
          side: const BorderSide(color: Color(0x50FFFFFF)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xCCFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
