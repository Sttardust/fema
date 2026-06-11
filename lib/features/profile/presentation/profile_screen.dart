import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const _ProfileGuestView();
          }
          return _ProfileBody(profile: profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}

class _ProfileGuestView extends StatelessWidget {
  const _ProfileGuestView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PurpleHeader(title: 'Profile'),
        const SizedBox(height: 80),
        const Icon(Icons.person_outline, size: 64, color: AppColors.grey),
        const SizedBox(height: 16),
        const Text(
          "You're browsing as a guest.",
          style: TextStyle(fontSize: 16, color: AppColors.textHeadline),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Create an account to track your progress and save lessons.',
            style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 220,
          child: ElevatedButton(
            onPressed: () => context.go('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Sign Up',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final AppUserProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PurpleHeader(title: 'Profile Settings'),
          const SizedBox(height: 32),
          Center(child: _Avatar(profile: profile)),
          const SizedBox(height: 36),
          _SectionHeader(
            title: 'Personal Information',
            trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textHeadline),
            onTrailingTap: () {},
          ),
          _ReadOnlyRow(label: 'Full Name', value: profile.fullName),
          const SizedBox(height: 8),
          _ReadOnlyRow(label: 'Email', value: profile.email ?? '—'),
          const SizedBox(height: 8),
          _ReadOnlyRow(label: 'Phone Number', value: profile.phone ?? '—'),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Security'),
          _NavRow(label: 'Change Password', onTap: () => _showChangePasswordSheet(context, ref)),
          const SizedBox(height: 8),
          _NavRow(label: 'Account Management', onTap: () => context.push('/profile/account-management')),
          const SizedBox(height: 8),
          _NavRow(label: 'Subscription', onTap: () => _comingSoon(context, 'Subscription')),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Notifications'),
          _ToggleRow(
            label: 'Notifications',
            value: true,
            onChanged: (v) {},
          ),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Help and Support'),
          _NavRow(label: 'About Us', onTap: () => context.push('/profile/about')),
          const SizedBox(height: 8),
          _NavRow(label: 'Help', onTap: () => _comingSoon(context, 'Help')),
          const SizedBox(height: 8),
          _NavRow(label: 'Share the FEMA App', onTap: () => _comingSoon(context, 'Share')),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => _signOut(context, ref),
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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

class _PurpleHeader extends StatelessWidget {
  final String title;
  const _PurpleHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(
            children: [
              const AppLogoLockup(color: Colors.white),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.search, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUserProfile profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greyLight),
            ),
            child: const Icon(Icons.person, size: 64, color: AppColors.accent),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.greyLight),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textHeadline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  const _SectionHeader({required this.title, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            GestureDetector(onTap: onTrailingTap, child: trailing!),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.grey, fontSize: 14),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textHeadline,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textHeadline,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHeadline,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
