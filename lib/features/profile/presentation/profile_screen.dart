import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../onboarding/domain/onboarding_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Implement edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            _buildProfileHeader(state),
            const SizedBox(height: AppConstants.space32),
            _buildInfoSection(state),
            const SizedBox(height: AppConstants.space32),
            _buildSettingsSection(context),
            const SizedBox(height: AppConstants.space40),
            _buildLogoutButton(context),
            const SizedBox(height: AppConstants.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(OnboardingState state) {
    final initials = (state.firstName?.isNotEmpty == true ? state.firstName![0] : '') +
        (state.surName?.isNotEmpty == true ? state.surName![0] : '');

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            '${state.firstName ?? 'User'} ${state.surName ?? ''}',
            style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.space4),
          Text(
            state.role.name.toUpperCase(),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Information', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppConstants.space16),
          _buildInfoTile(Icons.email_outlined, 'Email', state.email ?? 'Not provided'),
          _buildInfoTile(Icons.phone_outlined, 'Phone', state.phone ?? 'Not provided'),
          if (state.school != null) _buildInfoTile(Icons.school_outlined, 'School', state.school!),
          if (state.grade != null) _buildInfoTile(Icons.grade_outlined, 'Grade', state.grade!),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 20),
          const SizedBox(width: AppConstants.space16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppConstants.space16),
          _buildSettingsTile(Icons.notifications_outlined, 'Notifications', () {}),
          _buildSettingsTile(Icons.language_outlined, 'Language', () {}),
          _buildSettingsTile(Icons.security_outlined, 'Privacy & Security', () {}),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
      child: OutlinedButton(
        onPressed: () => context.go('/'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
