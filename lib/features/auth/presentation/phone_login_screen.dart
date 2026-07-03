import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pill_text_field.dart';
import '../domain/auth_repository.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = '+251${_phoneController.text}';

      await ref.read(authRepositoryProvider).verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          context.push(
            '/otp',
            extra: {
              'verificationId': verificationId,
              'redirectPath': '/',
            },
          );
        },
        verificationFailed: (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.space24,
            vertical: AppConstants.space24,
          ),
          child: Form(
            key: _formKey,
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
                  'Continue with phone',
                  style: GoogleFonts.figtree(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll send a one-time code to verify your number.",
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Phone input row: country pill + number field
                Row(
                  children: [
                    // Fixed country pill
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇪🇹', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '+251',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Phone number field (focused = primary border)
                    Expanded(
                      child: PillTextField(
                        hint: 'Phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        focused: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Send code button
                PillButton(
                  label: 'Send code',
                  onPressed: _onLogin,
                ),
                const SizedBox(height: 20),
                // Info note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Standard SMS rates may apply. The code expires after 10 minutes.',
                          style: GoogleFonts.figtree(
                            fontSize: 12.5,
                            color: AppColors.textBody,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
