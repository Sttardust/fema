import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const AppLogo(width: 180),
              const SizedBox(height: AppConstants.space48),
              Text(
                'Welcome to FEMA',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space16),
              Text(
                'Empowering your learning journey with quality education for KG to Grade 12.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                text: 'Get Started',
                onPressed: () => context.push('/onboarding'),
              ),
              const SizedBox(height: AppConstants.space16),
              TextButton(
                onPressed: () => context.push('/login'),
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: AppTextStyles.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Log In',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space32),
            ],
          ),
        ),
      ),
    );
  }
}
