import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

// ─────────────────────────────────────────────
// SCREEN 1: Teacher Intro Carousel (5 slides)
// ─────────────────────────────────────────────

class TeacherIntroCarouselScreen extends StatefulWidget {
  const TeacherIntroCarouselScreen({super.key});

  @override
  State<TeacherIntroCarouselScreen> createState() => _TeacherIntroCarouselScreenState();
}

class _TeacherIntroCarouselScreenState extends State<TeacherIntroCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TeacherIntroPage> _pages = const [
    _TeacherIntroPage(
      title: 'Inspire the Next Generation',
      description: 'Empower students across Ethiopia with your expertise and passion for teaching.',
      imagePath: 'assets/images/Teacher/Home/full data.png',
    ),
    _TeacherIntroPage(
      title: 'Easy Course Creation',
      description: 'Build rich, structured courses with videos, lessons, and quizzes in minutes.',
      imagePath: 'assets/images/Teacher/Course creation/Basics.png',
    ),
    _TeacherIntroPage(
      title: 'Reach More Students',
      description: 'Your knowledge goes further. Teach students beyond your classroom walls.',
      imagePath: 'assets/images/Teacher/Course creation/first time.png',
    ),
    _TeacherIntroPage(
      title: 'Track Student Progress',
      description: 'See detailed analytics, monitor engagement, and celebrate achievements.',
      imagePath: 'assets/images/Teacher/Chat/User list.png',
    ),
    _TeacherIntroPage(
      title: 'Join a Community',
      description: 'Collaborate with top educators across the country and grow together.',
      imagePath: 'assets/images/Teacher/Chat/single Chat.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: () => context.go('/welcome'),
                  child: Text('Skip', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          page.imagePath,
                          height: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 280,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(child: Icon(Icons.school, size: 100, color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.primary : AppColors.greyLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/welcome');
                      }
                    },
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

class _TeacherIntroPage {
  final String title;
  final String description;
  final String imagePath;
  const _TeacherIntroPage({required this.title, required this.description, required this.imagePath});
}


// ─────────────────────────────────────────────
// SCREEN 2: Teaching Experience
// ─────────────────────────────────────────────

class TeacherExperienceScreen extends ConsumerStatefulWidget {
  const TeacherExperienceScreen({super.key});

  @override
  ConsumerState<TeacherExperienceScreen> createState() => _TeacherExperienceScreenState();
}

class _TeacherExperienceScreenState extends ConsumerState<TeacherExperienceScreen> {
  final _schoolsController = TextEditingController();
  final List<String> _selectedGrades = [];
  final List<String> _selectedSubjects = [];

  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Amharic',
    'Social Studies', 'ICT', 'Physics', 'Chemistry', 'Biology',
  ];

  final List<String> _gradeRanges = [
    'Grade 1–4', 'Grade 5–8', 'Grade 9–10', 'Grade 11–12',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _schoolsController.text = state.pastSchools ?? '';
    _selectedGrades.addAll(state.teachingGrades);
    _selectedSubjects.addAll(state.teachingSubjects);
  }

  @override
  void dispose() {
    _schoolsController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selectedGrades.isNotEmpty && _selectedSubjects.isNotEmpty) {
      ref.read(onboardingProvider.notifier).updateTeachingRole(
        grades: _selectedGrades,
        subjects: _selectedSubjects,
        schools: _schoolsController.text,
      );
      context.push('/onboarding/teacher-personalization');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one grade range and one subject')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: OnboardingProgressHeader(
        currentStep: 1,
        totalSteps: 3,
        onSkip: () => context.push('/onboarding/teacher-personalization'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Your Teaching Journey',
              style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your background so we can personalize your experience.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 32),

            // Grade Ranges
            _SectionLabel(label: 'Which grades do you teach?'),
            const SizedBox(height: 12),
            _buildGradeGrid(),

            const SizedBox(height: 28),

            // Subjects
            _SectionLabel(label: 'Your subject specializations'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _subjects.map((subject) {
                final isSelected = _selectedSubjects.contains(subject);
                return GestureDetector(
                  onTap: () => setState(() {
                    isSelected ? _selectedSubjects.remove(subject) : _selectedSubjects.add(subject);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.greyLight,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      subject,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textHeadline,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // School(s)
            _SectionLabel(label: 'School(s) (Optional)'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _schoolsController,
              hintText: 'e.g. Hilltop Academy, Sunrise School',
              maxLines: 2,
            ),

            const SizedBox(height: 40),
            AppButton(text: 'Continue', onPressed: _onContinue),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: _gradeRanges.length,
      itemBuilder: (context, index) {
        final grade = _gradeRanges[index];
        final isSelected = _selectedGrades.contains(grade);
        return GestureDetector(
          onTap: () => setState(() {
            isSelected ? _selectedGrades.remove(grade) : _selectedGrades.add(grade);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.greyLight,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Center(
              child: Text(
                grade,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textHeadline,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────
// SCREEN 3: Goal Selection / Personalization
// ─────────────────────────────────────────────

class TeacherPersonalizationScreen extends ConsumerStatefulWidget {
  const TeacherPersonalizationScreen({super.key});

  @override
  ConsumerState<TeacherPersonalizationScreen> createState() => _TeacherPersonalizationScreenState();
}

class _TeacherPersonalizationScreenState extends ConsumerState<TeacherPersonalizationScreen> {
  final Set<String> _selectedGoals = {};

  final List<_GoalOption> _goals = const [
    _GoalOption(
      title: 'Share My Knowledge',
      subtitle: 'Create courses and lessons for students to learn from.',
      icon: Icons.lightbulb_outline,
    ),
    _GoalOption(
      title: 'Earn Extra Income',
      subtitle: 'Monetize your expertise by teaching on FEMA.',
      icon: Icons.monetization_on_outlined,
    ),
    _GoalOption(
      title: 'Professional Growth',
      subtitle: 'Develop your skills and grow as an educator.',
      icon: Icons.trending_up_outlined,
    ),
    _GoalOption(
      title: 'Reach Remote Students',
      subtitle: 'Help students who lack access to quality education.',
      icon: Icons.people_outline,
    ),
  ];

  void _onContinue() {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one goal')),
      );
      return;
    }
    ref.read(onboardingProvider.notifier).setPersonalizationAnswers(
      usesDigitalTools: 'Yes',
      sharesContent: _selectedGoals.join(', '),
    );
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go('/teacher/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: OnboardingProgressHeader(
        currentStep: 3,
        totalSteps: 3,
        showSkip: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'What is your main goal\nfor teaching on FEMA?',
              style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply — this helps us personalize your dashboard.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 32),
            ..._goals.map((goal) {
              final isSelected = _selectedGoals.contains(goal.title);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () => setState(() {
                    isSelected ? _selectedGoals.remove(goal.title) : _selectedGoals.add(goal.title);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.greyLight,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            goal.icon,
                            color: isSelected ? Colors.white : AppColors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : AppColors.textHeadline,
                                ),
                              ),
                              Text(
                                goal.subtitle,
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppColors.primary : AppColors.greyLight,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            AppButton(text: 'Get Started', onPressed: _onContinue),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _GoalOption {
  final String title;
  final String subtitle;
  final IconData icon;
  const _GoalOption({required this.title, required this.subtitle, required this.icon});
}


// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
