import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/auth_repository.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: AppTextStyles.headlineMedium,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              'Verification Code',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              'Enter the 6-digit code sent to your phone.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space48),
            Pinput(
              length: 6,
              controller: pinController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              ),
              onCompleted: (pin) async {
                try {
                  final credential = PhoneAuthProvider.credential(
                    verificationId: widget.verificationId,
                    smsCode: pin,
                  );
                  await ref.read(authRepositoryProvider).signInWithCredential(credential);
                  if (context.mounted) {
                    context.push('/onboarding/details');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid code. Please try again.')),
                  );
                }
              },
            ),
            const Spacer(),
            AppButton(
              text: 'Verify & Continue',
              onPressed: () async {
                if (pinController.text.length == 6) {
                  try {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: widget.verificationId,
                      smsCode: pinController.text,
                    );
                    await ref.read(authRepositoryProvider).signInWithCredential(credential);
                    if (context.mounted) {
                      context.push('/onboarding/details');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid code. Please try again.')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppConstants.space16),
            TextButton(
              onPressed: () {},
              child: const Text('Resend Code'),
            ),
            const SizedBox(height: AppConstants.space32),
          ],
        ),
      ),
    );
  }
}
