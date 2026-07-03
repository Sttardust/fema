import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../../library/presentation/library_screen.dart';
import '../../library/domain/library_provider.dart';
import '../../library/domain/models.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../auth/domain/auth_repository.dart';
import '../../profile/domain/user_profile_repository.dart';
import '../../../core/theme/subject_visuals.dart';
import '../../../core/widgets/capsule_tab_bar.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/state_views.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabProvider);
    final isGuest = ref.watch(authStateProvider).asData?.value == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (isGuest) const _GuestBanner(),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: const [
                _StudentHomePage(),
                LibraryScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CapsuleTabBar(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(homeTabProvider.notifier).state = i,
        items: const [
          CapsuleTabItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          CapsuleTabItem(
            icon: Icons.video_library_outlined,
            activeIcon: Icons.video_library,
            label: 'Library',
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

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "You're browsing as a guest. Sign up to save your progress.",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textBody,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/signup'),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
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

class _StudentHomePage extends ConsumerStatefulWidget {
  const _StudentHomePage();

  @override
  ConsumerState<_StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends ConsumerState<_StudentHomePage> {
  int _selectedChip = 0;

  static const _chips = ['All', 'Math', 'Science', 'English', 'Amharic'];

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final isGuest = ref.watch(authStateProvider).asData?.value == null;
    final profileAsync = ref.watch(currentUserProfileProvider);

    String firstName = 'there';
    if (!isGuest) {
      final profile = profileAsync.asData?.value;
      if (profile != null && (profile.firstName?.isNotEmpty ?? false)) {
        firstName = profile.firstName!;
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header row
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
                        child: isGuest
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'U',
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
                            isGuest
                                ? 'Hi there \u{1F44B}'
                                : 'Hi, $firstName \u{1F44B}',
                            style: GoogleFonts.figtree(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textBody,
                            ),
                          ),
                          Text(
                            'What will you learn today?',
                            style: GoogleFonts.figtree(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 2. Search pill
                  GestureDetector(
                    onTap: () => context.push('/home/search'),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Search courses, subjects…',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 4. Subject chips (horizontal scroll)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _chips.length,
                      separatorBuilder: (context2, idx) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final active = _selectedChip == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedChip = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: active
                                  ? null
                                  : Border.all(color: AppColors.greyLight),
                            ),
                            child: Text(
                              _chips[i],
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: active ? Colors.white : AppColors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 5. Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular courses',
                        style: GoogleFonts.figtree(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            ref.read(homeTabProvider.notifier).state = 1,
                        child: Text(
                          'See all',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 6. Course grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: coursesAsync.when(
            data: (courses) {
              final filtered = _selectedChip == 0
                  ? courses
                  : courses
                      .where((c) => _matchesChip(c, _selectedChip))
                      .toList();

              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyStateView(
                    icon: Icons.school_outlined,
                    message: 'No courses yet',
                  ),
                );
              }

              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course = filtered[index];
                    return _CourseGridCard(
                      course: course,
                      onTap: () {
                        ref.read(selectedCourseProvider.notifier).state =
                            course;
                        context.push('/library/course-details');
                      },
                    );
                  },
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: ErrorStateView(
                message: "Couldn't load courses",
                onRetry: () => ref.invalidate(coursesProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _matchesChip(Course course, int chipIndex) {
    switch (chipIndex) {
      case 1:
        return course.subject == CourseSubject.math;
      case 2:
        return course.subject == CourseSubject.science;
      case 3:
        return course.subject == CourseSubject.english;
      case 4:
        return course.subject == CourseSubject.amharic;
      default:
        return true;
    }
  }
}

class _CourseGridCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseGridCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = subjectTint(course.subject);

    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 88,
            width: double.infinity,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              subjectIcon(course.subject),
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(height: 10),

          // Title
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

          const SizedBox(height: 6),

          // Meta
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 14,
                color: AppColors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${course.lessons.length} lessons',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
