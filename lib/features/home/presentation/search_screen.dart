import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../library/domain/library_provider.dart';
import '../../library/domain/models.dart';
import '../../../core/widgets/soft_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top row: back button + search pill
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left,
                        color: AppColors.textBody,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Search pill (active / focused)
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: (val) =>
                                  setState(() => _query = val),
                              style: GoogleFonts.figtree(
                                fontSize: 14,
                                color: AppColors.textBody,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search courses, subjects…',
                                hintStyle: GoogleFonts.figtree(
                                  color: AppColors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.grey,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body: results or empty state
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyState()
                  : _buildSearchResults(coursesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 40, color: AppColors.greyLight),
          const SizedBox(height: 12),
          Text(
            'Search for courses and subjects',
            style: GoogleFonts.figtree(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Course>> coursesAsync) {
    return coursesAsync.when(
      data: (courses) {
        final results = courses
            .where((c) =>
                c.title.toLowerCase().contains(_query.toLowerCase()) ||
                c.subject.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off,
                    size: 40, color: AppColors.greyLight),
                const SizedBox(height: 12),
                Text(
                  'No results for "$_query"',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                '${results.length} RESULTS',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: results.length,
                separatorBuilder: (context2, idx) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final course = results[index];
                  return _SearchResultCard(
                    course: course,
                    index: index,
                    onTap: () {
                      ref.read(selectedCourseProvider.notifier).state = course;
                      context.push('/library/course-details');
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error loading results',
          style: GoogleFonts.figtree(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
      ),
    );
  }
}

IconData _subjectIconForSearch(CourseSubject subject) {
  switch (subject) {
    case CourseSubject.math:
      return Icons.calculate;
    case CourseSubject.science:
      return Icons.science;
    case CourseSubject.english:
      return Icons.menu_book;
    case CourseSubject.amharic:
      return Icons.translate;
    case CourseSubject.socialStudies:
      return Icons.public;
    case CourseSubject.other:
      return Icons.school;
  }
}

class _SearchResultCard extends StatelessWidget {
  final Course course;
  final int index;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.course,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint =
        AppColors.subjectTints[index % AppColors.subjectTints.length];

    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          // Thumb
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              _subjectIconForSearch(course.subject),
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Info
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
                  'Grade ${course.grade} · ${course.lessons.length} lessons',
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
