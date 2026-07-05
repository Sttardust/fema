import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/class_repository.dart';

const _subjectEntries = [
  ('Math', 'math'),
  ('Science', 'science'),
  ('English', 'english'),
  ('Social Studies', 'socialstudies'),
  ('Amharic', 'amharic'),
  ('Other', 'other'),
];

final _grades = List.generate(12, (i) => 'Grade ${i + 1}');

Future<void> showClassCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: MediaQuery.of(ctx).viewInsets,
      child: const _ClassCreateSheet(),
    ),
  );
}

class _ClassCreateSheet extends ConsumerStatefulWidget {
  const _ClassCreateSheet();

  @override
  ConsumerState<_ClassCreateSheet> createState() => _ClassCreateSheetState();
}

class _ClassCreateSheetState extends ConsumerState<_ClassCreateSheet> {
  final _nameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  String? _subject;
  String? _grade;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  bool get _canCreate => _subject != null && _grade != null && !_saving;

  Future<void> _create() async {
    if (!_canCreate) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in. Please sign in and try again.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(teacherClassRepositoryProvider).createClass(
            teacherId: uid,
            subject: _subject!,
            grade: _grade!,
            name: _nameCtrl.text.trim(),
            section: _sectionCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't create class. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Text(
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
        child: Center(child: child),
      );

  Widget _pillField({required TextEditingController controller, required String hint}) =>
      _pillContainer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey),
            isDense: true,
            isCollapsed: true,
          ),
          style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
        ),
      );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) =>
      _pillContainer(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(
              hint,
              style: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
            style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
            onChanged: onChanged,
            items: items,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New class',
                style: GoogleFonts.figtree(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 20),
              _label('Subject'),
              const SizedBox(height: 8),
              _dropdown(
                value: _subject,
                hint: 'Choose a subject',
                items: _subjectEntries
                    .map((e) => DropdownMenuItem(value: e.$2, child: Text(e.$1)))
                    .toList(),
                onChanged: (v) => setState(() => _subject = v),
              ),
              const SizedBox(height: 16),
              _label('Grade'),
              const SizedBox(height: 8),
              _dropdown(
                value: _grade,
                hint: 'Choose a grade',
                items: _grades
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _grade = v),
              ),
              const SizedBox(height: 16),
              _label('Class name (optional)'),
              const SizedBox(height: 8),
              _pillField(
                controller: _nameCtrl,
                hint: 'e.g. Math Grade 7 — auto-named if empty',
              ),
              const SizedBox(height: 16),
              _label('Section (optional)'),
              const SizedBox(height: 8),
              _pillField(controller: _sectionCtrl, hint: 'e.g. A'),
              const SizedBox(height: 24),
              PillButton(
                label: _saving ? 'Creating…' : 'Create class',
                enabled: _canCreate,
                onPressed: _canCreate ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
