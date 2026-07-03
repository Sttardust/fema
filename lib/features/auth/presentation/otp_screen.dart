import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../domain/auth_repository.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String redirectPath;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.redirectPath,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final pinController = TextEditingController();

  Future<void> _verify(String pin) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: pin,
    );
    try {
      await ref.read(authRepositoryProvider).signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Please try again.')),
        );
      }
      return;
    }
    if (mounted) {
      context.go(widget.redirectPath);
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Base pin box style
    final defaultPinTheme = PinTheme(
      width: double.infinity,
      height: 58,
      textStyle: GoogleFonts.figtree(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textBody,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight, width: 1.0),
      ),
    );

    // Focused (cursor active) box
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    // Box with a digit entered (same as focused but without needing focus)
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.space24,
            vertical: AppConstants.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.pop(),
                ),
              ),
              const SizedBox(height: 28),
              // Title
              Text(
                'Verify your number',
                style: GoogleFonts.figtree(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to your phone.',
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // 6-box OTP input — each box Expanded via mainAxisSize in Pinput
              Pinput(
                length: 6,
                controller: pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                // Make all 6 boxes fill available width equally
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                onCompleted: (pin) => _verify(pin),
              ),
              const Spacer(),
              // Resend row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't get the code? ",
                    style: GoogleFonts.figtree(fontSize: 13, color: AppColors.grey),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                    ),
                    child: Text(
                      'Resend',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Verify button
              PillButton(
                label: 'Verify',
                onPressed: () {
                  if (pinController.text.length == 6) {
                    _verify(pinController.text);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
