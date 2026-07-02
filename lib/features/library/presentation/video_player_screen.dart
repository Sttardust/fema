import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

/// Watching-a-lesson screen. Three tabs (Note / Transcript / Up Next) below
/// the video, and a Previous / Next bottom bar.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPlaying = false;
  double _progress = 0.4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(selectedLessonProvider);
    final course = ref.watch(selectedCourseProvider);

    if (lesson == null || course == null) {
      return const Scaffold(body: Center(child: Text('No lesson selected')));
    }

    final lessons = course.lessons;
    final currentIndex = lessons.indexWhere((l) => l.id == lesson.id);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < lessons.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Text(
                  '${course.grade} ${_subjectLabel(course.subject)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _VideoPlayer(
            course: course,
            lesson: lesson,
            isPlaying: _isPlaying,
            progress: _progress,
            onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
            onScrub: (v) => setState(() => _progress = v),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Note'),
              Tab(text: 'Transcript'),
              Tab(text: 'Up Next'),
            ],
          ),
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
    );
  }

  String _subjectLabel(CourseSubject s) {
    final n = s.name;
    return n[0].toUpperCase() + n.substring(1);
  }
}

class _VideoPlayer extends StatelessWidget {
  final Course course;
  final Lesson lesson;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;

  const _VideoPlayer({
    required this.course,
    required this.lesson,
    required this.isPlaying,
    required this.progress,
    required this.onTogglePlay,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    final totalSecs = lesson.durationMinutes * 60;
    final elapsedSecs = (totalSecs * progress).round();
    final mm = (elapsedSecs ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsedSecs % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: const Color(0xFF1A1A2E),
          height: 210,
          child: Stack(
            children: [
              // Background "chalkboard" placeholder
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(course.grade.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(course.subject.name.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // Center playback controls
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10,
                          color: Colors.white70, size: 32),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onTogglePlay,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.forward_10,
                          color: Colors.white70, size: 32),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              // Bottom progress row
              Positioned(
                left: 12,
                right: 12,
                bottom: 4,
                child: Row(
                  children: [
                    Text('$mm:$ss',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10),
                          activeTrackColor: Colors.red,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.red,
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: onScrub,
                        ),
                      ),
                    ),
                    const Icon(Icons.fullscreen,
                        color: Colors.white70, size: 22),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Thoughts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
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
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add your thought',
                      hintStyle: TextStyle(color: AppColors.grey),
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
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.textHeadline,
                      fontWeight: FontWeight.w700,
                    ),
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

// ─── Transcript tab ───────────────────────────────────────────────────────────

class _TranscriptTab extends StatelessWidget {
  final Lesson lesson;
  const _TranscriptTab({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transcript',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Text(
              lesson.contentHtml ??
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
                      'forms, including kinetic and potential energy.',
              style: const TextStyle(
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
      return const Center(child: Text('No more lessons.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: upcoming.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
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
                    style: const TextStyle(
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textHeadline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lessonSubtitle(lesson),
                        style: const TextStyle(
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.greyLight)),
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: onPrev,
              child: Text(
                'Previous',
                style: TextStyle(
                  color: hasPrev ? AppColors.textHeadline : AppColors.greyLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onNext,
              child: Text(
                'Next',
                style: TextStyle(
                  color: hasNext ? AppColors.textHeadline : AppColors.greyLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
