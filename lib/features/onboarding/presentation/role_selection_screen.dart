import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/onboarding_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: Implement language toggle
            },
            icon: const Icon(Icons.language, size: 20),
            label: const Text('EN/AM'),
          ),
          const SizedBox(width: AppConstants.space16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              "Who's Using FEMA?",
              style: AppTextStyles.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space32),
            _RoleCard(
              title: "I'm a Student",
              subtitle: "Looking for engaging lessons and quizzes.",
              icon: Icons.school_outlined,
              role: UserRole.student,
              onTap: () {
                ref.read(onboardingProvider.notifier).setRole(UserRole.student);
                context.push('/onboarding/grade');
              },
            ),
            const SizedBox(height: AppConstants.space16),
            _RoleCard(
              title: "I'm a Parent",
              subtitle: "To monitor and support my child's progress.",
              icon: Icons.family_restroom_outlined,
              role: UserRole.parent,
              onTap: () {
                ref.read(onboardingProvider.notifier).setRole(UserRole.parent);
                ref.read(onboardingProvider.notifier).updateActiveChild(ChildProfile());
                context.push('/onboarding/parent-details');
              },
            ),
            const SizedBox(height: AppConstants.space16),
            _RoleCard(
              title: "I'm a Teacher",
              subtitle: "For creating courses and managing student progress.",
              icon: Icons.school_outlined,
              role: UserRole.teacher,
              onTap: () {
                ref.read(onboardingProvider.notifier).setRole(UserRole.teacher);
                context.push('/onboarding/teacher-experience');
              },
            ),
            const SizedBox(height: AppConstants.space16),
            _RoleCard(
              title: "I'm an Admin",
              subtitle: "For managing the system and inviting staff.",
              icon: Icons.admin_panel_settings_outlined,
              role: UserRole.admin,
              onTap: () {
                ref.read(onboardingProvider.notifier).setRole(UserRole.admin);
                context.push('/onboarding/admin-user-creation');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final UserRole role;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radius16),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.space20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radius16),
          border: Border.all(color: AppColors.greyLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.space12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppConstants.space20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.space4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
