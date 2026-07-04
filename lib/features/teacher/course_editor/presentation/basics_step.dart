import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';

/// Immutable data bag that the BasicsStep surfaces to its parent.
/// [subject] is the lowercase Firestore string (e.g. 'science').
class BasicsData {
  final String title;
  final String description;
  final String subject;
  final String grade;
  final List<String> learningObjectives;

  const BasicsData({
    required this.title,
    required this.description,
    required this.subject,
    required this.grade,
    required this.learningObjectives,
  });
}

// ---------------------------------------------------------------------------
// Subject helpers
// ---------------------------------------------------------------------------

const _subjectEntries = [
  ('Math', 'math'),
  ('Science', 'science'),
  ('English', 'english'),
  ('Social Studies', 'socialstudies'),
  ('Amharic', 'amharic'),
  ('Other', 'other'),
];

// ---------------------------------------------------------------------------
// Grades
// ---------------------------------------------------------------------------

final _grades = List.generate(12, (i) => 'Grade ${i + 1}');

// ---------------------------------------------------------------------------
// BasicsStep
// ---------------------------------------------------------------------------

class BasicsStep extends StatefulWidget {
  final BasicsData? initial;
  final Future<void> Function(BasicsData) onSubmit;

  const BasicsStep({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  @override
  State<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends State<BasicsStep> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _subject; // lowercase firestore value
  String? _grade;

  // Each objective: controller + focus node pair
  final List<TextEditingController> _objControllers = [];
  final List<FocusNode> _objFocusNodes = [];

  bool _submitting = false;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _subject != null &&
      _grade != null &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChange);
    _descriptionController.addListener(_onFieldChange);

    final init = widget.initial;
    if (init != null) {
      _titleController.text = init.title;
      _descriptionController.text = init.description;
      _subject = init.subject.isEmpty ? null : init.subject;
      // Only set _grade if the value is actually one of the dropdown items;
      // otherwise leave null so the hint shows instead of crashing DropdownButton.
      _grade = _grades.contains(init.grade) ? init.grade : null;
      for (final obj in init.learningObjectives) {
        _addObjectiveRow(text: obj);
      }
    }
  }

  void _onFieldChange() => setState(() {});

  void _addObjectiveRow({String text = '', bool autofocus = false}) {
    final ctrl = TextEditingController(text: text);
    final focus = FocusNode();
    ctrl.addListener(_onFieldChange);
    setState(() {
      _objControllers.add(ctrl);
      _objFocusNodes.add(focus);
    });
    if (autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
    }
  }

  void _removeObjectiveRow(int index) {
    _objControllers[index].removeListener(_onFieldChange);
    _objControllers[index].dispose();
    _objFocusNodes[index].dispose();
    setState(() {
      _objControllers.removeAt(index);
      _objFocusNodes.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _objControllers) {
      c.dispose();
    }
    for (final f in _objFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final objectives = _objControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await widget.onSubmit(BasicsData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _subject!,
        grade: _grade!,
        learningObjectives: objectives,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.figtree(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
      );

  Widget _pillContainer({required Widget child}) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.greyLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Course title ──────────────────────────────────────────────────
          _sectionLabel('Course title'),
          const SizedBox(height: 8),
          _pillContainer(
            child: Center(
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g. Chemistry: Matter Around Us',
                  hintStyle: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                  isDense: true,
                  isCollapsed: true,
                ),
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Subject ──────────────────────────────────────────────────────
          _sectionLabel('Subject'),
          const SizedBox(height: 8),
          _pillContainer(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _subject,
                isExpanded: true,
                hint: Text(
                  'Choose a subject',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.grey,
                ),
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.textBody,
                ),
                onChanged: (v) => setState(() => _subject = v),
                items: _subjectEntries
                    .map((e) => DropdownMenuItem(
                          value: e.$2,
                          child: Text(e.$1),
                        ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Grade ─────────────────────────────────────────────────────────
          _sectionLabel('Grade'),
          const SizedBox(height: 8),
          _pillContainer(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _grade,
                isExpanded: true,
                hint: Text(
                  'Choose a grade',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.grey,
                ),
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.textBody,
                ),
                onChanged: (v) => setState(() => _grade = v),
                items: _grades
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g),
                        ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Description ───────────────────────────────────────────────────
          _sectionLabel('Description'),
          const SizedBox(height: 8),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'What students will learn in this course…',
                hintStyle: GoogleFonts.figtree(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
                isDense: true,
                isCollapsed: true,
              ),
              style: GoogleFonts.figtree(
                fontSize: 14,
                color: AppColors.textBody,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Learning objectives ───────────────────────────────────────────
          _sectionLabel('What students will learn (optional)'),
          const SizedBox(height: 8),

          // Existing objective rows
          for (var i = 0; i < _objControllers.length; i++) ...[
            _ObjectiveRow(
              controller: _objControllers[i],
              focusNode: _objFocusNodes[i],
              onRemove: () => _removeObjectiveRow(i),
            ),
            const SizedBox(height: 8),
          ],

          // Add objective button (max 5)
          if (_objControllers.length < 5)
            GestureDetector(
              onTap: () => _addObjectiveRow(autofocus: true),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add objective',
                      style: GoogleFonts.figtree(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ── Continue button ───────────────────────────────────────────────
          PillButton(
            label: 'Continue',
            enabled: _canSubmit,
            onPressed: _canSubmit ? _handleSubmit : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Objective row
// ---------------------------------------------------------------------------

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({
    required this.controller,
    required this.focusNode,
    required this.onRemove,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.greyLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                isCollapsed: true,
              ),
              style: GoogleFonts.figtree(
                fontSize: 13,
                color: AppColors.textBody,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 13,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
