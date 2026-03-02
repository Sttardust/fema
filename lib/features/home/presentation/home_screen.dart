import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../../library/presentation/library_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final role = state.role;
    final currentIndex = ref.watch(homeTabProvider);

    return Scaffold(
      appBar: currentIndex == 0 ? AppBar(
        title: const Text('FEMA Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push('/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Temporary logout/restart for testing
              context.go('/');
            },
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildDashboardByRole(context, role, state),
          const LibraryScreen(),
          const NotificationsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Alerts'),
        ],
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        onTap: (index) {
          ref.read(homeTabProvider.notifier).state = index;
        },
      ),
    );
  }

  Widget _buildDashboardByRole(BuildContext context, UserRole role, OnboardingState state) {
    switch (role) {
      case UserRole.student:
        return _StudentDashboard(state: state);
      case UserRole.parent:
        return _ParentDashboard(state: state);
      case UserRole.teacher:
        return _TeacherDashboard(state: state);
      case UserRole.admin:
        return _AdminDashboard(state: state);
      case UserRole.none:
      default:
        return const Center(child: Text('Welcome to FEMA! Please login or sign up.'));
    }
  }
}

class _StudentDashboard extends StatelessWidget {
  final OnboardingState state;
  const _StudentDashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${state.firstName ?? 'Student'}! 👋',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppConstants.space8),
          Text(
            'Ready to continue your learning journey?',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppConstants.space32),
          _DashboardCard(
            title: 'Daily Lessons',
            subtitle: 'Continue where you left off',
            icon: Icons.play_lesson_outlined,
            color: Colors.blue,
            onTap: () {
              ref.read(homeTabProvider.notifier).state = 1; // Go to Library
            },
          ),
          const SizedBox(height: AppConstants.space16),
          _DashboardCard(
            title: 'Practice Quiz',
            subtitle: 'Test your knowledge',
            icon: Icons.quiz_outlined,
            color: Colors.orange,
            onTap: () {
              context.push('/onboarding/quiz-intro');
            },
          ),
          const SizedBox(height: AppConstants.space16),
          _DashboardCard(
            title: 'My Progress',
            subtitle: 'View your achievements',
            icon: Icons.trending_up,
            color: Colors.green,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ParentDashboard extends StatelessWidget {
  final OnboardingState state;
  const _ParentDashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parent Dashboard',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppConstants.space8),
          Text(
            'Monitoring ${state.children.length} children',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppConstants.space32),
          ...state.children.map((child) => Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.space16),
                child: _DashboardCard(
                  title: child.fullName ?? 'Child',
                  subtitle: 'Grade: ${child.grade}',
                  icon: Icons.child_care,
                  color: AppColors.primary,
                  onTap: () {},
                ),
              )),
          _DashboardActionCard(
            title: 'Add Another Child',
            icon: Icons.add_circle_outline,
            onTap: () {
              ref.read(onboardingProvider.notifier).startAddingChild();
              context.push('/onboarding/child-secure');
            },
          ),
          const SizedBox(height: AppConstants.space16),
          _DashboardActionCard(
            title: 'Secure Profiles',
            icon: Icons.security_outlined,
            onTap: () {
              context.push('/parent/security');
            },
          ),
        ],
      ),
    );
  }
}

class _TeacherDashboard extends StatelessWidget {
  final OnboardingState state;
  const _TeacherDashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Dashboard',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppConstants.space8),
          Text(
            'Managing ${state.teachingGrades.join(', ')}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppConstants.space32),
          _DashboardCard(
            title: 'My Classes',
            subtitle: 'Manage your students',
            icon: Icons.group_outlined,
            color: Colors.purple,
            onTap: () {
               context.push('/teacher/classes');
            },
          ),
          const SizedBox(height: AppConstants.space16),
          _DashboardCard(
            title: 'Course Content',
            subtitle: 'Create and edit lessons',
            icon: Icons.library_books_outlined,
            color: Colors.teal,
            onTap: () {
              ref.read(homeTabProvider.notifier).state = 1; // Go to Library
            },
          ),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final OnboardingState state;
  const _AdminDashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Console',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppConstants.space32),
          _DashboardCard(
            title: 'User Management',
            subtitle: 'Invite and manage users',
            icon: Icons.manage_accounts_outlined,
            color: Colors.blueGrey,
            onTap: () {
              context.push('/admin/management');
            },
          ),
          const SizedBox(height: AppConstants.space16),
          _DashboardCard(
            title: 'System Analytics',
            subtitle: 'Track app usage and performance',
            icon: Icons.analytics_outlined,
            color: Colors.indigo,
            onTap: () {
              context.push('/admin/analytics');
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
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
              color: color.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.grey),
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

class _DashboardActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(AppConstants.space16),
        minimumSize: const Size(double.infinity, 80),
        side: const BorderSide(color: AppColors.primary, style: BorderStyle.dashed),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppConstants.space12),
          Text(title, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
