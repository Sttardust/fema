import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class ChildProfileListScreen extends ConsumerWidget {
  const ChildProfileListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final children = onboardingState.children;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: OnboardingProgressHeader(
        currentStep: 8,
        totalSteps: 8,
        showSkip: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.space32),
                    
                    // Header Image (Local Parent Asset)
                    Image.asset(
                      'assets/images/Parent/Students/Students list.png',
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline, size: 60, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      "Your Child’s Profile",
                      style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Review the profiles you've created before we get started.",
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Child Cards
                    ...List.generate(children.length, (index) {
                      final child = children[index];
                      // Alternate colors for a bit of playfulness
                      final isEven = index % 2 == 0;
                      final baseColor = isEven ? AppColors.primary : AppColors.secondary;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(AppConstants.space16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.greyLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: baseColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (child.fullName?.isNotEmpty == true) 
                                      ? child.fullName!.substring(0, 1).toUpperCase() 
                                      : '?',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: baseColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.fullName ?? 'Unnamed Child',
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${child.grade ?? 'No Grade'}   •   @${child.username ?? 'user'}",
                                    style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            // Edit
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.grey),
                              onPressed: () {
                                ref.read(onboardingProvider.notifier).editChild(index);
                                context.push('/onboarding/child-secure');
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    
                    // Add Another
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(onboardingProvider.notifier).updateActiveChild(ChildProfile());
                        context.push('/onboarding/child-secure');
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add another profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(color: AppColors.primaryLight, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(AppConstants.space24),
              child: AppButton(
                text: 'Complete Setup',
                onPressed: () async {
                  await ref.read(onboardingProvider.notifier).completeOnboarding();
                  if (context.mounted) {
                    context.push('/onboarding/intro');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
