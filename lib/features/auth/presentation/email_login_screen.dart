import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pill_text_field.dart';
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
  bool _obscurePassword = true;

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authRepositoryProvider).signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );

        if (mounted) {
          context.go('/');
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                const SizedBox(height: 16),
                // Icon tile
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primaryShadow,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.school, size: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                // Headline
                Text(
                  'Welcome to FEMA',
                  style: GoogleFonts.figtree(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBody,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn anywhere, anytime. Sign in to continue your journey.',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Email field
                PillTextField(
                  hint: 'Email address',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                // Password field
                _PasswordField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 8),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      if (!email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter your email first')),
                        );
                        return;
                      }

                      try {
                        await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent')),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reset failed: $error')),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Sign in button
                PillButton(
                  label: 'Sign in',
                  onPressed: _onLogin,
                ),
                const SizedBox(height: 24),
                // Divider row
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.greyLight, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.greyLight, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Phone sign-in
                PillButton.outlined(
                  label: 'Continue with phone',
                  icon: Icons.smartphone,
                  onPressed: () => context.push('/login-phone'),
                ),
                const SizedBox(height: 20),
                // Guest browse
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Browse as guest',
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: AppColors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Footer: New here? Create account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New here? ',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: Text(
                        'Create an account',
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

/// Password field with visibility toggle, wrapping PillTextField visually
/// but adding an eye-icon suffix button while keeping obscureText behavior.
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: AppColors.greyLight),
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
              style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
              decoration: InputDecoration.collapsed(
                hintText: 'Password',
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
    );
  }
}
