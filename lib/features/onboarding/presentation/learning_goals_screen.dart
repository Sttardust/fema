import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class LearningGoalsScreen extends ConsumerStatefulWidget {
  const LearningGoalsScreen({super.key});

  @override
  ConsumerState<LearningGoalsScreen> createState() => _LearningGoalsScreenState();
}

class _LearningGoalsScreenState extends ConsumerState<LearningGoalsScreen> {
  final List<String> availableGoals = [
    'Improve grades',
    'Prepare for national exams',
    'Catch up on missed lessons',
    'Get ahead of current class level',
    'Learn at his/her own pace',
    'Help my child succeed',
    'Explore and stay informed'
  ];
  
  final List<String> selectedGoals = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    final currentGoals = state.role == UserRole.parent 
        ? state.activeChild?.learningGoals 
        : state.learningGoals;
    
    if (currentGoals != null) {
      selectedGoals.addAll(currentGoals);
    }
  }

  void _onContinue() {
    final notifier = ref.read(onboardingProvider.notifier);
    final isParent = ref.read(onboardingProvider).role == UserRole.parent;

    notifier.setLearningGoals(selectedGoals);
    
    if (isParent) {
      notifier.saveActiveChild();
      context.push('/onboarding/child-list');
    } else {
      context.push('/onboarding/referral');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParent = ref.watch(onboardingProvider).role == UserRole.parent;

    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: isParent ? 7 : 5,
        totalSteps: isParent ? 8 : 7,
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              isParent ? "What’s Your Learning Goal for your child?" : "What Are Your Learning Goals?",
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              isParent 
                  ? "Let us know what you're aiming for, so we can support your child's learning journey with the right tools and content."
                  : "Select all that apply to help us personalize your path.",
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space32),
            Expanded(
              child: ListView.separated(
                itemCount: availableGoals.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space12),
                itemBuilder: (context, index) {
                  final goal = availableGoals[index];
                  final isSelected = selectedGoals.contains(goal);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          selectedGoals.add(goal);
                        } else {
                          selectedGoals.remove(goal);
                        }
                      });
                    },
                    title: Text(goal, style: AppTextStyles.bodyLarge),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.greyLight,
                    ),
                    tileColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.space24),
            AppButton(
              text: 'Continue',
              onPressed: _onContinue,
            ),
            const SizedBox(height: AppConstants.space32),
          ],
        ),
      ),
    );
  }
}
