import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/app_logo.dart';

/// Entry screen for unauthenticated users. Auto-advancing 3-page carousel
/// with "Get started" (signup), "Browse as guest" (home), and a sign-in
/// footer at the bottom.
class FemaIntroScreen extends StatefulWidget {
  const FemaIntroScreen({super.key});

  @override
  State<FemaIntroScreen> createState() => _FemaIntroScreenState();
}

class _FemaIntroScreenState extends State<FemaIntroScreen> {
  static const _autoAdvance = Duration(seconds: 4);

  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  final List<_IntroPage> _pages = const [
    _IntroPage(
      title: 'Welcome to FEMA!',
      description:
          'A smart way to learn, grow, and shine.\nBuilt for Ethiopian students, parents, and educators.',
    ),
    _IntroPage(
      title: 'Expert Teachers',
      description:
          "Learn from Ethiopia's best educators and stay ahead in your learning journey.",
    ),
    _IntroPage(
      title: 'Academic Success',
      description:
          'Track your progress and achieve excellence with our adaptive learning tools.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = _currentPage == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.greyLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Primary action — Get started → signup
                  PillButton(
                    label: 'Get started',
                    onPressed: () => context.go('/signup'),
                  ),
                  const SizedBox(height: 12),
                  // Secondary action — Browse as guest → home
                  PillButton.outlined(
                    label: 'Browse as guest',
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 20),
                  // Footer — sign-in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: AppColors.grey,
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
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon composition: 200px primarySoft circle → 120px primary circle → white icon
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const AppLogo(size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            style: GoogleFonts.figtree(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textBody,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.figtree(
              fontSize: 14,
              height: 1.55,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
