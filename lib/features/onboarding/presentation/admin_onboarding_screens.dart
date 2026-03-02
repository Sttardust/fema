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

class AdminUserCreationScreen extends ConsumerStatefulWidget {
  const AdminUserCreationScreen({super.key});

  @override
  ConsumerState<AdminUserCreationScreen> createState() => _AdminUserCreationScreenState();
}

class _AdminUserCreationScreenState extends ConsumerState<AdminUserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      ref.read(onboardingProvider.notifier).updateInvitedUserBasicInfo(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      context.push('/onboarding/admin-password');
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
                "Invite a New User",
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                "As an admin, you can create accounts for teachers and other staff.",
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppConstants.space32),
              
              AppTextField(
                controller: _nameController,
                hintText: 'Enter full name',
                labelText: 'Full Name*',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              AppTextField(
                controller: _emailController,
                hintText: 'example@mail.com',
                labelText: 'Email Address*',
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              AppTextField(
                controller: _phoneController,
                hintText: '912345678',
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('+251', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
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

class AdminPasswordSetupScreen extends ConsumerStatefulWidget {
  const AdminPasswordSetupScreen({super.key});

  @override
  ConsumerState<AdminPasswordSetupScreen> createState() => _AdminPasswordSetupScreenState();
}

class _AdminPasswordSetupScreenState extends ConsumerState<AdminPasswordSetupScreen> {
  final _passwordController = TextEditingController();

  void _onFinish() {
    if (_passwordController.text.length >= 6) {
      ref.read(onboardingProvider.notifier).updateInvitedUserTempPassword(_passwordController.text);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('User Invited!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 64),
              const SizedBox(height: AppConstants.space16),
              const Text(
                'An invitation has been sent to the user with their temporary password.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            AppButton(
              text: 'Finish',
              onPressed: () {
                Navigator.pop(context);
                context.push('/onboarding/intro');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 2,
        totalSteps: 3,
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Set Security Credentials",
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              "Create a temporary password for the new user. They will be required to change it on their first login.",
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppConstants.space32),
            
            AppTextField(
              controller: _passwordController,
              hintText: 'Create temp password',
              labelText: 'Temporary Password*',
              isPassword: true,
              validator: (val) => val == null || val.length < 6 ? 'Too short' : null,
            ),
            
            const Spacer(),
            AppButton(
              text: 'Finish & Send Invite',
              onPressed: _onFinish,
            ),
            const SizedBox(height: AppConstants.space48),
          ],
        ),
      ),
    );
  }
}
