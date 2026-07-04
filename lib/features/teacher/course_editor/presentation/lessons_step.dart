import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../domain/course_editor_repository.dart';
import '../domain/lesson_upload_controller.dart';
import 'lesson_sheet.dart';

// ---------------------------------------------------------------------------
// LessonsStep
// ---------------------------------------------------------------------------

class LessonsStep extends ConsumerWidget {
  const LessonsStep({
    super.key,
    required this.courseId,
    required this.onContinue,
  });

  final String courseId;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(courseEditorLessonsProvider(courseId));

    return lessonsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, st) => ErrorStateView(
        message: "Couldn't load lessons",
        onRetry: () => ref.invalidate(courseEditorLessonsProvider(courseId)),
      ),
      data: (lessons) => _LessonsBody(
        courseId: courseId,
        lessons: lessons,
        onContinue: onContinue,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LessonsBody
// ---------------------------------------------------------------------------

class _LessonsBody extends ConsumerWidget {
  const _LessonsBody({
    required this.courseId,
    required this.lessons,
    required this.onContinue,
  });

  final String courseId;
  final List<Map<String, dynamic>> lessons;
  final VoidCallback onContinue;

  void _openSheet(BuildContext context, WidgetRef ref, {Map<String, dynamic>? existing}) {
    final existingOrders = lessons.map((l) => (l['order'] as int?) ?? 0).toList();
    showLessonSheet(
      context,
      ref,
      courseId: courseId,
      existing: existing,
      existingOrders: existingOrders,
    );
  }

  Future<void> _onReorder(BuildContext context, WidgetRef ref, int oldIndex, int newIndex) async {
    // Standard reorder fixup
    var newIdx = newIndex;
    if (newIdx > oldIndex) newIdx--;

    final ids = lessons.map((l) => l['id'] as String).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIdx, moved);

    final repo = ref.read(courseEditorRepositoryProvider);
    try {
      await repo.applyReorder(courseId, CourseEditorRepository.reorderPayload(ids));
      if (context.mounted) ref.invalidate(courseEditorLessonsProvider(courseId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't reorder lessons. Please try again.")),
        );
        ref.invalidate(courseEditorLessonsProvider(courseId));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> lesson,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete lesson?',
          style: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textBody,
          ),
        ),
        content: Text(
          'Its video and files are removed too.',
          style: GoogleFonts.figtree(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final videoUrl = lesson['videoUrl'] as String?;
      final documentUrl = lesson['documentUrl'] as String?;
      if (videoUrl != null) await LessonUploadController.deleteByUrl(videoUrl);
      if (documentUrl != null) await LessonUploadController.deleteByUrl(documentUrl);

      final repo = ref.read(courseEditorRepositoryProvider);
      await repo.deleteLesson(courseId, lesson['id'] as String);
      if (context.mounted) ref.invalidate(courseEditorLessonsProvider(courseId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete lesson. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: lessons.isEmpty
              ? EmptyStateView(
                  icon: Icons.menu_book_outlined,
                  message: 'No lessons yet — add your first lesson',
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: lessons.length,
                  itemBuilder: (ctx, i) {
                    final lesson = lessons[i];
                    final id = lesson['id'] as String;
                    return _LessonRow(
                      key: ValueKey(id),
                      index: i,
                      lesson: lesson,
                      onEdit: () => _openSheet(context, ref, existing: lesson),
                      onDelete: () => _confirmDelete(context, ref, lesson),
                    );
                  },
                  onReorder: (oldIndex, newIndex) =>
                      _onReorder(context, ref, oldIndex, newIndex),
                ),
        ),

        // Add lesson button
        GestureDetector(
          onTap: () => _openSheet(context, ref),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(26),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Add lesson',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        PillButton(
          label: 'Continue',
          enabled: lessons.isNotEmpty,
          onPressed: lessons.isNotEmpty ? onContinue : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _LessonRow
// ---------------------------------------------------------------------------

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    super.key,
    required this.index,
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final Map<String, dynamic> lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = lesson['title'] as String? ?? '';
    final durationMinutes = lesson['durationMinutes'] as int? ?? 0;
    final videoUrl = lesson['videoUrl'] as String?;
    final contentHtml = lesson['contentHtml'] as String?;
    final documentUrl = lesson['documentUrl'] as String?;

    // Status row widgets
    Widget statusWidget;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      statusWidget = Row(
        children: [
          const Icon(Icons.check_circle, size: 12, color: Color(0xFF2BB37A)),
          const SizedBox(width: 4),
          Text(
            'Video · $durationMinutes min',
            style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      );
    } else if (contentHtml != null && contentHtml.isNotEmpty) {
      statusWidget = Row(
        children: [
          const Icon(Icons.article_outlined, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Text lesson',
            style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      );
    } else {
      statusWidget = Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 12, color: Color(0xFFB97F1F)),
          const SizedBox(width: 4),
          Text(
            'No content yet',
            style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator, size: 16, color: AppColors.greyLight),
            ),

            const SizedBox(width: 10),

            // Order number circle
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Title + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.figtree(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      statusWidget,
                      if (documentUrl != null && documentUrl.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.attach_file, size: 12, color: AppColors.grey),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // More menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: AppColors.grey),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Edit',
                    style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: GoogleFonts.figtree(fontSize: 14, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
