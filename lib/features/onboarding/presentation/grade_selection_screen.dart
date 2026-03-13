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
  String? _selectedGrade;
  final List<String> _primaryGrades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];
  final List<String> _secondaryGrades = ['Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];

  void _onContinue() {
    if (_selectedGrade == null) return;

    final onboardingState = ref.read(onboardingProvider);
    if (onboardingState.role == UserRole.parent) {
      ref.read(onboardingProvider.notifier).setGrade(_selectedGrade!);
      context.push('/onboarding/subjects-confident');
    } else {
      // Logic for parental assistance for lower grades (customizable threshold)
      if (_selectedGrade == 'Grade 1' || _selectedGrade == 'Grade 2' || _selectedGrade == 'Grade 3') {
        _showParentalModal();
      } else {
        ref.read(onboardingProvider.notifier).setGrade(_selectedGrade!);
        context.push('/onboarding/details');
      }
    }
  }

  void _showParentalModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Parental Assistance', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'For foundation years, we recommend completing the setup with a parent or guardian to ensure the best experience.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Change Grade'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('I Understand'),
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
      backgroundColor: Colors.white,
      appBar: OnboardingProgressHeader(
        currentStep: isParent ? 4 : 1,
        totalSteps: 8,
        showSkip: !isParent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                isParent ? "What grade is your child in?" : "What grade are you in?",
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Select your current grade to get personalized learning content.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Primary Education'),
              const SizedBox(height: 12),
              _buildGradeGrid(_primaryGrades),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Secondary Education'),
              const SizedBox(height: 12),
              _buildGradeGrid(_secondaryGrades),
              
              const SizedBox(height: 40),
              AppButton(
                text: 'Continue',
                onPressed: _selectedGrade != null ? _onContinue : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.grey,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGradeGrid(List<String> grades) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final grade = grades[index];
        final isSelected = _selectedGrade == grade;
        return InkWell(
          onTap: () => setState(() => _selectedGrade = grade),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.greyLight,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Center(
              child: Text(
                grade,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textHeadline,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
