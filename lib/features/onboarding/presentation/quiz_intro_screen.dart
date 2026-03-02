import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class QuizIntroScreen extends ConsumerWidget {
  const QuizIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 7,
        totalSteps: 7,
        showSkip: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.quiz_outlined, size: 100, color: AppColors.primary),
            const SizedBox(height: AppConstants.space32),
            Text(
              "Ready to See Where You Stand?",
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              "Take a quick 10-question quiz tailored to your interests. This helps us place you in the right level.",
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            AppButton(
              text: 'Take the Quiz',
              onPressed: () {
                context.push('/onboarding/quiz');
              },
            ),
            const SizedBox(height: AppConstants.space16),
            TextButton(
              onPressed: () {
                ref.read(onboardingProvider.notifier).setQuizSkipped(true);
                context.push('/onboarding/intro');
              },
              child: Text(
                'Skip for now',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppConstants.space48),
          ],
        ),
      ),
    );
  }
}
