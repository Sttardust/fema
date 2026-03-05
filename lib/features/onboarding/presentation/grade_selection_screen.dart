import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class GradeSelectionScreen extends ConsumerStatefulWidget {
  const GradeSelectionScreen({super.key});

  @override
  ConsumerState<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends ConsumerState<GradeSelectionScreen> {
  String? selectedGrade;
  final List<String> grades = [
    'KG', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4',
    'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8',
    'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'
  ];

  void _onContinue() {
    if (selectedGrade == null) return;

    ref.read(onboardingProvider.notifier).setGrade(selectedGrade!);
    
    final onboardingState = ref.read(onboardingProvider);
    if (onboardingState.role == UserRole.parent) {
      context.push('/onboarding/subjects-confident');
    } else {
      final gradeIdx = grades.indexOf(selectedGrade!);
      if (gradeIdx <= 4) { // KG to Grade 4
        _showParentalModal();
      } else {
        context.push('/onboarding/details');
      }
    }
  }

  void _showParentalModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radius16)),
        title: const Text('Parental Assistance Needed'),
        content: const Text(
          'It looks like you are in a lower grade. Please ask your parent or guardian to help you with the next steps of the setup.'
        ),
        actions: [
          AppButton(
            text: 'I Understand',
            height: 48,
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final isParent = onboardingState.role == UserRole.parent;

    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: isParent ? 4 : 1,
        totalSteps: isParent ? 8 : 8,
        showSkip: !isParent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              isParent ? "What grade is your child in?" : "What grade are you in?",
              style: AppTextStyles.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              isParent
                  ? "This helps us customize the learning experience based on your child's level and make sure they get the right support."
                  : "This helps us tailor the content to your specific level.",
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space40),
            DropdownButtonFormField<String>(
              value: selectedGrade,
              hint: isParent ? const Text('Grade') : const Text('Select your grade'),
              items: grades.map((grade) {
                return DropdownMenuItem(value: grade, child: Text(grade));
              }).toList(),
              onChanged: (val) => setState(() => selectedGrade = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
              ),
            ),
            const Spacer(),
            AppButton(
              text: 'Continue',
              onPressed: selectedGrade != null ? _onContinue : null,
            ),
            const SizedBox(height: AppConstants.space32),
          ],
        ),
      ),
    );
  }
}
