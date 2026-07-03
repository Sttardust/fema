import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/domain/auth_repository.dart';
import '../../library/domain/library_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ──
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin console',
                        style: GoogleFonts.figtree(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                      Text(
                        'FEMA platform overview',
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Stats Row (published courses count only — real data) ──
              coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) return const SizedBox.shrink();
                  final totalLessons = courses.fold<int>(
                    0,
                    (sum, c) => sum + c.lessons.length,
                  );
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.menu_book_outlined,
                              value: '${courses.length}',
                              label: 'Courses',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.play_lesson_outlined,
                              value: '$totalLessons',
                              label: 'Lessons',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),

              // ── MANAGEMENT group ──
              Text(
                'MANAGEMENT',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              SoftCard(
                radius: 18,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _NavRow(
                      icon: Icons.people_outline,
                      label: 'Manage users',
                      onTap: () => context.push('/admin/users'),
                    ),
                    const _RowDivider(),
                    _NavRow(
                      icon: Icons.analytics_outlined,
                      label: 'Analytics',
                      onTap: () => context.push('/admin/analytics'),
                    ),
                    const _RowDivider(),
                    _NavRow(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Info note ──
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin accounts are provisioned via the bootstrap script. '
                        'Content is seeded from the Firebase console in the MVP.',
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
              const SizedBox(height: 24),

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
      ),
    );
  }
}

// ─── Stat Tile ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.figtree(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 11.5,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Row ─────────────────────────────────────────────────────────────────

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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

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
