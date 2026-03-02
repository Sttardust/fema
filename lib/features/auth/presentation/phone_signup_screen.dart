import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class PhoneSignupScreen extends ConsumerStatefulWidget {
  const PhoneSignupScreen({super.key});

  @override
  ConsumerState<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends ConsumerState<PhoneSignupScreen> {
  final _phoneController = TextEditingController();

  void _onVerify() {
    if (_phoneController.text.length >= 9) {
      context.push('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Your Phone Number',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              'We will send a 6-digit code to verify your number.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space40),
            Row(
              children: [
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  child: Text(
                    '+251',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: AppTextField(
                    controller: _phoneController,
                    hintText: '912345678',
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppButton(
              text: 'Send Code',
              onPressed: _onVerify,
            ),
            const SizedBox(height: AppConstants.space32),
          ],
        ),
      ),
    );
  }
}
