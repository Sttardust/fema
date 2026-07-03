import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pill_text_field.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../domain/auth_repository.dart';

class EmailSignupScreen extends ConsumerStatefulWidget {
  const EmailSignupScreen({super.key});

  @override
  ConsumerState<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends ConsumerState<EmailSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _onSignUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authRepositoryProvider).signUpWithEmail(
          _emailController.text,
          _passwordController.text,
        );

        // Split "Full name" into firstName / surName on the first space.
        final fullName = _nameController.text.trim();
        final spaceIndex = fullName.indexOf(' ');
        final firstName = spaceIndex == -1 ? fullName : fullName.substring(0, spaceIndex).trim();
        final surName = spaceIndex == -1 ? null : fullName.substring(spaceIndex + 1).trim();

        ref.read(onboardingProvider.notifier).updatePersonalDetails(
          firstName: firstName.isNotEmpty ? firstName : null,
          surName: (surName != null && surName.isNotEmpty) ? surName : null,
          email: _emailController.text,
        );

        if (mounted) {
          // After signup, pick role first (matches design); role selection
          // then routes to the role-specific onboarding step.
          context.push('/onboarding');
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left,
                        color: AppColors.textBody,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Headline
                Text(
                  'Create your account',
                  style: GoogleFonts.figtree(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start learning in minutes. It's free.",
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Full name
                PillTextField(
                  hint: 'Full name',
                  icon: Icons.person_outline,
                  controller: _nameController,
                ),
                const SizedBox(height: 14),
                // Email
                PillTextField(
                  hint: 'Email address',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                // Password
                _PasswordField(
                  hint: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 14),
                // Confirm password
                _PasswordField(
                  hint: 'Confirm password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Terms line
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Create account button
                PillButton(
                  label: 'Create account',
                  onPressed: _onSignUp,
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.greyLight, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: GoogleFonts.figtree(fontSize: 12, color: AppColors.grey),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.greyLight, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Phone sign-up
                PillButton.outlined(
                  label: 'Sign up with phone',
                  icon: Icons.smartphone,
                  onPressed: () => context.pushReplacement('/signup-phone'),
                ),
                const SizedBox(height: 24),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.figtree(fontSize: 13, color: AppColors.grey),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Sign in',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final FormFieldValidator<String>? validator;

  const _PasswordField({
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: field.hasError ? AppColors.error : AppColors.greyLight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 18, color: AppColors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      obscureText: obscureText,
                      onChanged: (_) => field.didChange(controller.text),
                      style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
                      decoration: InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  field.errorText!,
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
