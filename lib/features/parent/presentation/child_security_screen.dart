import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../onboarding/domain/onboarding_provider.dart';

class ChildSecurityScreen extends ConsumerWidget {
  const ChildSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(onboardingProvider).children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Secure Profiles'),
      ),
      body: children.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.space16),
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final child = children[index];
                return _ChildSecurityCard(child: child, index: index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(onboardingProvider.notifier).startAddingChild();
          context.push('/onboarding/child-secure');
        },
        label: const Text('Add Another Child'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_outlined, size: 64, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'No child profiles found',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _ChildSecurityCard extends ConsumerWidget {
  final ChildProfile child;
  final int index;

  const _ChildSecurityCard({required this.child, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  child.fullName?.substring(0, 1) ?? 'C',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName ?? 'Unnamed Child', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                    Text(child.grade ?? 'No grade', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _CredentialRow(label: 'Username', value: child.username ?? 'Not set'),
          const SizedBox(height: 8),
          _CredentialRow(label: 'Password', value: child.password ?? 'Not set', isPassword: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditDialog(context, ref),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Update Credentials'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final userController = TextEditingController(text: child.username);
    final passController = TextEditingController(text: child.password);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Credentials: ${child.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(onboardingProvider.notifier).updateChildCredentials(
                index,
                userController.text,
                passController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isPassword;

  const _CredentialRow({
    required this.label,
    required this.value,
    this.isPassword = false,
  });

  @override
  State<_CredentialRow> createState() => _CredentialRowState();
}

class _CredentialRowState extends State<_CredentialRow> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: AppTextStyles.bodySmall),
            Text(
              widget.isPassword && _obscured ? '••••••••' : widget.value,
              style: AppTextStyles.bodyMedium.copyWith(letterSpacing: widget.isPassword && _obscured ? 2 : 0),
            ),
          ],
        ),
        if (widget.isPassword)
          IconButton(
            icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
      ],
    );
  }
}
