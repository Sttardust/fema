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
      appBar: OnboardingProgressHeader(
        currentStep: 8,
        totalSteps: 8,
        showSkip: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space32),
            Text(
              "Your Child’s Profile",
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space32),
            Expanded(
              child: ListView.separated(
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space16),
                itemBuilder: (context, index) {
                  final child = children[index];
                  return Container(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                      border: Border.all(color: AppColors.greyLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
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
                                "${child.grade ?? 'No Grade'}   Nickname - ${child.username ?? ''}",
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.grey),
                          onPressed: () {
                            // TODO: Implement edit logic
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.space16),
            OutlinedButton(
              onPressed: () {
                ref.read(onboardingProvider.notifier).updateActiveChild(ChildProfile());
                context.push('/onboarding/child-secure');
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                ),
              ),
              child: const Text('Create another profile', style: TextStyle(color: AppColors.primary)),
            ),
            const SizedBox(height: AppConstants.space32),
            AppButton(
              text: 'Continue',
              onPressed: () {
                if (onboardingState.role == UserRole.parent) {
                  context.push('/onboarding/intro');
                } else {
                  context.push('/onboarding/referral');
                }
              },
            ),
            const SizedBox(height: AppConstants.space48),
          ],
        ),
      ),
    );
  }
}
