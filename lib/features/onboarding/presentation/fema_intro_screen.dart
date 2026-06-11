import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Entry screen for unauthenticated users. Auto-advancing 3-page carousel
/// with persistent Sign Up / Login at bottom and a "Browse the app" link
/// in the top-right that drops the user into guest-mode /home.
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
      imagePath: 'assets/images/intro/welcome_family.png',
    ),
    _IntroPage(
      title: 'Expert Teachers',
      description:
          "Learn from Ethiopia's best educators and stay ahead in your learning journey.",
      imagePath: 'assets/images/intro/expert_teachers.png',
    ),
    _IntroPage(
      title: 'Academic Success',
      description:
          'Track your progress and achieve excellence with our adaptive learning tools.',
      imagePath: 'assets/images/intro/academic_success.png',
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    'Browse the app',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = _currentPage == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.primaryLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Sign Up',
                    onPressed: () => context.go('/signup'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.greyLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.textHeadline,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
  final String imagePath;

  const _IntroPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeadline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
