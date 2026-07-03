import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/lesson_video_controller.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

/// Watching-a-lesson screen. Real video playback via LessonVideoController /
/// Chewie. Three tabs (Notes / Transcript / Up Next) below the video, and a
/// Previous / Next bottom bar.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Video lifecycle state
  LessonVideoController? _videoController;
  _VideoState _videoState = _VideoState.noUrl;

  // Monotonically increasing request ID guards against stale async results
  // when the lesson changes quickly.
  int _initRequestId = 0;

  /// The lesson ID whose video is currently loaded (or loading). Used in
  /// didChangeDependencies to detect lesson changes without re-initializing on
  /// every rebuild.
  String? _loadedLessonId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lesson = ref.read(selectedLessonProvider);
    if (lesson == null) return;
    if (_loadedLessonId != lesson.id) {
      _loadedLessonId = lesson.id;
      _initVideo(lesson);
    }
  }

  Future<void> _initVideo(Lesson lesson) async {
    // Fix 1: Bump request id FIRST so every call (including noUrl) invalidates
    // any in-flight initialization from the previous lesson.
    final myRequestId = ++_initRequestId;

    if (!LessonVideoController.isPlayableUrl(lesson.videoUrl)) {
      // Fix 2: setState to the terminal state BEFORE disposing the old
      // controller so the Chewie widget is already out of the tree when dispose
      // runs.
      if (mounted) setState(() => _videoState = _VideoState.noUrl);
      _disposeVideoController();
      return;
    }

    // Fix 2 (continued): transition to initializing state first, then dispose
    // the old controller so the ready-state Chewie is removed from the tree
    // before its underlying controller is disposed.
    if (mounted) setState(() => _videoState = _VideoState.initializing);
    _disposeVideoController();

    final ctrl = LessonVideoController(lesson.videoUrl!);
    try {
      await ctrl.initialize();
      if (!mounted || _initRequestId != myRequestId) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _videoController = ctrl;
        _videoState = _VideoState.ready;
      });
    } catch (_) {
      ctrl.dispose();
      if (!mounted || _initRequestId != myRequestId) return;
      // Fix 3: Clear _loadedLessonId so re-selecting the same lesson retries
      // initialization instead of being a no-op.
      _loadedLessonId = null;
      setState(() => _videoState = _VideoState.error);
    }
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers so the widget rebuilds when lesson/course change.
    final lesson = ref.watch(selectedLessonProvider);
    final course = ref.watch(selectedCourseProvider);

    // When the lesson changes, trigger a new video load (guarded by id check).
    ref.listen<Lesson?>(selectedLessonProvider, (previous, next) {
      if (next == null) return;
      if (_loadedLessonId != next.id) {
        _loadedLessonId = next.id;
        _initVideo(next);
      }
    });

    if (lesson == null || course == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: EmptyStateView(
          icon: Icons.video_library_outlined,
          message: 'No lesson selected',
          action: PillButton(
            label: 'Browse library',
            onPressed: () => context.go('/home'),
          ),
        ),
      );
    }

    final lessons = course.lessons;
    final currentIndex = lessons.indexWhere((l) => l.id == lesson.id);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < lessons.length - 1;
    final lessonNumber = currentIndex >= 0 ? currentIndex + 1 : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top nav row ───────────────────────────────────────────────
            _TopNavRow(
              lessonNumber: lessonNumber,
              totalLessons: lessons.length,
              onBack: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            const SizedBox(height: 12),

            // ── 2. Video area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _VideoArea(
                    videoState: _videoState,
                    controller: _videoController,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Lesson heading ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.figtree(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.title} · ${course.grade}',
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. Chip tabs row ─────────────────────────────────────────────
            _ChipTabRow(tabController: _tabController),
            const SizedBox(height: 8),

            // ── 5. Tab content ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NoteTab(lesson: lesson),
                  _TranscriptTab(lesson: lesson),
                  _UpNextTab(course: course, currentLesson: lesson),
                ],
              ),
            ),

            // ── 6. Bottom prev/next row ──────────────────────────────────────
            _BottomNav(
              hasPrev: hasPrev,
              hasNext: hasNext,
              onPrev: hasPrev
                  ? () => ref.read(selectedLessonProvider.notifier).state =
                      lessons[currentIndex - 1]
                  : null,
              onNext: hasNext
                  ? () => ref.read(selectedLessonProvider.notifier).state =
                      lessons[currentIndex + 1]
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Video area state enum ────────────────────────────────────────────────────

enum _VideoState { noUrl, initializing, ready, error }

// ─── Top nav row ──────────────────────────────────────────────────────────────

class _TopNavRow extends StatelessWidget {
  final int lessonNumber;
  final int totalLessons;
  final VoidCallback onBack;

  const _TopNavRow({
    required this.lessonNumber,
    required this.totalLessons,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // 40 px circular back button with surface fill + card shadow
          CircleIconButton(
            icon: Icons.chevron_left,
            onTap: onBack,
          ),

          // Centered label: "Lesson n of m"
          Expanded(
            child: Center(
              child: Text(
                'Lesson $lessonNumber of $totalLessons',
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ),

          // Spacer sized to match the back button so the label stays centered
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─── Video area ───────────────────────────────────────────────────────────────

class _VideoArea extends StatelessWidget {
  final _VideoState videoState;
  final LessonVideoController? controller;

  const _VideoArea({required this.videoState, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF211936),
      child: switch (videoState) {
        _VideoState.initializing => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        _VideoState.ready => Chewie(controller: controller!.chewie!),
        _VideoState.noUrl || _VideoState.error => _VideoUnavailable(),
      },
    );
  }
}

class _VideoUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0x29FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_disabled,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Video unavailable',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chip tab row ─────────────────────────────────────────────────────────────

class _ChipTabRow extends StatefulWidget {
  final TabController tabController;

  const _ChipTabRow({required this.tabController});

  @override
  State<_ChipTabRow> createState() => _ChipTabRowState();
}

class _ChipTabRowState extends State<_ChipTabRow> {
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.tabController.index;
    widget.tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted && _activeIndex != widget.tabController.index) {
      setState(() => _activeIndex = widget.tabController.index);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Notes', 'Transcript', 'Up next'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == _activeIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: _ChipTab(
              label: labels[i],
              isActive: isActive,
              onTap: () => widget.tabController.animateTo(i),
            ),
          );
        }),
      ),
    );
  }
}

class _ChipTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChipTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: AppColors.greyLight),
        ),
        child: Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.grey,
          ),
        ),
      ),
    );
  }
}

// ─── Note tab ─────────────────────────────────────────────────────────────────

class _NoteTab extends StatefulWidget {
  final Lesson lesson;
  const _NoteTab({required this.lesson});

  @override
  State<_NoteTab> createState() => _NoteTabState();
}

class _NoteTabState extends State<_NoteTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Thoughts',
              style: GoogleFonts.figtree(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add your thought',
                        hintStyle: GoogleFonts.figtree(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_ctrl.text.trim().isEmpty) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note saved')),
                      );
                      _ctrl.clear();
                    },
                    child: Text(
                      'Save',
                      style: GoogleFonts.figtree(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
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

// ─── Transcript tab ───────────────────────────────────────────────────────────

class _TranscriptTab extends StatelessWidget {
  final Lesson lesson;
  const _TranscriptTab({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final text = lesson.contentHtml ??
        'Welcome to our ${lesson.title.toLowerCase()} lesson! In '
            'this video, we will explore the fascinating world of '
            'classical mechanics. We will start by discussing '
            "Newton's laws of motion, which form the foundation of "
            'our understanding of how objects move. From the simple '
            'act of throwing a ball to the complex orbits of '
            'planets, these laws help us predict and explain the '
            'behavior of physical systems.\n\nWe will also delve '
            'into concepts like force, mass, and acceleration, '
            'providing real-world examples to illustrate these '
            'principles in action.\n\nAs we progress, we will '
            'introduce the concept of energy and its various '
            'forms, including kinetic and potential energy.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcript',
            style: GoogleFonts.figtree(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              style: GoogleFonts.figtree(
                color: AppColors.textBody,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Up Next tab ──────────────────────────────────────────────────────────────

class _UpNextTab extends ConsumerWidget {
  final Course course;
  final Lesson currentLesson;
  const _UpNextTab({required this.course, required this.currentLesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex =
        course.lessons.indexWhere((l) => l.id == currentLesson.id);
    final upcoming = currentIndex >= 0
        ? course.lessons.sublist(currentIndex)
        : course.lessons;

    if (upcoming.isEmpty) {
      return Center(
        child: Text(
          'No more lessons.',
          style: GoogleFonts.figtree(
            color: AppColors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: upcoming.length,
      separatorBuilder: (ctx, i) =>
          Divider(height: 1, color: AppColors.greyLight),
      itemBuilder: (context, i) {
        final lesson = upcoming[i];
        final isCurrent = lesson.id == currentLesson.id;
        return InkWell(
          onTap: isCurrent
              ? null
              : () => ref.read(selectedLessonProvider.notifier).state = lesson,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.figtree(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lessonSubtitle(lesson),
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrent)
                  const Icon(Icons.add_circle_outline,
                      color: AppColors.grey, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  String _lessonSubtitle(Lesson lesson) {
    final kind = lesson.videoUrl != null ? 'Video' : 'Article';
    return '$kind • ${lesson.durationMinutes} mins';
  }
}

// ─── Bottom Previous/Next ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _BottomNav({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.greyLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PillButton.outlined(
              label: 'Previous',
              icon: Icons.chevron_left,
              enabled: hasPrev,
              onPressed: onPrev,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PillButton(
              label: 'Next',
              enabled: hasNext,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
