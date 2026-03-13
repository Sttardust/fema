import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/library_provider.dart';
import '../domain/models.dart';

class CourseDetailsScreen extends ConsumerStatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  ConsumerState<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, course),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Curriculum'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(course: course),
            _CurriculumTab(course: course),
          ],
        ),
      ),
      bottomNavigationBar: _buildEnrollBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Course course) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              course.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryDark,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.grade.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.subject.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
            // Play button
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Enroll logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Enroll',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Course course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About the course
          Text(
            'About the course',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            course.description.isNotEmpty
                ? course.description
                : 'Welcome to the ${course.title} course! In this exciting journey, we will explore the fundamental principles of ${course.subject.name} that govern the world around us. From understanding motion and forces to discovering the wonders of energy and matter, this course is designed to spark your curiosity and deepen your knowledge. Get ready to engage with hands-on experiments and real-life applications that make learning ${course.subject.name} fun and relevant!',
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 24),

          // Pre-requisite read
          Text(
            'Pre-requisite read',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.grade} ${course.subject.name}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),

          // Language
          Text(
            'Language',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'English',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),

          // Course Content summary
          Text(
            'Course Content',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ContentStatRow(
            icon: Icons.play_circle_outline,
            text: '${course.lessons.where((l) => l.videoUrl != null).length.clamp(1, 99)} total hour videos',
          ),
          _ContentStatRow(
            icon: Icons.article_outlined,
            text: '${(course.lessons.length * 0.3).round().clamp(1, 99)} Articles',
          ),
          _ContentStatRow(
            icon: Icons.quiz_outlined,
            text: '${(course.lessons.length * 0.5).round().clamp(1, 99)} Quizzes',
          ),
          _ContentStatRow(
            icon: Icons.assignment_outlined,
            text: '${(course.lessons.length * 0.2).round().clamp(1, 99)} Assignments',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ContentStatRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContentStatRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 20),
          const SizedBox(width: 10),
          Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
        ],
      ),
    );
  }
}

// ─── Curriculum Tab ───────────────────────────────────────────────────────────

class _CurriculumTab extends ConsumerWidget {
  final Course course;
  const _CurriculumTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group lessons into chapters (every 4-5 lessons = 1 chapter)
    final chapters = _buildChapters(course.lessons);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return _ChapterExpansionTile(
          chapterNumber: index + 1,
          chapterTitle: chapter.title,
          lessons: chapter.lessons,
          isInitiallyExpanded: index == 0,
          onLessonTap: (lesson) {
            ref.read(selectedLessonProvider.notifier).state = lesson;
            ref.read(selectedCourseProvider.notifier).state = course;
            context.push('/library/video-player');
          },
        );
      },
    );
  }

  List<_Chapter> _buildChapters(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return [
        _Chapter(title: 'Introduction to Physics', lessons: [
          Lesson(id: '1', title: 'Introduction to Physics', description: 'Video', durationMinutes: 10),
          Lesson(id: '2', title: 'Newtons First Law', description: 'Article', durationMinutes: 8),
          Lesson(id: '3', title: 'Newtons Second Law', description: 'Video', durationMinutes: 15),
          Lesson(id: '4', title: "Newton's First Law of Motion", description: 'Video', durationMinutes: 5),
          Lesson(id: '5', title: 'Physics Chapter 1 Assessment', description: 'Quiz - 5 Questions', durationMinutes: 10),
        ]),
        _Chapter(title: 'Define mass in the context of physics.', lessons: []),
        _Chapter(title: "Newton's First Law of Motion", lessons: []),
        _Chapter(title: 'Physics Chapter 1 Assessment', lessons: []),
      ];
    }

    final List<_Chapter> chapters = [];
    const chapterSize = 5;
    final chapterTitles = [
      'Introduction to Physics',
      'Newtons First Law',
      'Newtons Second Law',
      'Define mass in the context of physics.',
      "Newton's First Law of Motion Explained",
      'Physics Chapter 1 Assessment',
    ];

    for (int i = 0; i < lessons.length; i += chapterSize) {
      final end = (i + chapterSize).clamp(0, lessons.length);
      final chapterIndex = i ~/ chapterSize;
      chapters.add(_Chapter(
        title: chapterIndex < chapterTitles.length
            ? chapterTitles[chapterIndex]
            : 'Chapter ${chapterIndex + 1}',
        lessons: lessons.sublist(i, end),
      ));
    }
    return chapters;
  }
}

class _Chapter {
  final String title;
  final List<Lesson> lessons;
  _Chapter({required this.title, required this.lessons});
}

class _ChapterExpansionTile extends StatelessWidget {
  final int chapterNumber;
  final String chapterTitle;
  final List<Lesson> lessons;
  final bool isInitiallyExpanded;
  final Function(Lesson) onLessonTap;

  const _ChapterExpansionTile({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.lessons,
    this.isInitiallyExpanded = false,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: isInitiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Text(
            'Chapter $chapterNumber',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              chapterTitle,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      children: lessons.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Content coming soon',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                ),
              ),
            ]
          : lessons.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;
              final lessonType = _getLessonType(lesson);
              return InkWell(
                onTap: () => onLessonTap(lesson),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lessonType == 'Quiz'
                                  ? 'Quiz - 5 Questions'
                                  : '$lessonType - ${lesson.durationMinutes}:${(lesson.durationMinutes % 60).toString().padLeft(2, '0')} mins',
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        lessonType == 'Video'
                            ? Icons.play_circle_outline
                            : lessonType == 'Quiz'
                                ? Icons.quiz_outlined
                                : Icons.article_outlined,
                        color: AppColors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
    );
  }

  String _getLessonType(Lesson lesson) {
    if (lesson.description.toLowerCase().contains('quiz')) return 'Quiz';
    if (lesson.description.toLowerCase().contains('article')) return 'Article';
    return 'Video';
  }
}

// ─── Lesson Viewer (kept for backward compat, but video_player_screen.dart is the new one) ──

class LessonViewerScreen extends ConsumerWidget {
  const LessonViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(selectedLessonProvider);

    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('No lesson selected')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: Column(
        children: [
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
                  Text(lesson.title, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${lesson.durationMinutes} minutes', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                  const Divider(height: 48),
                  Text(lesson.description, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
