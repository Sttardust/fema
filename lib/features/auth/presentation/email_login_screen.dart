import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../domain/auth_repository.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authRepositoryProvider).signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );

        final onboardingState = ref.read(onboardingProvider);
        if (mounted) {
          if (onboardingState.role == UserRole.none) {
            context.push('/onboarding');
          } else {
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                'Log in with your email to continue your journey.',
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              AppButton(
                text: 'Log In',
                onPressed: _onLogin,
              ),
              const SizedBox(height: AppConstants.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTextStyles.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
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
                label: const Text('Log in with Phone Number'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
