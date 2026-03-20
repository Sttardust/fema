import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../library/domain/library_provider.dart';
import '../../library/domain/models.dart';

class ContentEditorScreen extends ConsumerStatefulWidget {
  const ContentEditorScreen({super.key});

  @override
  ConsumerState<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends ConsumerState<ContentEditorScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basics
  final _titleController = TextEditingController();
  String _selectedSubject = 'Mathematics';
  String _selectedGrade = 'Grade 10';
  String _difficulty = 'Academic';

  // Step 2: Syllabus Context
  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Module 1: Getting Started',
      'lessons': ['Introduction to the topic'],
    }
  ];

  // Step 3: Settings
  bool _enableComments = true;
  bool _enableDownloads = true;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({required bool isPublish}) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course title is required on Step 1')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      
      final course = Course(
        id: '',
        title: _titleController.text,
        description: '${_difficulty == 'Academic' ? 'Academic' : 'General focus'} course created from the teacher editor.',
        subject: CourseSubject.values.firstWhere(
          (e) => e.name.toLowerCase() == _selectedSubject.toLowerCase(),
          orElse: () => CourseSubject.other,
        ),
        grade: _selectedGrade,
        thumbnailUrl: '', // Default or placeholder
        status: isPublish ? CourseStatus.published : CourseStatus.draft,
        lessons: _modules.expand((m) => (m['lessons'] as List<String>).map((title) => Lesson(
          id: '',
          title: title,
          description: '',
          contentHtml: '',
        ))).toList(),
      );

      await repository.saveCourse(course, isDraft: !isPublish);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPublish ? 'Course published!' : 'Draft saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _handleSave(isPublish: true);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Course Basics' 
          : _currentStep == 1 ? 'Syllabus Builder' 
          : 'Course Settings',
          style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () => _handleSave(isPublish: false),
              child: const Text('Save Draft', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Custom Progress Header
              _buildProgressHeader(),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: AppColors.primary),
                  ),
                  child: Stepper(
                    type: StepperType.horizontal,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    currentStep: _currentStep,
                    onStepTapped: (index) => setState(() => _currentStep = index),
                    onStepContinue: _nextStep,
                    onStepCancel: _prevStep,
                    controlsBuilder: (context, details) => const SizedBox.shrink(), // Custom bottom controls used instead
                    steps: [
                      Step(
                        title: const SizedBox.shrink(),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                        content: _buildStep1Basics(),
                      ),
                      Step(
                        title: const SizedBox.shrink(),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                        content: _buildStep2Syllabus(),
                      ),
                      Step(
                        title: const SizedBox.shrink(),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                        content: _buildStep3Settings(),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Controls
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.greyLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back', style: TextStyle(color: AppColors.textBody)),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: _currentStep == 2 ? 'Publish Course' : 'Continue',
                        onPressed: _nextStep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Step ${_currentStep + 1} of 3', style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontWeight: FontWeight.bold)),
          Text(
            _currentStep == 0 ? '10% complete' : _currentStep == 1 ? '50% complete' : '90% complete',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1 ───
  Widget _buildStep1Basics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Let's Get Your New Course Started!",
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Set the foundation for your curriculum.",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
        ),
        const SizedBox(height: 32),

        const _SectionLabel(label: 'Course Title'),
        const SizedBox(height: 8),
        AppTextField(
          controller: _titleController,
          hintText: 'e.g. Master Grade 10 Physics',
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(label: 'Category'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedSubject,
                    items: ['Mathematics', 'Science', 'English', 'Amharic', 'Social Studies'],
                    onChanged: (val) => setState(() => _selectedSubject = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(label: 'Target Grade'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedGrade,
                    items: ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
                    onChanged: (val) => setState(() => _selectedGrade = val!),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        const _SectionLabel(label: 'Difficulty Level'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToggleAction(
                label: 'Academic',
                isActive: _difficulty == 'Academic',
                onTap: () => setState(() => _difficulty = 'Academic'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToggleAction(
                label: 'General Focus',
                isActive: _difficulty == 'General',
                onTap: () => setState(() => _difficulty = 'General'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── STEP 2 ───
  Widget _buildStep2Syllabus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Syllabus Builder",
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Outline the structure of your course.",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
        ),
        const SizedBox(height: 24),

        ..._modules.map((module) {
          final lessons = module['lessons'] as List<String>;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.greyLight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Module Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator, color: AppColors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          module['title'],
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.grey),
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // Lessons
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...lessons.map((lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(lesson, style: AppTextStyles.bodySmall)),
                          ],
                        ),
                      )),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Lesson / Assignment'),
                        onPressed: () {
                          setState(() {
                            lessons.add('New Lesson ${lessons.length + 1}');
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        DottedBorderAddButton(
          label: 'Add New Module',
          onTap: () {
            setState(() {
              _modules.add({
                'title': 'Module ${_modules.length + 1}',
                'lessons': [],
              });
            });
          },
        ),
      ],
    );
  }

  // ─── STEP 3 ───
  Widget _buildStep3Settings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Course Settings",
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Finalize your course interactivity and availability.",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
        ),
        const SizedBox(height: 32),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.greyLight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Enable Q&A and Comments', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Allow students to ask questions inside lessons.', style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                value: _enableComments,
                onChanged: (v) => setState(() => _enableComments = v),
                activeThumbColor: AppColors.primary,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text('Enable Offline Downloads', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Students can download materials to view offline.', style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                value: _enableDownloads,
                onChanged: (v) => setState(() => _enableDownloads = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        // Preview Card
        Text('Preview', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 80, height: 60,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.school, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleController.text.isEmpty ? 'Untitled Course' : _titleController.text, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$_selectedGrade • $_selectedSubject', style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.greyLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.greyLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

// ─── HELPERS ───

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600));
  }
}

class _ToggleAction extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleAction({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.greyLight, width: isActive ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textHeadline,
          ),
        ),
      ),
    );
  }
}

class DottedBorderAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DottedBorderAddButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          // Custom dotted border emulation via Dash decoration if available, else simple outline
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
