import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const BackButton(color: AppColors.textHeadline),
      title: Column(
        children: [
          Text(
            'Step $currentStep of $totalSteps',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: currentStep / totalSteps,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (showSkip)
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}
