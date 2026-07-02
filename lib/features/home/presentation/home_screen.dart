import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import '../../library/presentation/library_screen.dart';
import '../../library/domain/library_provider.dart';
import '../../library/domain/models.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../auth/domain/auth_repository.dart';
import '../../../core/widgets/app_logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabProvider);
    final isGuest = ref.watch(authStateProvider).asData?.value == null;

    return Scaffold(
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => ref.read(homeTabProvider.notifier).state = 0,
                ),
                _NavBarItem(
                  icon: Icons.laptop_mac_outlined,
                  activeIcon: Icons.laptop_mac,
                  label: 'My Courses',
                  isActive: currentIndex == 1,
                  onTap: () => ref.read(homeTabProvider.notifier).state = 1,
                ),
                _NavBarItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: currentIndex == 2,
                  onTap: () => ref.read(homeTabProvider.notifier).state = 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
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
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "You're browsing as a guest. Sign up to save your progress.",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/signup'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _StudentHomePage extends ConsumerWidget {
  const _StudentHomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return CustomScrollView(
      slivers: [
        // Purple header: FEMA lockup + search field
        SliverToBoxAdapter(
          child: _HomePurpleHeader(
            onSearchTap: () => context.push('/home/search'),
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: _FilterChipsRow(),
        ),

          // Recommended Courses section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended courses',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(homeTabProvider.notifier).state = 1,
                    child: Text(
                      'View all',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recommended Courses Carousel
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return _buildPlaceholderCards();
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: courses.length,
                    itemBuilder: (context, index) => _CourseCard(
                      course: courses[index],
                      onTap: () {
                        ref.read(selectedCourseProvider.notifier).state = courses[index];
                        context.push('/library/course-details');
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildPlaceholderCards(),
              ),
            ),
          ),

          // New section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(homeTabProvider.notifier).state = 1,
                    child: Text(
                      'View all',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // New Courses Horizontal List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return _buildPlaceholderCards();
                  }
                  // Show reversed list as "new" for demo
                  final newCourses = courses.reversed.toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: newCourses.length,
                    itemBuilder: (context, index) => _CourseCard(
                      course: newCourses[index],
                      onTap: () {
                        ref.read(selectedCourseProvider.notifier).state = newCourses[index];
                        context.push('/library/course-details');
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildPlaceholderCards(),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildPlaceholderCards() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) => const _PlaceholderCourseCard(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: AppColors.primaryDark,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      course.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryDark,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                course.grade.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                course.subject.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play button overlay
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Educators',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Get guidance from Ethiopia's best teachers.",
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _HomePurpleHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  const _HomePurpleHeader({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  AppLogoLockup(color: Colors.white),
                  Spacer(),
                  Icon(Icons.notifications_none,
                      color: Colors.white, size: 26),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.grey, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search for courses',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.tune, color: AppColors.grey, size: 22),
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

class _FilterChipsRow extends StatefulWidget {
  @override
  State<_FilterChipsRow> createState() => _FilterChipsRowState();
}

class _FilterChipsRowState extends State<_FilterChipsRow> {
  static const _filters = ['All', 'Recommended', 'Tutorials', 'By Grade', 'By Subject'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.greyLight,
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textHeadline,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceholderCourseCard extends StatelessWidget {
  const _PlaceholderCourseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppColors.primaryDark,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ONLINE COURSE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Icon(Icons.play_circle_outline, color: Colors.white54, size: 28),
                  ],
                ),
              ),
            ),
          ),
          // Info placeholder
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Educators',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Get guidance from Ethiopia's best teachers.",
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
