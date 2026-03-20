import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../library/domain/library_provider.dart';
import '../../library/domain/models.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/domain/user_profile_repository.dart';
import 'class_management_screen.dart';

// ─── Tab State Provider ───
final teacherTabProvider = StateProvider<int>((ref) => 0);

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(teacherTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          _TeacherDashboard(),
          ClassManagementScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _TeacherNavBar(currentIndex: currentIndex, ref: ref),
    );
  }
}

class _TeacherNavBar extends StatelessWidget {
  final int currentIndex;
  final WidgetRef ref;
  const _TeacherNavBar({required this.currentIndex, required this.ref});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      (icon: Icons.class_outlined, activeIcon: Icons.class_, label: 'My Classes'),
      (icon: Icons.notifications_none_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = currentIndex == i;
              return InkWell(
                onTap: () => ref.read(teacherTabProvider.notifier).state = i,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        color: isActive ? AppColors.primary : AppColors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? AppColors.primary : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Teacher Dashboard Tab ───
class _TeacherDashboard extends ConsumerWidget {
  const _TeacherDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final firstName = profile?.firstName ?? 'Teacher';
    final coursesAsync = ref.watch(teacherCoursesProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Top Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $firstName 👋', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                      Text("Let's inspire today!", style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, size: 26, color: AppColors.textHeadline),
                        onPressed: () => ref.read(teacherTabProvider.notifier).state = 2,
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Stats Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(child: _StatCard(title: 'Active Courses', value: '4', icon: Icons.menu_book_outlined, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Total Students', value: '124', icon: Icons.people_outline, color: Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Avg Rating', value: '4.8', icon: Icons.star_outline, color: Colors.amber)),
                ],
              ),
            ),
          ),

          // ── Create Course CTA ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: GestureDetector(
                onTap: () => context.push('/teacher/editor'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start a New Course', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Share your expertise with students nationwide.', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: Text('Create Course', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Image.asset(
                        'assets/images/Teacher/Course creation/first time.png',
                        height: 90,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.add_circle_outline, size: 80, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── My Courses Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Courses', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => ref.read(teacherTabProvider.notifier).state = 1,
                    child: Text('Manage', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: coursesAsync.when(
                data: (courses) => courses.isEmpty
                    ? const Center(child: Text('No courses yet. Create your first!'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: courses.length,
                        itemBuilder: (context, index) => _TeacherCourseCard(
                          course: courses[index],
                          students: 30 + index * 5,
                          onTap: () {
                            ref.read(selectedCourseProvider.notifier).state = courses[index];
                            context.push('/library/course-details');
                          },
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Could not load courses')),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Stat Card ───
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headlineSmall.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Teacher Course Card ───
class _TeacherCourseCard extends StatelessWidget {
  final Course course;
  final int students;
  final VoidCallback onTap;
  const _TeacherCourseCard({required this.course, required this.students, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 105,
                color: AppColors.primaryDark,
                child: Image.network(
                  course.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      course.subject.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 13, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text('$students students', style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
