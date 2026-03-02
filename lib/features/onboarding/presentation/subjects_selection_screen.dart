import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class SubjectsSelectionScreen extends ConsumerStatefulWidget {
  final bool isConfident;

  const SubjectsSelectionScreen({
    super.key,
    required this.isConfident,
  });

  @override
  ConsumerState<SubjectsSelectionScreen> createState() => _SubjectsSelectionScreenState();
}

class _SubjectsSelectionScreenState extends ConsumerState<SubjectsSelectionScreen> {
  final List<String> availableSubjects = [
    'Math', 'Physics', 'English', 'Biology',
    'Chemistry', 'Geography', 'Civics', 'Amharic',
    'History', 'Economics', 'IT'
  ];
  
  final List<String> selectedSubjects = [];
  final TextEditingController _addSubjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    final currentList = widget.isConfident 
        ? (state.role == UserRole.parent ? state.activeChild?.confidentSubjects : state.confidentSubjects)
        : (state.role == UserRole.parent ? state.activeChild?.improvementSubjects : state.improvementSubjects);
    
    if (currentList != null) {
      selectedSubjects.addAll(currentList);
    }
  }

  @override
  void dispose() {
    _addSubjectController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final notifier = ref.read(onboardingProvider.notifier);
    final isParent = ref.read(onboardingProvider).role == UserRole.parent;

    if (widget.isConfident) {
      notifier.setConfidentSubjects(selectedSubjects);
      context.push('/onboarding/subjects-improve');
    } else {
      notifier.setImprovementSubjects(selectedSubjects);
      context.push('/onboarding/goals');
    }
  }

  void _addCustomSubject() {
    final text = _addSubjectController.text.trim();
    if (text.isNotEmpty && !selectedSubjects.contains(text)) {
      setState(() {
        selectedSubjects.add(text);
        if (!availableSubjects.contains(text)) {
          availableSubjects.add(text);
        }
        _addSubjectController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParent = ref.watch(onboardingProvider).role == UserRole.parent;

    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: isParent ? (widget.isConfident ? 5 : 6) : (widget.isConfident ? 3 : 4),
        totalSteps: isParent ? 8 : 7,
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              isParent
                  ? (widget.isConfident 
                      ? "Which subjects is your child confident in?" 
                      : "Which subjects do you want your child to improve?")
                  : (widget.isConfident 
                      ? "Subjects You're Confident In" 
                      : "Subjects You Need Improvement In"),
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              isParent
                  ? (widget.isConfident
                      ? "Select the subjects you feel your child is strongest in. This helps us recommend advanced materials and challenges."
                      : "Select the subjects where your child need more support. We'll tailor learning experience to help your child grow.")
                  : (widget.isConfident
                      ? "Select the subjects you excel at."
                      : "Which subjects do you want to focus on more?"),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppConstants.space12,
                      runSpacing: AppConstants.space12,
                      children: availableSubjects.map((subject) {
                        final isSelected = selectedSubjects.contains(subject);
                        return FilterChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedSubjects.add(subject);
                              } else {
                                selectedSubjects.remove(subject);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.1),
                          checkmarkColor: AppColors.primary,
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textBody,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius12),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.greyLight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppConstants.space32),
                    Text("Not in the list?", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _addSubjectController,
                      decoration: InputDecoration(
                        hintText: 'Add Subject',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          onPressed: _addCustomSubject,
                        ),
                      ),
                      onSubmitted: (_) => _addCustomSubject(),
                    ),
                  ],
                ),
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
