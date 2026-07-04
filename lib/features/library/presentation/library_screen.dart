import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/subject_visuals.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

// ── Subject filter chips state ───────────────────────────────────────────────
final _libraryChipProvider = StateProvider<int>((ref) => 0);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  static const _chips = ['All', 'Math', 'Science', 'English', 'Amharic'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final selectedChip = ref.watch(_libraryChipProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Library',
              style: GoogleFonts.figtree(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Search pill ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
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
                    Flexible(
                      child: Text(
                        'Search courses, subjects…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Subject filter chips ─────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (context2, idx) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = selectedChip == i;
                return GestureDetector(
                  onTap: () =>
                      ref.read(_libraryChipProvider.notifier).state = i,
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
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? Colors.white : AppColors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Course list ──────────────────────────────────────────────────
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                final filtered = selectedChip == 0
                    ? courses
                    : courses
                        .where((c) => _matchesChip(c, selectedChip))
                        .toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.school_outlined,
                    message: 'No courses yet',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (context2, idx) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return _LibraryCourseRow(
                      course: course,
                      onTap: () {
                        ref.read(selectedCourseProvider.notifier).state =
                            course;
                        context.push('/library/course-details');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => ErrorStateView(
                message: "Couldn't load courses",
                onRetry: () => ref.invalidate(coursesProvider),
              ),
            ),
          ),
        ],
      ),
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

// ── Course row card ───────────────────────────────────────────────────────────

class _LibraryCourseRow extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _LibraryCourseRow({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = subjectTint(course.subject);

    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          // Flat colour thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              subjectIcon(course.subject),
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 4),
                Text(
                  '${course.grade} · ${course.lessons.length} lessons',
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}
