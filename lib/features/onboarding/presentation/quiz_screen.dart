import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  final List<int?> _answers = List.filled(10, null);

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the value of x in the equation 2x + 5 = 11?',
      'options': ['3', '4', '6', '8'],
      'answer': 0,
    },
    {
      'question': 'What is the sum of the angles in a triangle?',
      'options': ['90°', '180°', '270°', '360°'],
      'answer': 1,
    },
    {
      'question': 'Which of these is a prime number?',
      'options': ['9', '15', '19', '21'],
      'answer': 2,
    },
    {
      'question': 'What is 25% of 80?',
      'options': ['15', '20', '25', '30'],
      'answer': 1,
    },
    {
      'question': 'If the ratio of boys to girls is 3:2 and there are 20 girls, how many boys are there?',
      'options': ['15', '25', '30', '40'],
      'answer': 2,
    },
    {
      'question': 'Which part of the plant is responsible for photosynthesis?',
      'options': ['Root', 'Stem', 'Leaf', 'Flower'],
      'answer': 2,
    },
    {
      'question': 'What is the standard unit of force?',
      'options': ['Joule', 'Watt', 'Newton', 'Pascal'],
      'answer': 2,
    },
    {
      'question': 'What is the chemical symbol for Oxygen?',
      'options': ['Ox', 'O', 'H', 'C'],
      'answer': 1,
    },
    {
      'question': 'Which organ pumps blood throughout the body?',
      'options': ['Brain', 'Lungs', 'Liver', 'Heart'],
      'answer': 3,
    },
    {
      'question': 'Which layer of the Earth is the outermost?',
      'options': ['Core', 'Mantle', 'Crust', 'Inner Core'],
      'answer': 2,
    },
  ];

  void _nextQuestion() {
    setState(() {
      _answers[_currentQuestionIndex] = _selectedOptionIndex;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _selectedOptionIndex = _answers[_currentQuestionIndex];
      } else {
        _completeQuiz();
      }
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedOptionIndex = _answers[_currentQuestionIndex];
      });
    }
  }

  void _completeQuiz() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['answer']) {
        score++;
      }
    }
    
    ref.read(onboardingProvider.notifier).setQuizScore(score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 64),
            const SizedBox(height: AppConstants.space16),
            Text(
              'You scored $score out of ${_questions.length}',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space8),
            const Text(
              'This helps us personalize your learning path.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AppButton(
            text: 'Finish',
            onPressed: () {
              Navigator.pop(context);
              context.push('/onboarding/intro');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 7, // Fixed step for placement test phase
        totalSteps: 7,
        showSkip: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              question['question'],
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppConstants.space32),
            ...List.generate(
              question['options'].length,
              (index) {
                final isSelected = _selectedOptionIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.space16),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOptionIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.space16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.radius12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.greyLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.grey,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.circle, size: 12, color: AppColors.primary),
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppConstants.space16),
                          Expanded(
                            child: Text(
                              question['options'][index],
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.space16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: AppConstants.space16),
                Expanded(
                  child: AppButton(
                    text: _currentQuestionIndex == _questions.length - 1 ? 'Finish' : 'Next',
                    onPressed: _selectedOptionIndex != null ? _nextQuestion : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space48),
          ],
        ),
      ),
    );
  }
}
