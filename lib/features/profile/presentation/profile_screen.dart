import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/domain/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/soft_card.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const _ProfileGuestView();
          }
          return _ProfileBody(profile: profile);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}

// ─── Guest View ─────────────────────────────────────────────────────────────

class _ProfileGuestView extends StatelessWidget {
  const _ProfileGuestView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Profile',
              style: GoogleFonts.figtree(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 24),

            // Identity card — guest
            SoftCard(
              radius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Guest',
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Guest',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign in button
            PillButton(
              label: 'Sign in',
              onPressed: () => context.go('/signup'),
              icon: Icons.login,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Authenticated Body ──────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final AppUserProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = profile.fullName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final email = profile.email;
    final phone = profile.phone;
    final subtitle = email?.isNotEmpty == true
        ? email!
        : (phone?.isNotEmpty == true ? phone! : '');
    final roleBadge = _roleBadgeLabel(profile);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Text(
              'Profile',
              style: GoogleFonts.figtree(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 24),

            // ── Identity SoftCard ──
            SoftCard(
              radius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.figtree(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      roleBadge,
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── ACCOUNT group ──
            _GroupLabel('ACCOUNT'),
            const SizedBox(height: 10),
            SoftCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _NavRow(
                    icon: Icons.lock_outline,
                    label: 'Change password',
                    onTap: () => _showChangePasswordSheet(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Account management',
                    onTap: () => context.push('/profile/account-management'),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.card_membership_outlined,
                    label: 'Subscription',
                    onTap: () => _comingSoon(context, 'Subscription'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── APP group ──
            _GroupLabel('APP'),
            const SizedBox(height: 10),
            SoftCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _NavRow(
                    icon: Icons.info_outline,
                    label: 'About Us',
                    onTap: () => context.push('/profile/about'),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.help_outline,
                    label: 'Help',
                    onTap: () => _comingSoon(context, 'Help'),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.share_outlined,
                    label: 'Share the FEMA App',
                    onTap: () => _comingSoon(context, 'Share'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Sign out ──
            GestureDetector(
              onTap: () => _signOut(context, ref),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFF1D7D7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Sign out',
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleBadgeLabel(AppUserProfile p) {
    switch (p.role) {
      case UserRole.student:
        final grade = p.grade;
        return grade != null && grade.isNotEmpty ? 'Student · Grade $grade' : 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.admin:
        return 'Admin';
      case UserRole.parent:
        return 'Parent';
      case UserRole.none:
        return 'User';
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go('/');
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }

  Future<void> _showChangePasswordSheet(BuildContext context, WidgetRef ref) async {
    final email = profile.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email on file — contact support')),
      );
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send reset email: $e')),
      );
    }
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBody,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 62,
      endIndent: 16,
      color: AppColors.greyLight,
    );
  }
}
