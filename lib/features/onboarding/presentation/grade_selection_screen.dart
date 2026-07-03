import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../domain/onboarding_provider.dart';

class GradeSelectionScreen extends ConsumerStatefulWidget {
  const GradeSelectionScreen({super.key});

  @override
  ConsumerState<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends ConsumerState<GradeSelectionScreen> {
  String? _selectedGrade;
  bool _isSubmitting = false;
  final List<String> _primaryGrades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];
  final List<String> _secondaryGrades = ['Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];

  void _onContinue() {
    if (_selectedGrade == null) return;

    if (_selectedGrade == 'Grade 1' ||
        _selectedGrade == 'Grade 2' ||
        _selectedGrade == 'Grade 3') {
      _showParentalModal();
    } else {
      _finishWithGrade();
    }
  }

  void _finishWithGrade() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      ref.read(onboardingProvider.notifier).setGrade(_selectedGrade!);
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showParentalModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Parental Assistance',
          style: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textBody,
          ),
        ),
        content: Text(
          'For foundation years, we recommend completing the setup with a parent or guardian to ensure the best experience.',
          style: GoogleFonts.figtree(
            fontSize: 13.5,
            color: AppColors.grey,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Change Grade',
              style: GoogleFonts.figtree(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishWithGrade();
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'I Understand',
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button row
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.space24,
                top: 16,
                right: AppConstants.space24,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: AppColors.textBody,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'What grade are you in?',
                      style: GoogleFonts.figtree(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We'll personalize your library with courses for your grade.",
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        color: AppColors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Primary Education section
                    _buildSectionLabel('PRIMARY EDUCATION'),
                    const SizedBox(height: 12),
                    _buildGradeGrid(_primaryGrades),

                    const SizedBox(height: 28),

                    // Secondary Education section
                    _buildSectionLabel('SECONDARY EDUCATION'),
                    const SizedBox(height: 12),
                    _buildGradeGrid(_secondaryGrades),

                    const SizedBox(height: 36),
                    PillButton(
                      label: 'Continue',
                      onPressed: (_selectedGrade != null && !_isSubmitting) ? _onContinue : null,
                      enabled: _selectedGrade != null && !_isSubmitting,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGradeGrid(List<String> grades) {
    // Build rows of 3
    final rows = <Widget>[];
    for (var i = 0; i < grades.length; i += 3) {
      final rowGrades = grades.sublist(i, (i + 3).clamp(0, grades.length));
      rows.add(
        Row(
          children: rowGrades.asMap().entries.map((entry) {
            final idx = entry.key;
            final grade = entry.value;
            final isSelected = _selectedGrade == grade;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: idx > 0 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGrade = grade),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.greyLight,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        grade,
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textBody,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
      if (i + 3 < grades.length) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return Column(children: rows);
  }
}
