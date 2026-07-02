import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const AppLogoLockup(),
                  const Spacer(),
                  _LanguagePill(),
                ],
              ),
              const SizedBox(height: 56),
              const Text(
                "Who's using FEMA today?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Select your role to personalize your learning experience.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _RoleCard(
                label: 'I am a Student',
                role: UserRole.student,
                selected: _selected == UserRole.student,
                onTap: () => setState(() => _selected = UserRole.student),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                label: 'I am a Teacher',
                role: UserRole.teacher,
                selected: _selected == UserRole.teacher,
                onTap: () => setState(() => _selected = UserRole.teacher),
              ),
              const Spacer(),
              AppButton(
                text: 'Continue',
                onPressed: (_selected == null || _isSubmitting) ? null : _onContinue,
                backgroundColor:
                    _selected == null ? AppColors.greyLight : AppColors.primary,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectionFill : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
            ),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.greyLight,
          width: selected ? 6 : 2,
        ),
        color: Colors.white,
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate, size: 16, color: AppColors.textHeadline),
          SizedBox(width: 6),
          Text(
            'English',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeadline,
            ),
          ),
        ],
      ),
    );
  }
}
