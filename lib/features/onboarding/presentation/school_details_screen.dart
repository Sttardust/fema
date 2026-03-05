import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class SchoolDetailsScreen extends ConsumerStatefulWidget {
  const SchoolDetailsScreen({super.key});

  @override
  ConsumerState<SchoolDetailsScreen> createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends ConsumerState<SchoolDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolController = TextEditingController();
  final _lastGradeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _schoolController.text = state.school ?? '';
    _lastGradeController.text = state.lastGrade ?? '';
  }

  void _onContinue() {
      ref.read(onboardingProvider.notifier).updateSchoolDetails(
        school: _schoolController.text,
        grade: _lastGradeController.text,
      );
      context.push('/onboarding/subjects-confident');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 3,
        totalSteps: 8,
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
                "Tell Us About Your School Journey",
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                'This helps us understand your academic background.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppConstants.space32),
              AppTextField(
                controller: _schoolController,
                hintText: 'Enter your school name',
                labelText: 'School',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              AppTextField(
                controller: _lastGradeController,
                hintText: 'e.g. 85% or Grade A',
                labelText: 'Tell us your last year or last semester grade',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
