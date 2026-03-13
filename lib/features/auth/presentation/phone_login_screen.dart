import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/auth_repository.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      // For now, phone login might need a different flow or just password
      // Since the request said "phone field and the password field"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone login with password not yet fully implemented in backend')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Log In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
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
                'Log in with your phone number and password.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space32),
              AppTextField(
                controller: _phoneController,
                hintText: '912345678',
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.length < 9) return 'Invalid phone number';
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
              const SizedBox(height: AppConstants.space32),
              AppButton(
                text: 'Log In',
                onPressed: _onLogin,
              ),
              const SizedBox(height: AppConstants.space24),
              TextButton(
                onPressed: () => context.pushReplacement('/login'),
                child: Text(
                  'Switch to Email Login',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
