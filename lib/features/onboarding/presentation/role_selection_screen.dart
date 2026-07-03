import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../domain/onboarding_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selected;
  bool _isSubmitting = false;

  void _onContinue() async {
    if (_isSubmitting) return;
    final picked = _selected;
    if (picked == null) return;
    setState(() => _isSubmitting = true);
    try {
      ref.read(onboardingProvider.notifier).setRole(picked);

      switch (picked) {
        case UserRole.student:
          context.push('/onboarding/grade');
          break;
        case UserRole.teacher:
          await ref.read(onboardingProvider.notifier).completeOnboarding();
          if (mounted) context.go('/teacher/home');
          break;
        case UserRole.parent:
        case UserRole.admin:
        case UserRole.none:
          break;
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Who are you?',
                style: GoogleFonts.figtree(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role so we can set up the right experience for you.',
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _RoleCard(
                label: 'I am a Student',
                description: 'Browse courses, watch lessons, and track your progress.',
                icon: Icons.backpack_outlined,
                role: UserRole.student,
                selected: _selected == UserRole.student,
                onTap: () => setState(() => _selected = UserRole.student),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                label: 'I am a Teacher',
                description: 'Manage your classes, students, and attendance.',
                icon: Icons.co_present_outlined,
                role: UserRole.teacher,
                selected: _selected == UserRole.teacher,
                onTap: () => setState(() => _selected = UserRole.teacher),
              ),
              const Spacer(),
              PillButton(
                label: 'Continue',
                onPressed: (_selected == null || _isSubmitting) ? null : _onContinue,
                enabled: _selected != null && !_isSubmitting,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon tile
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            // Label + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.figtree(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.figtree(
                      fontSize: 12.5,
                      color: AppColors.grey,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing state icon
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? AppColors.primary : AppColors.greyLight,
            ),
          ],
        ),
      ),
    );
  }
}
