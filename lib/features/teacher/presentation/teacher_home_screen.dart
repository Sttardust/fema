import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/subject_visuals.dart';
import '../../../core/widgets/capsule_tab_bar.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/domain/user_profile_repository.dart';
import '../../library/domain/library_provider.dart';
import '../domain/class_repository.dart';
import 'class_management_screen.dart';

// ─── Tab State Provider ───
final teacherTabProvider = StateProvider<int>((ref) => 0);

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(teacherTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          _TeacherDashboard(),
          ClassManagementScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CapsuleTabBar(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(teacherTabProvider.notifier).state = i,
        items: const [
          CapsuleTabItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          CapsuleTabItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Classes',
          ),
          CapsuleTabItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Teacher Dashboard ───
class _TeacherDashboard extends ConsumerWidget {
  const _TeacherDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final firstName = profile?.firstName ?? 'Teacher';
    final classesAsync = ref.watch(teacherClassesProvider);
    final coursesAsync = ref.watch(teacherCoursesProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $firstName \u{1F44B}',
                        style: GoogleFonts.figtree(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                      Text(
                        "Here's your teaching overview",
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: AppColors.grey,
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
            child: classesAsync.when(
              data: (classes) {
                final classCount = classes.length;
                final studentCount = classes.fold<int>(
                  0,
                  (sum, c) => sum + c.studentCount,
                );

                // Derive lessons count from teacherCoursesProvider
                final lessonsValue = coursesAsync.when(
                  data: (courses) {
                    final total = courses.fold<int>(
                      0,
                      (sum, c) => sum + c.lessons.length,
                    );
                    return '$total';
                  },
                  loading: () => '…',
                  error: (e, _) => '--',
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.school,
                          value: '$classCount',
                          label: 'Classes',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.people,
                          value: '$studentCount',
                          label: 'Students',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.menu_book_outlined,
                          value: lessonsValue,
                          label: 'Lessons',
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SizedBox(
                  height: 90,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SoftCard(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Couldn't load stats",
                          style: GoogleFonts.figtree(fontSize: 13, color: AppColors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(teacherClassesProvider),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── "Your classes" section header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'Your classes',
                style: GoogleFonts.figtree(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ),

          // ── Classes List ──
          SliverToBoxAdapter(
            child: classesAsync.when(
              data: (classes) {
                if (classes.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.school_outlined,
                    message: 'No classes yet',
                    action: PillButton(
                      label: 'Create a class',
                      onPressed: () {
                        ref.read(teacherTabProvider.notifier).state = 1;
                      },
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: List.generate(classes.length, (i) {
                      final cls = classes[i];
                      final tint = AppColors.subjectTints[i % AppColors.subjectTints.length]; // classes have no subject field
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          radius: 18,
                          padding: EdgeInsets.zero,
                          onTap: () {
                            ref.read(teacherTabProvider.notifier).state = 1;
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: tint,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cls.name,
                                        style: GoogleFonts.figtree(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textBody,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${cls.studentCount} students',
                                        style: GoogleFonts.figtree(
                                          fontSize: 12,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (error, _) => ErrorStateView(
                message: "Couldn't load classes",
                onRetry: () => ref.invalidate(teacherClassesProvider),
              ),
            ),
          ),

          // ── "My courses" section (only shown when there are courses) ──
          SliverToBoxAdapter(
            child: coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'My courses',
                        style: GoogleFonts.figtree(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                    // Horizontal scroll of course cards
                    SizedBox(
                      height: 172,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        itemCount: courses.length,
                        separatorBuilder: (context, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final course = courses[i];
                          final tint = subjectTint(course.subject);
                          return SoftCard(
                            radius: 18,
                            padding: const EdgeInsets.all(12),
                            onTap: () {
                              ref
                                  .read(selectedCourseProvider.notifier)
                                  .state = course;
                              context.push('/library/course-details');
                            },
                            child: SizedBox(
                              width: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Subject tile
                                  Container(
                                    height: 48,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: tint,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      subjectIcon(course.subject),
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Course title
                                  Text(
                                    course.title,
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textBody,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  // Lessons count
                                  Text(
                                    '${course.lessons.length} lessons',
                                    style: GoogleFonts.figtree(
                                      fontSize: 12,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SoftCard(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Couldn't load courses",
                          style: GoogleFonts.figtree(fontSize: 13, color: AppColors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(teacherCoursesProvider),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Tile ───
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
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 17,
            ),
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
