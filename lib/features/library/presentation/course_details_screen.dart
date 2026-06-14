import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

/// Single course view — Overview + Curriculum tabs, with an Enroll CTA
/// pinned to the bottom. Matches the Figma "Single course view" frames.
class CourseDetailsScreen extends ConsumerStatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      return const Scaffold(body: Center(child: Text('No course selected')));
    }

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
          _Hero(course: course),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Curriculum'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(course: course),
                _CurriculumTab(course: course),
              ],
            ),
          ),
          _EnrollFooter(
            onEnroll: () => _enroll(context, course),
          ),
        ],
      ),
    );
  }

  String _subjectLabel(CourseSubject s) {
    final n = s.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  void _enroll(BuildContext context, Course course) {
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

class _Hero extends StatelessWidget {
  final Course course;
  const _Hero({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: const Color(0xFF1A1A2E),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(course.grade.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(course.subject.name.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Course course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final videos = course.lessons.where((l) => l.videoUrl != null).length;
    final articles = course.lessons
        .where((l) => l.videoUrl == null && l.contentHtml != null)
        .length;
    final totalMins =
        course.lessons.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final hours = (totalMins / 60).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About the course',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          _MetaRow(label: 'Pre-required read', value: _preReqFor(course)),
          const SizedBox(height: 14),
          const _MetaRow(label: 'Language', value: 'English'),
          const SizedBox(height: 22),
          const Text(
            'Course Content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 10),
          if (videos > 0) _ContentRow(
            icon: Icons.play_circle_outline,
            label: '$hours total hour ${hours == 1 ? 'video' : 'videos'}',
          ),
          if (articles > 0) _ContentRow(
            icon: Icons.article_outlined,
            label: '$articles ${articles == 1 ? 'Article' : 'Articles'}',
          ),
          _ContentRow(
            icon: Icons.quiz_outlined,
            label: '${course.lessons.length} ${course.lessons.length == 1 ? 'Lesson' : 'Lessons'}',
          ),
        ],
      ),
    );
  }

  String _preReqFor(Course course) {
    // Suggest the immediately previous grade as the prereq. Cheap heuristic
    // until we wire real prerequisites.
    final grade = course.grade.trim();
    final match = RegExp(r'(\d+)').firstMatch(grade);
    if (match == null) return 'None';
    final n = int.tryParse(match.group(1)!) ?? 0;
    if (n <= 1) return 'None';
    return 'Grade ${n - 1} ${course.subject.name}';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.textBody),
        ),
      ],
    );
  }
}

class _ContentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContentRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHeadline),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textBody),
          ),
        ],
      ),
    );
  }
}

// ─── Curriculum tab ───────────────────────────────────────────────────────────

class _CurriculumTab extends StatefulWidget {
  final Course course;
  const _CurriculumTab({required this.course});

  @override
  State<_CurriculumTab> createState() => _CurriculumTabState();
}

class _CurriculumTabState extends State<_CurriculumTab> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final lessons = widget.course.lessons;
    if (lessons.isEmpty) {
      return const Center(child: Text('No chapters yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: lessons.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.greyLight.withValues(alpha: 0.6)),
      itemBuilder: (context, i) {
        final lesson = lessons[i];
        final expanded = _expanded.contains(i);
        return _ChapterRow(
          index: i + 1,
          title: lesson.title,
          description: lesson.description,
          minutes: lesson.durationMinutes,
          expanded: expanded,
          onTap: () => setState(() {
            expanded ? _expanded.remove(i) : _expanded.add(i);
          }),
        );
      },
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final int minutes;
  final bool expanded;
  final VoidCallback onTap;

  const _ChapterRow({
    required this.index,
    required this.title,
    required this.description,
    required this.minutes,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Chapter $index',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textHeadline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(80, 8, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textBody,
                          height: 1.45,
                        ),
                      ),
                    if (description.isNotEmpty) const SizedBox(height: 6),
                    Text(
                      '$minutes min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom CTA ───────────────────────────────────────────────────────────────

class _EnrollFooter extends StatelessWidget {
  final VoidCallback onEnroll;
  const _EnrollFooter({required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onEnroll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Enroll',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
