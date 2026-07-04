import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../library/domain/library_provider.dart';
import '../../../library/domain/models.dart';
import '../domain/course_editor_repository.dart';
import '../domain/lesson_upload_controller.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(teacherCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left,
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/teacher/home');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: coursesAsync.when(
                      data: (courses) {
                        final total = courses.length;
                        final drafts =
                            courses.where((c) => c.status == CourseStatus.draft).length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My courses',
                              style: GoogleFonts.figtree(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textBody,
                              ),
                            ),
                            Text(
                              '$total course${total == 1 ? '' : 's'} · $drafts draft${drafts == 1 ? '' : 's'}',
                              style: GoogleFonts.figtree(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Text(
                        'My courses',
                        style: GoogleFonts.figtree(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                      error: (e, st) => Text(
                        'My courses',
                        style: GoogleFonts.figtree(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "New course" pill button — 40h
                  SizedBox(
                    height: 40,
                    child: _NewCoursePillButton(
                      onPressed: () => context.push('/teacher/course/new'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Body
              Expanded(
                child: coursesAsync.when(
                  data: (courses) {
                    if (courses.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.school_outlined,
                        message: 'No courses yet',
                        action: PillButton(
                          label: 'New course',
                          onPressed: () => context.push('/teacher/course/new'),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: courses.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final course = courses[i];
                        return _CourseRow(
                          course: course,
                          isBusy: _isBusy,
                          onBusyChanged: (v) => setState(() => _isBusy = v),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, st) => ErrorStateView(
                    message: "Couldn't load your courses",
                    onRetry: () => ref.invalidate(teacherCoursesProvider),
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

// ─── Inline pill-shaped "New course" button (compact height) ───
class _NewCoursePillButton extends StatelessWidget {
  const _NewCoursePillButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(27),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'New course',
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Course Row Card ───
class _CourseRow extends ConsumerWidget {
  const _CourseRow({
    required this.course,
    required this.isBusy,
    required this.onBusyChanged,
  });

  final Course course;
  final bool isBusy;
  final ValueChanged<bool> onBusyChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tint = subjectTint(course.subject);
    final isPublished = course.status == CourseStatus.published;

    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/teacher/course/${course.id}'),
      child: Row(
        children: [
          // Subject thumbnail
          Container(
            width: 56,
            height: 56,
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
          // Title + meta
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${course.lessons.length} lesson${course.lessons.length == 1 ? '' : 's'} · ${course.grade}',
                        style: GoogleFonts.figtree(
                          fontSize: 11.5,
                          color: AppColors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(isPublished: isPublished),
                  ],
                ),
              ],
            ),
          ),
          // More menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16, color: AppColors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) => _handleMenu(context, ref, value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: isPublished ? 'unpublish' : 'publish',
                child: Text(isPublished ? 'Unpublish' : 'Publish'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenu(
      BuildContext context, WidgetRef ref, String action) async {
    if (isBusy) return;

    switch (action) {
      case 'edit':
        context.push('/teacher/course/${course.id}');
        break;

      case 'publish':
      case 'unpublish':
        final publish = action == 'publish';
        onBusyChanged(true);
        try {
          await ref
              .read(courseEditorRepositoryProvider)
              .setStatus(course.id, publish);
          ref.invalidate(teacherCoursesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      publish ? 'Course published' : 'Course unpublished')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Couldn't update course status. Try again.")),
            );
          }
        } finally {
          onBusyChanged(false);
        }
        break;

      case 'delete':
        final confirmed = await _showDeleteDialog(context, course);
        if (confirmed != true) break;

        onBusyChanged(true);
        try {
          // Fetch lessons fresh so media added after the list loaded is included.
          final lessons = await ref
              .read(firestoreServiceProvider)
              .getLessons(course.id);
          for (final lesson in lessons) {
            final videoUrl = lesson['videoUrl'] as String?;
            final documentUrl = lesson['documentUrl'] as String?;
            if (videoUrl != null) await LessonUploadController.deleteByUrl(videoUrl);
            if (documentUrl != null) await LessonUploadController.deleteByUrl(documentUrl);
          }
          await ref
              .read(courseEditorRepositoryProvider)
              .deleteCourse(course.id);
          ref.invalidate(teacherCoursesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Course deleted')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Something went wrong. Please try again.")),
            );
          }
        } finally {
          onBusyChanged(false);
        }
        break;
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context, Course course) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete course?',
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                course.status == CourseStatus.published
                    ? 'Students will lose access and all lessons and files are removed. This cannot be undone.'
                    : 'All lessons and files are removed. This cannot be undone.',
                style: GoogleFonts.figtree(
                  fontSize: 13.5,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Chip ───
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final bg = isPublished
        ? const Color(0xFFE6F7F0)
        : const Color(0xFFFBF3E2);
    final fg = isPublished
        ? const Color(0xFF2BB37A)
        : const Color(0xFFB97F1F);
    final label = isPublished ? 'Published' : 'Draft';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.figtree(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
