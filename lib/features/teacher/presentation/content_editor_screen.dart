import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedSubject = 'Mathematics';
  String _selectedGrade = 'Grade 10';
  bool _isLoading = false;

  Future<void> _handleSave({required bool isDraft}) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      
      final course = Course(
        id: '', // New course
        title: _titleController.text,
        description: _descriptionController.text,
        subject: _parseSubject(_selectedSubject),
        grade: _selectedGrade,
        thumbnailUrl: '', // Default or placeholder
        lessons: [
          Lesson(
            id: '',
            title: 'First Lesson',
            description: 'Main content',
            contentHtml: _contentController.text,
          ),
        ],
      );

      await repository.saveCourse(course, isDraft: isDraft);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isDraft ? 'Draft saved!' : 'Course published!')),
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

  CourseSubject _parseSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return CourseSubject.math;
      case 'science': return CourseSubject.science;
      case 'english': return CourseSubject.english;
      case 'amharic': return CourseSubject.amharic;
      case 'social studies': return CourseSubject.socialStudies;
      default: return CourseSubject.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Content'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () => _handleSave(isDraft: true),
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Course Basics', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppConstants.space16),
                AppTextField(
                  controller: _titleController,
                  labelText: 'Course Title',
                  hintText: 'e.g. Introduction to Physics',
                ),
                const SizedBox(height: AppConstants.space16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Subject',
                        value: _selectedSubject,
                        items: ['Mathematics', 'Science', 'English', 'Amharic', 'Social Studies'],
                        onChanged: (val) => setState(() => _selectedSubject = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Grade',
                        value: _selectedGrade,
                        items: ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'],
                        onChanged: (val) => setState(() => _selectedGrade = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space24),
                Text('Description', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppConstants.space12),
                AppTextField(
                  controller: _descriptionController,
                  labelText: 'Summary',
                  hintText: 'Briefly describe what students will learn...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppConstants.space24),
                Text('Lesson Content', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppConstants.space12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyLight),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: Column(
                    children: [
                      _EditorToolbar(),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 15,
                          decoration: const InputDecoration(
                            hintText: 'Start writing your lesson here...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.space32),
                AppButton(
                  text: 'Publish Course',
                  onPressed: () => _handleSave(isDraft: false),
                ),
                const SizedBox(height: AppConstants.space24),
              ],
            ),
          ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.greyLight.withValues(alpha: 0.2),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.format_bold, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.format_italic, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.format_list_bulleted, size: 20), onPressed: () {}),
          const VerticalDivider(),
          IconButton(icon: const Icon(Icons.link, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.image_outlined, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.video_collection_outlined, size: 20), onPressed: () {}),
        ],
      ),
    );
  }
}
