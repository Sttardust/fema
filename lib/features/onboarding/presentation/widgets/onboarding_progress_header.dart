import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingProgressHeader extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final int totalSteps;
  final bool showSkip;
  final VoidCallback? onSkip;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.showSkip = true,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const BackButton(),
      title: SizedBox(
        width: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: AppColors.greyLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        if (showSkip)
          TextButton(
            onPressed: onSkip ?? () => context.push('/onboarding/intro'),
            child: Text(
              'Skip',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(width: AppConstants.space8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
