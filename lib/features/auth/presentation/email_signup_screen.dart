import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../domain/auth_repository.dart';

class EmailSignupScreen extends ConsumerStatefulWidget {
  const EmailSignupScreen({super.key});

  @override
  ConsumerState<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends ConsumerState<EmailSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _onSignUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authRepositoryProvider).signUpWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        
        ref.read(onboardingProvider.notifier).updatePersonalDetails(
          email: _emailController.text,
        );
        
        if (mounted) {
          context.push('/onboarding/details'); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign up failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create an Account',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                'Sign up with your email to continue your onboarding.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space32),
              AppTextField(
                controller: _emailController,
                hintText: 'Enter your email',
                labelText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  if (value == null || !value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.space20),
              AppTextField(
                controller: _passwordController,
                hintText: 'Enter your password',
                labelText: 'Password',
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (value) {
                  if (value == null || value.length < 6) return 'Password too short';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.space20),
              AppTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm your password',
                labelText: 'Confirm Password',
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (value) {
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.space32),
              AppButton(
                text: 'Sign Up',
                onPressed: _onSignUp,
              ),
              const SizedBox(height: AppConstants.space24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppConstants.space24),
              OutlinedButton.icon(
                onPressed: () => context.push('/signup-phone'),
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Sign up with Phone Number'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: AppConstants.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text("Already have an account? ", style: AppTextStyles.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      'Log In',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
