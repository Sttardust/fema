import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../library/domain/library_provider.dart';
import '../../library/domain/models.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textHeadline),
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (val) => setState(() => _query = val),
            decoration: const InputDecoration(
              hintText: 'Search for courses...',
              hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: AppColors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close, color: AppColors.grey),
            ),
        ],
      ),
      body: _query.isEmpty ? _buildRecentSearches() : _buildSearchResults(coursesAsync),
    );
  }

  Widget _buildRecentSearches() {
    final recentSearches = ['Mathematics', 'Science', 'English', 'Physics'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: recentSearches.map((s) => _SearchChip(
              label: s,
              onTap: () {
                _searchController.text = s;
                setState(() => _query = s);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Course>> coursesAsync) {
    return coursesAsync.when(
      data: (courses) {
        final results = courses.where((c) => 
          c.title.toLowerCase().contains(_query.toLowerCase()) || 
          c.subject.name.toLowerCase().contains(_query.toLowerCase())
        ).toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: AppColors.greyLight),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$_query"',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 32, color: AppColors.greyLight),
          itemBuilder: (context, index) {
            final course = results[index];
            return _SearchResultTile(
              course: course,
              onTap: () {
                ref.read(selectedCourseProvider.notifier).state = course;
                context.push('/library/course-details');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading results')),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SearchChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHeadline),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _SearchResultTile({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 60,
              color: AppColors.primaryLight,
              child: Image.network(
                course.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.school, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${course.subject.name} • Grade ${course.grade}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.greyLight),
        ],
      ),
    );
  }
}
