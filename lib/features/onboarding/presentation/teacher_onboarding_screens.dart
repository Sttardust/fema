import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class TeacherExperienceScreen extends ConsumerStatefulWidget {
  const TeacherExperienceScreen({super.key});

  @override
  ConsumerState<TeacherExperienceScreen> createState() => _TeacherExperienceScreenState();
}

class _TeacherExperienceScreenState extends ConsumerState<TeacherExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolsController = TextEditingController();
  final List<String> _selectedGrades = [];
  final List<String> _selectedSubjects = [];

  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Amharic', 'Social Studies', 'ICT'
  ];

  final List<String> _grades = [
    'Grade 1-4', 'Grade 5-8', 'Grade 9-10', 'Grade 11-12'
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _schoolsController.text = state.pastSchools ?? '';
    _selectedGrades.addAll(state.teachingGrades);
    _selectedSubjects.addAll(state.teachingSubjects);
  }

  void _onContinue() {
    if (_formKey.currentState!.validate() && _selectedGrades.isNotEmpty && _selectedSubjects.isNotEmpty) {
      ref.read(onboardingProvider.notifier).updateTeachingRole(
        grades: _selectedGrades,
        subjects: _selectedSubjects,
        schools: _schoolsController.text,
      );
      context.push('/onboarding/details');
    } else if (_selectedGrades.isEmpty || _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one grade and one subject')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 1,
        totalSteps: 3, 
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Your Teaching Journey",
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                'Help us understand your background to match you with classes.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppConstants.space32),
              
              Text('Which grades do you teach?*', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstants.space12),
              Wrap(
                spacing: 8,
                children: _grades.map((grade) {
                  final isSelected = _selectedGrades.contains(grade);
                  return FilterChip(
                    label: Text(grade),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGrades.add(grade);
                        } else {
                          _selectedGrades.remove(grade);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AppConstants.space24),
              Text('Your specializations?*', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstants.space12),
              Wrap(
                spacing: 8,
                children: _subjects.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubjects.add(subject);
                        } else {
                          _selectedSubjects.remove(subject);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),

              const SizedBox(height: AppConstants.space24),
              AppTextField(
                controller: _schoolsController,
                hintText: 'e.g. Hilltop Academy, Sunrise School',
                labelText: 'Previous/Current Schools',
                maxLines: 3,
              ),
              
              const SizedBox(height: AppConstants.space40),
              AppButton(
                text: 'Continue',
                onPressed: _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherPersonalizationScreen extends ConsumerStatefulWidget {
  const TeacherPersonalizationScreen({super.key});

  @override
  ConsumerState<TeacherPersonalizationScreen> createState() => _TeacherPersonalizationScreenState();
}

class _TeacherPersonalizationScreenState extends ConsumerState<TeacherPersonalizationScreen> {
  String? _usesDigitalTools;
  String? _sharesContent;

  void _onContinue() {
    if (_usesDigitalTools != null && _sharesContent != null) {
      ref.read(onboardingProvider.notifier).setPersonalizationAnswers(
        usesDigitalTools: _usesDigitalTools,
        sharesContent: _sharesContent,
      );
      ref.read(onboardingProvider.notifier).completeOnboarding();
      context.push('/onboarding/intro');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 3,
        totalSteps: 3,
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Personalize Your Experience",
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              "Help us understand how you'd like to use FEMA.",
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppConstants.space32),
            
            Text(
              "Do you currently use digital tools in your teaching?",
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.space12),
            _SelectionOption(
              label: "Yes, frequently",
              isSelected: _usesDigitalTools == "Yes, frequently",
              onTap: () => setState(() => _usesDigitalTools = "Yes, frequently"),
            ),
            _SelectionOption(
              label: "Sometimes",
              isSelected: _usesDigitalTools == "Sometimes",
              onTap: () => setState(() => _usesDigitalTools = "Sometimes"),
            ),
            _SelectionOption(
              label: "No, but I'm interested",
              isSelected: _usesDigitalTools == "No, but I'm interested",
              onTap: () => setState(() => _usesDigitalTools = "No, but I'm interested"),
            ),

            const SizedBox(height: AppConstants.space24),
            Text(
              "Would you like to share your own teaching content?",
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.space12),
            _SelectionOption(
              label: "Yes, I'd love to contribute",
              isSelected: _sharesContent == "Yes",
              onTap: () => setState(() => _sharesContent = "Yes"),
            ),
            _SelectionOption(
              label: "Maybe later",
              isSelected: _sharesContent == "Maybe later",
              onTap: () => setState(() => _sharesContent = "Maybe later"),
            ),
            _SelectionOption(
              label: "No, I'm just here to use existing content",
              isSelected: _sharesContent == "No",
              onTap: () => setState(() => _sharesContent = "No"),
            ),

            const SizedBox(height: AppConstants.space40),
            AppButton(
              text: 'Continue',
              onPressed: _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.greyLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
