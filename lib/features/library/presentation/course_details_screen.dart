import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

class CourseDetailsScreen extends ConsumerWidget {
  const CourseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(selectedCourseProvider);

    if (course == null) {
      return const Scaffold(body: Center(child: Text('No course selected')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, course),
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.space20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCourseInfo(course),
                const SizedBox(height: AppConstants.space32),
                Text(
                  'Lessons (${course.lessons.length})',
                  style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.space16),
                _buildLessonList(ref, course),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, course),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Course course) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              course.thumbnailUrl,
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.3)),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildCourseInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                course.subject.name.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              course.grade,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.space12),
        Text(
          course.title,
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.space12),
        Text(
          course.description,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildLessonList(WidgetRef ref, Course course) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: course.lessons.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final lesson = course.lessons[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lesson.isCompleted ? AppColors.primary : AppColors.greyLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: lesson.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          title: Text(
            lesson.title,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${lesson.durationMinutes} min • ${lesson.description}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.play_circle_outline, color: AppColors.primary),
          onTap: () {
            ref.read(selectedLessonProvider.notifier).state = lesson;
            ref.read(selectedCourseProvider.notifier).state = course;
            Navigator.of(ref.context).push(
              MaterialPageRoute(builder: (context) => const LessonViewerScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, Course course) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space20),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Start first lesson
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Enroll Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
class LessonViewerScreen extends ConsumerWidget {
  const LessonViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(selectedLessonProvider);

    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('No lesson selected')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
      ),
      body: Column(
        children: [
          // Placeholder for video player
          Container(
            height: 240,
            width: double.infinity,
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 60),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.space8),
                  Text(
                    '${lesson.durationMinutes} minutes duration',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                  ),
                  const Divider(height: 48),
                  Text(
                    'Lesson Content',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.space16),
                  Text(
                    lesson.description,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppConstants.space24),
                  const Text(
                    'In this lesson, we will explore the fundamental concepts related to this topic. Make sure to take notes as you watch the video and try the exercises at the end.',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppConstants.space16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Mark lesson as completed and go to next
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Complete & Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
