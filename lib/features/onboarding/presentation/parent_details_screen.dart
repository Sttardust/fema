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

class ParentDetailsScreen extends ConsumerStatefulWidget {
  const ParentDetailsScreen({super.key});

  @override
  ConsumerState<ParentDetailsScreen> createState() => _ParentDetailsScreenState();
}

class _ParentDetailsScreenState extends ConsumerState<ParentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      ref.read(onboardingProvider.notifier).updatePersonalDetails(
            firstName: _firstNameController.text,
            surName: _surNameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      context.push('/onboarding/child-secure');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: OnboardingProgressHeader(
        currentStep: 1,
        totalSteps: 8,
        showSkip: true,
        onSkip: () => context.go('/home'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.space32),
              
              // Image Header (using existing asset pattern if available, or a colored circle)
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.family_restroom_outlined, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                "Let's get to know each other!",
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Please provide your basic details to personalize your experience and ensure a secure learning environment.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              const _FormLabel(label: "First Name"),
              AppTextField(
                controller: _firstNameController,
                hintText: 'e.g. Abebe',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              const _FormLabel(label: "Surname"),
              AppTextField(
                controller: _surNameController,
                hintText: 'e.g. Kebede',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              const _FormLabel(label: "Email Address (Optional)"),
              AppTextField(
                controller: _emailController,
                hintText: 'abebe@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 24),
              const _FormLabel(label: "Create Password"),
              AppTextField(
                controller: _passwordController,
                hintText: '••••••••••••',
                isPassword: true,
                validator: (value) => value != null && value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              
              const SizedBox(height: 48),
              AppButton(
                text: 'Continue',
                onPressed: _onContinue,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textHeadline),
      ),
    );
  }
}
