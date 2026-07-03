import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/subject_visuals.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/soft_card.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

/// Single course view — Overview + Curriculum tabs, with a Continue CTA
/// pinned to the bottom. Matches the MVP design system (Task 6).
class CourseDetailsScreen extends ConsumerStatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Which tab segment is active: 0 = Overview, 1 = Curriculum
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _activeTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(selectedCourseProvider);
    if (course == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No course selected')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top nav row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  // Back button — 40px circular surface
                  CircleIconButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.pop(),
                  ),

                  // Centred title
                  Expanded(
                    child: Text(
                      'Course details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                    ),
                  ),

                  // Spacer to balance the back button
                  const SizedBox(width: 40, height: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Banner ─────────────────────────────────────────────────────
            _CourseBanner(course: course),

            const SizedBox(height: 16),

            // ── Segmented control ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SegmentedControl(
                activeIndex: _activeTab,
                onChanged: (i) {
                  setState(() => _activeTab = i);
                  _tabController.animateTo(i);
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab content ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(course: course),
                  _CurriculumTab(course: course),
                ],
              ),
            ),

            // ── Bottom CTA ─────────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: PillButton(
                  label: 'Continue learning',
                  icon: Icons.play_arrow,
                  onPressed: () => _continueLearning(context, course),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueLearning(BuildContext context, Course course) {
    final first = course.lessons.isNotEmpty ? course.lessons.first : null;
    if (first == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This course has no lessons yet.')),
      );
      return;
    }
    ref.read(selectedLessonProvider.notifier).state = first;
    context.push('/library/video-player');
  }
}

// ── Course banner ─────────────────────────────────────────────────────────────

class _CourseBanner extends StatelessWidget {
  final Course course;
  const _CourseBanner({required this.course});

  @override
  Widget build(BuildContext context) {
    final totalMins =
        course.lessons.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    final hasGrade = course.grade.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x334B0082),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject icon tile
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                subjectIcon(course.subject),
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(height: 12),

            // Course title
            Text(
              course.title,
              style: GoogleFonts.figtree(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // Meta row
            Row(
              children: [
                // Lessons
                _MetaChip(
                  icon: Icons.play_circle_outline,
                  label: '${course.lessons.length} lessons',
                ),

                // Duration — always available since durationMinutes is on Lesson
                if (totalMins > 0) ...[
                  const SizedBox(width: 14),
                  _MetaChip(
                    icon: Icons.schedule,
                    label: hours > 0
                        ? '${hours}h ${mins}m'
                        : '${mins}m',
                  ),
                ],

                // Grade
                if (hasGrade) ...[
                  const SizedBox(width: 14),
                  _MetaChip(
                    icon: Icons.school,
                    label: 'Grade ${course.grade}',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      color: Color(0xCCFFFFFF),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xCCFFFFFF)),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
          _Segment(
            label: 'Overview',
            active: activeIndex == 0,
            onTap: () => onChanged(0),
          ),
          _Segment(
            label: 'Curriculum',
            active: activeIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: double.infinity,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Course course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    // course.description is a required non-nullable String on the model.
    // ownerId exists but no teacher name is available — teacher card omitted.
    // No learningObjectives field on Course model — objectives card omitted.

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About this course
          SoftCard(
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this course',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  course.description.isNotEmpty
                      ? course.description
                      : 'No description available.',
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Curriculum tab ────────────────────────────────────────────────────────────

class _CurriculumTab extends ConsumerWidget {
  final Course course;
  const _CurriculumTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = course.lessons;
    final selectedLesson = ref.watch(selectedLessonProvider);

    if (lessons.isEmpty) {
      return const Center(
        child: Text(
          'No lessons yet.',
          style: TextStyle(fontSize: 14, color: AppColors.grey),
        ),
      );
    }

    // The current/selected lesson is whatever selectedLessonProvider points to,
    // falling back to the first lesson if nothing is selected.
    final currentLessonId =
        selectedLesson?.id ?? lessons.first.id;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: lessons.length,
      separatorBuilder: (context2, idx) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final lesson = lessons[i];
        final isCurrent = lesson.id == currentLessonId;

        return _LessonRow(
          index: i + 1,
          lesson: lesson,
          isCurrent: isCurrent,
          onTap: () {
            ref.read(selectedLessonProvider.notifier).state = lesson;
            context.push('/library/video-player');
          },
        );
      },
    );
  }
}

class _LessonRow extends StatelessWidget {
  final int index;
  final Lesson lesson;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrent
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: isCurrent
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Number tile
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? Colors.white : AppColors.grey,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Title + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                  ),
                  if (lesson.durationMinutes > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.durationMinutes} min',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing icon
            Icon(
              isCurrent
                  ? Icons.play_circle
                  : Icons.play_circle_outline,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
