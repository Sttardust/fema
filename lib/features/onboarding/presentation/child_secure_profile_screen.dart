import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class ChildSecureProfileScreen extends ConsumerStatefulWidget {
  const ChildSecureProfileScreen({super.key});

  @override
  ConsumerState<ChildSecureProfileScreen> createState() => _ChildSecureProfileScreenState();
}

class _ChildSecureProfileScreenState extends ConsumerState<ChildSecureProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      final currentChild = ref.read(onboardingProvider).activeChild ?? ChildProfile();
      ref.read(onboardingProvider.notifier).updateActiveChild(
            currentChild.copyWith(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
      context.push('/onboarding/child-basic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 2,
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
                "Create a Secure profile information",
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space16),
              Text(
                "Set a username and password your child can use to log in safely. Make it something memorable and age-appropriate.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space32),
              Text("Username", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(hintText: 'temesgen'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Create Password", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
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
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Confirm Password", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: '**************',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
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
