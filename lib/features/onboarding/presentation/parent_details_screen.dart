import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
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
  bool _obscurePassword = true;

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
              Text(
                "Lets get to now each other!",
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space16),
              Text(
                "Please provide your basic details to personalize your experience and ensure a secure learning environment.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space32),
              Text("First Name *", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(hintText: 'temesgen'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Sur Name *", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _surNameController,
                decoration: const InputDecoration(hintText: 'temesgen'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Email", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'temesgen'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Password", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '**************',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space48),
              AppButton(
                text: 'Continue',
                onPressed: _onContinue,
              ),
              const SizedBox(height: AppConstants.space32),
            ],
          ),
        ),
      ),
    );
  }
}
