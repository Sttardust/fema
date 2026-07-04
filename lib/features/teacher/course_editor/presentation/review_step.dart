import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../library/domain/library_provider.dart';
import '../../../library/domain/models.dart';
import '../domain/course_editor_repository.dart';
import '../domain/lesson_upload_controller.dart';

// ---------------------------------------------------------------------------
// Subject label helper
// ---------------------------------------------------------------------------

String _subjectLabel(CourseSubject subject) {
  switch (subject) {
    case CourseSubject.math:
      return 'Math';
    case CourseSubject.science:
      return 'Science';
    case CourseSubject.english:
      return 'English';
    case CourseSubject.socialStudies:
      return 'Social Studies';
    case CourseSubject.amharic:
      return 'Amharic';
    case CourseSubject.other:
      return 'Other';
  }
}

// ---------------------------------------------------------------------------
// ReviewStep
// ---------------------------------------------------------------------------

class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Ensure the teacher courses provider is fresh so a newly-created draft
    // shows up in the summary card. (Safe to call even if already loaded.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(teacherCoursesProvider);
    });
  }

  // ─── Publish / Unpublish ───────────────────────────────────────────────────

  Future<void> _setStatus(bool publish) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(courseEditorRepositoryProvider)
          .setStatus(widget.courseId, publish);
      ref.invalidate(teacherCoursesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Course published' : 'Course unpublished'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't update course status. Try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(Course? course) async {
    if (_busy) return;

    final isPublished = course?.status == CourseStatus.published;
    final confirmed = await _showDeleteDialog(isPublished: isPublished);
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      // Fetch lessons for media cleanup.
      final lessons = await ref
          .read(firestoreServiceProvider)
          .getLessons(widget.courseId);

      for (final lesson in lessons) {
        final videoUrl = lesson['videoUrl'] as String?;
        final documentUrl = lesson['documentUrl'] as String?;
        if (videoUrl != null) await LessonUploadController.deleteByUrl(videoUrl);
        if (documentUrl != null) {
          await LessonUploadController.deleteByUrl(documentUrl);
        }
      }

      await ref
          .read(courseEditorRepositoryProvider)
          .deleteCourse(widget.courseId);
      ref.invalidate(teacherCoursesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted')),
        );
        context.go('/teacher/courses');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showDeleteDialog({required bool? isPublished}) {
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
                isPublished == true
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(teacherCoursesProvider);
    final lessonsAsync = ref.watch(courseEditorLessonsProvider(widget.courseId));

    final course = coursesAsync.whenData(
      (list) => list.where((c) => c.id == widget.courseId).firstOrNull,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary card ──────────────────────────────────────────────────
          _buildSummaryCard(course),

          const SizedBox(height: 16),

          // ── Checklist card ────────────────────────────────────────────────
          _buildChecklistCard(lessonsAsync, course),

          const SizedBox(height: 16),

          // ── Status card ───────────────────────────────────────────────────
          _buildStatusCard(lessonsAsync, course),

          const SizedBox(height: 16),

          // ── Danger row ────────────────────────────────────────────────────
          _buildDangerRow(course),
        ],
      ),
    );
  }

  // ─── Summary card ─────────────────────────────────────────────────────────

  Widget _buildSummaryCard(AsyncValue<Course?> course) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: course.when(
        loading: () => const SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        error: (e, st) => const SizedBox(
          height: 56,
          child: Center(
            child: Text('—'),
          ),
        ),
        data: (c) {
          final tint = c != null ? subjectTint(c.subject) : AppColors.greyLight;
          final icon = c != null ? subjectIcon(c.subject) : Icons.school;
          final title = c?.title ?? '—';
          final subjectStr = c != null ? _subjectLabel(c.subject) : '—';
          final grade = c?.grade ?? '—';

          return Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subjectStr · $grade',
                      style: GoogleFonts.figtree(
                        fontSize: 11.5,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Checklist card ───────────────────────────────────────────────────────

  Widget _buildChecklistCard(
    AsyncValue<List<Map<String, dynamic>>> lessonsAsync,
    AsyncValue<Course?> course,
  ) {
    final lessons = lessonsAsync.asData?.value ?? [];
    final n = lessons.length;
    final withVideo =
        lessons.where((l) => (l['videoUrl'] as String?)?.isNotEmpty == true).length;
    final withTranscript = lessons
        .where((l) =>
            (l['videoUrl'] as String?)?.isNotEmpty == true &&
            (l['transcript'] as String?)?.isNotEmpty == true)
        .length;
    final hasDescription =
        (course.asData?.value?.description ?? '').trim().isNotEmpty;

    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          // Lessons count
          _CheckRow(
            icon: n == 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            iconColor:
                n == 0 ? const Color(0xFFB97F1F) : const Color(0xFF2BB37A),
            text: n == 0
                ? 'Add at least one lesson'
                : '$n lesson${n == 1 ? '' : 's'} added',
          ),

          // Videos
          _CheckRow(
            icon: (withVideo == n && n > 0)
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            iconColor: (withVideo == n && n > 0)
                ? const Color(0xFF2BB37A)
                : const Color(0xFFB97F1F),
            text: '$withVideo of $n lesson${n == 1 ? '' : 's'} have video',
          ),

          // Transcripts — skip row when there are no video lessons
          if (withVideo > 0)
            _CheckRow(
              icon: (withTranscript == withVideo)
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              iconColor: (withTranscript == withVideo)
                  ? const Color(0xFF2BB37A)
                  : const Color(0xFFB97F1F),
              text:
                  '$withTranscript of $withVideo video lesson${withVideo == 1 ? '' : 's'} have transcripts',
            ),

          // Description
          _CheckRow(
            icon: hasDescription
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            iconColor: hasDescription
                ? const Color(0xFF2BB37A)
                : const Color(0xFFB97F1F),
            text: hasDescription ? 'Description written' : 'Add a description',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ─── Status card ──────────────────────────────────────────────────────────

  Widget _buildStatusCard(
    AsyncValue<List<Map<String, dynamic>>> lessonsAsync,
    AsyncValue<Course?> course,
  ) {
    final lessons = lessonsAsync.asData?.value ?? [];
    final isDraft = (course.asData?.value?.status ?? CourseStatus.draft) ==
        CourseStatus.draft;
    final canPublish = lessons.isNotEmpty && !_busy;

    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Course status',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
              ),
              _StatusChip(isPublished: !isDraft),
            ],
          ),

          const SizedBox(height: 12),

          // Helper text
          Text(
            'Publishing makes this course visible to every student browsing the library.',
            style: GoogleFonts.figtree(
              fontSize: 12.5,
              color: AppColors.grey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Publish / Unpublish pill button
          if (isDraft)
            PillButton(
              label: 'Publish course',
              icon: Icons.public,
              enabled: canPublish,
              onPressed: canPublish ? () => _setStatus(true) : null,
            )
          else
            PillButton.outlined(
              label: 'Unpublish',
              icon: Icons.public_off,
              enabled: !_busy,
              onPressed: _busy ? null : () => _setStatus(false),
            ),

          const SizedBox(height: 12),

          // Save as draft & exit
          _OutlinedRow(
            icon: Icons.save_alt,
            label: 'Save as draft & exit',
            onTap: () => context.go('/teacher/courses'),
          ),
        ],
      ),
    );
  }

  // ─── Danger row ───────────────────────────────────────────────────────────

  Widget _buildDangerRow(AsyncValue<Course?> course) {
    return _DangerRow(
      onTap: () => _confirmDelete(course.asData?.value),
    );
  }
}

// ---------------------------------------------------------------------------
// _CheckRow
// ---------------------------------------------------------------------------

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 11,
        bottom: isLast ? 11 : 0,
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.figtree(
                fontSize: 13.5,
                color: AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatusChip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final bg =
        isPublished ? const Color(0xFFE6F7F0) : const Color(0xFFFBF3E2);
    final fg =
        isPublished ? const Color(0xFF2BB37A) : const Color(0xFFB97F1F);
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

// ---------------------------------------------------------------------------
// _OutlinedRow  (Save as draft & exit)
// ---------------------------------------------------------------------------

class _OutlinedRow extends StatelessWidget {
  const _OutlinedRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.greyLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.textBody),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DangerRow  (Delete course)
// ---------------------------------------------------------------------------

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 15, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Delete course',
              style: GoogleFonts.figtree(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
