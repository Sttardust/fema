import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../library/domain/library_provider.dart';
import '../../../library/domain/models.dart';
import '../../../profile/domain/user_profile_repository.dart';
import '../domain/course_editor_repository.dart';
import 'basics_step.dart';
import 'lessons_step.dart';
import 'review_step.dart';

// ---------------------------------------------------------------------------
// Step-indicator metadata
// ---------------------------------------------------------------------------

const _stepLabels = ['BASICS', 'LESSONS', 'REVIEW'];

// ---------------------------------------------------------------------------
// CourseWizardScreen
// ---------------------------------------------------------------------------

class CourseWizardScreen extends ConsumerStatefulWidget {
  const CourseWizardScreen({super.key, this.courseId});

  final String? courseId;

  @override
  ConsumerState<CourseWizardScreen> createState() => _CourseWizardScreenState();
}

class _CourseWizardScreenState extends ConsumerState<CourseWizardScreen> {
  int _step = 0;

  /// Tracks the persisted Firestore doc id (null until first createDraft).
  String? _courseId;

  /// Display title — kept in sync with what the user saves.
  String? _courseTitle;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseId;
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _handleBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/teacher/courses');
    }
  }

  // ---------------------------------------------------------------------------
  // Save handlers
  // ---------------------------------------------------------------------------

  Future<void> _onBasicsSubmit(BasicsData data) async {
    final repo = ref.read(courseEditorRepositoryProvider);

    try {
      if (_courseId == null) {
        // New course — need uid
        final uid = ref.read(authStateProvider).asData?.value?.uid;
        if (uid == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not signed in. Please sign in and try again.')),
            );
          }
          return;
        }

        final profile = ref.read(currentUserProfileProvider).asData?.value;
        final authorName = profile?.fullName;

        final id = await repo.createDraft(
          title: data.title,
          description: data.description,
          subject: data.subject,
          grade: data.grade,
          ownerId: uid,
          authorName: authorName,
          learningObjectives: data.learningObjectives,
        );

        if (!mounted) return;
        ref.invalidate(teacherCoursesProvider);
        setState(() {
          _courseId = id;
          _courseTitle = data.title;
          _step = 1;
        });
      } else {
        // Edit existing course
        await repo.updateBasics(
          _courseId!,
          title: data.title,
          description: data.description,
          subject: data.subject,
          grade: data.grade,
          learningObjectives: data.learningObjectives,
        );

        if (!mounted) return;
        setState(() {
          _courseTitle = data.title;
          _step = 1;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save. Try again.")),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Derive initial BasicsData from a Course when editing
  // ---------------------------------------------------------------------------

  BasicsData _courseToInitial(Course course) {
    // subject enum → lowercase firestore string
    final subjectStr = course.subject.name.toLowerCase();

    return BasicsData(
      title: course.title,
      description: course.description,
      subject: subjectStr,
      grade: course.grade,
      learningObjectives: List<String>.from(course.learningObjectives),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // When editing, watch teacher courses for prefill. While loading → spinner.
    BasicsData? initialData;

    if (widget.courseId != null) {
      final coursesAsync = ref.watch(teacherCoursesProvider);

      return coursesAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: ErrorStateView(
            message: "Couldn't load course.",
            onRetry: () => ref.invalidate(teacherCoursesProvider),
          ),
        ),
        data: (courses) {
          final course = courses.where((c) => c.id == widget.courseId).firstOrNull;
          if (course == null) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: EmptyStateView(
                icon: Icons.school_outlined,
                message: 'Course not found',
              ),
            );
          }

          // Derive initial on first build — _courseTitle falls back to
          // course.title when _courseTitle is still null (avoids setState-in-build).
          final derivedTitle = _courseTitle ?? course.title;
          initialData = _courseToInitial(course);

          return _buildScaffold(
            displayTitle: derivedTitle,
            initialData: initialData,
          );
        },
      );
    }

    return _buildScaffold(displayTitle: _courseTitle, initialData: null);
  }

  Widget _buildScaffold({
    required String? displayTitle,
    required BasicsData? initialData,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left,
                    onTap: _handleBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle ?? 'New course',
                          style: GoogleFonts.figtree(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textBody,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_courseId != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.check,
                                size: 12,
                                color: Color(0xFF2BB37A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Saved as draft',
                                style: GoogleFonts.figtree(
                                  fontSize: 11.5,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Step indicator bars ────────────────────────────────────────
              _StepIndicator(currentStep: _step),

              const SizedBox(height: 14),

              // ── Step label ─────────────────────────────────────────────────
              Text(
                'STEP ${_step + 1} OF 3 — ${_stepLabels[_step]}',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 16),

              // ── Step body ─────────────────────────────────────────────────
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    BasicsStep(
                      initial: initialData,
                      onSubmit: _onBasicsSubmit,
                    ),
                    // Task 7: real lessons step (Task 8 replaces Review stub).
                    _courseId == null
                        ? const _StubStep('Lessons')
                        : LessonsStep(
                            courseId: _courseId!,
                            onContinue: () => setState(() => _step = 2),
                          ),
                    _courseId == null
                        ? const _StubStep('Review')
                        : ReviewStep(courseId: _courseId!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step indicator — 3 equal bars
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final bool active = i <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.greyLight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Stub step placeholder (replaced by Tasks 7 and 8)
// ---------------------------------------------------------------------------

class _StubStep extends StatelessWidget {
  const _StubStep(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label step — coming soon',
        style: GoogleFonts.figtree(
          fontSize: 14,
          color: AppColors.grey,
        ),
      ),
    );
  }
}
