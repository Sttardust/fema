import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../domain/class_models.dart';
import '../domain/class_repository.dart';

// ─── Local tab state (students=0, attendance=1) per-class ───
final _classManagementTabProvider = StateProvider<int>((ref) => 0);

class ClassManagementScreen extends ConsumerWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Class Management',
          style: GoogleFonts.figtree(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textBody,
          ),
        ),
        centerTitle: false,
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return EmptyStateView(
              icon: Icons.school_outlined,
              message: 'No classes yet',
              action: PillButton.outlined(
                label: 'Setup Hint',
                icon: Icons.info_outline,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add class documents under the Firestore `classes` collection with a matching `teacherId`.',
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return _ClassManagementBody(classes: classes);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => ErrorStateView(
          message: "Couldn't load classes",
          onRetry: () => ref.invalidate(teacherClassesProvider),
        ),
      ),
    );
  }
}

// ─── Main body (classes exist) ───
class _ClassManagementBody extends ConsumerWidget {
  const _ClassManagementBody({required this.classes});
  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentIndex = ref.watch(_classManagementTabProvider);

    final totalStudents = classes.fold<int>(0, (sum, c) => sum + c.studentCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats summary ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.school,
                  value: '${classes.length}',
                  label: 'Classes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.people,
                  value: '$totalStudents',
                  label: 'Students',
                ),
              ),
            ],
          ),
        ),

        // ── Segmented control ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _SegmentedControl(
            currentIndex: segmentIndex,
            onTap: (i) =>
                ref.read(_classManagementTabProvider.notifier).state = i,
          ),
        ),

        const SizedBox(height: 16),

        // ── Content area ──
        Expanded(
          child: segmentIndex == 0
              ? _StudentsTab(classes: classes)
              : _AttendanceTab(classes: classes),
        ),
      ],
    );
  }
}

// ─── Segmented control ───
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Segment(label: 'Students', isActive: currentIndex == 0, onTap: () => onTap(0)),
          _Segment(label: 'Attendance', isActive: currentIndex == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Students Tab ───
// Groups students by class with a section header above each class's rows.
// A student enrolled in multiple classes will appear under each one — correct.
class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.classes});
  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    final hasStudents = classes.any((c) => c.students.isNotEmpty);

    // Build a flat list of items: each class contributes a header + N rows.
    // Items are either _ClassHeader or ClassStudent (with the class name attached).
    final List<_StudentListItem> items = [];
    for (final cls in classes) {
      items.add(_ClassHeader(className: cls.name, studentCount: cls.studentCount));
      for (final student in cls.students) {
        items.add(_StudentEntry(student: student, className: cls.name));
      }
    }

    return Column(
      children: [
        Expanded(
          child: !hasStudents
              ? const EmptyStateView(
                  icon: Icons.people_outline,
                  message: 'No students yet',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _ClassHeader) {
                      return _ClassSectionHeader(
                        className: item.className,
                        studentCount: item.studentCount,
                      );
                    } else if (item is _StudentEntry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StudentRow(
                          student: item.student,
                          onMoreTap: () =>
                              _showStudentDetail(context, item.student),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
        // ── Add student button ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: PillButton(
            label: 'Add student',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student enrollment flow is next to implement.'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showStudentDetail(BuildContext context, ClassStudent student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          student.name,
          style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem(context, 'Grade', student.grade),
            _detailItem(context, 'Average Score', '${student.averageScore.toStringAsFixed(0)}%'),
            _detailItem(context, 'Attendance Rate', '${student.attendanceRate.toStringAsFixed(0)}%'),
            _detailItem(
              context,
              'Learning Goals',
              student.learningGoals.isEmpty
                  ? 'No learning goals recorded'
                  : student.learningGoals.join(', '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.figtree(fontSize: 13, color: AppColors.textBody),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// ─── List item types for grouped student list ───
abstract class _StudentListItem {}

class _ClassHeader extends _StudentListItem {
  final String className;
  final int studentCount;
  _ClassHeader({required this.className, required this.studentCount});
}

class _StudentEntry extends _StudentListItem {
  final ClassStudent student;
  final String className;
  _StudentEntry({required this.student, required this.className});
}

// ─── Class section header widget ───
class _ClassSectionHeader extends StatelessWidget {
  const _ClassSectionHeader({
    required this.className,
    required this.studentCount,
  });
  final String className;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            className.toUpperCase(),
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$studentCount/${studentCount > 0 ? studentCount : 0}',
            style: GoogleFonts.figtree(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.onMoreTap});
  final ClassStudent student;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final initial = student.name.isNotEmpty ? student.name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.grade,
                  style: GoogleFonts.figtree(
                    fontSize: 11.5,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onMoreTap,
            child: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendance Tab ───
class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.classes});
  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const EmptyStateView(
        icon: Icons.school_outlined,
        message: 'No classes yet',
      );
    }

    // Show per-class attendance sections
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        return _ClassAttendanceSection(teacherClass: cls);
      },
    );
  }
}

class _ClassAttendanceSection extends StatelessWidget {
  const _ClassAttendanceSection({required this.teacherClass});
  final TeacherClass teacherClass;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day}/${now.month}/${now.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class name header
          Text(
            teacherClass.name,
            style: GoogleFonts.figtree(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 6),
          // Date row
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
              const Spacer(),
              Text(
                '${teacherClass.studentCount} students',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Take attendance CTA
          SoftCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onTap: () => _showAttendanceSheet(context, teacherClass),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Take attendance for ${teacherClass.name}',
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceSheet(BuildContext context, TeacherClass teacherClass) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AttendanceSheet(teacherClass: teacherClass),
    );
  }
}

// ─── Attendance Sheet ───
class _AttendanceSheet extends ConsumerStatefulWidget {
  const _AttendanceSheet({required this.teacherClass});
  final TeacherClass teacherClass;

  @override
  ConsumerState<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends ConsumerState<_AttendanceSheet> {
  late final Map<String, bool> _attendance = {
    for (final student in widget.teacherClass.students) student.id: true,
  };
  bool _isSaving = false;

  int get _markedCount =>
      _attendance.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final students = widget.teacherClass.students;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacherClass.name,
                    style: GoogleFonts.figtree(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Date + marked count row
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formattedToday(),
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBody,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$_markedCount of ${students.length} marked',
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Student attendance rows
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: students.length,
              separatorBuilder: (context2, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final student = students[index];
                final isPresent = _attendance[student.id] ?? true;
                final initial = student.name.isNotEmpty
                    ? student.name[0].toUpperCase()
                    : '?';

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: GoogleFonts.figtree(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textBody,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.grade,
                              style: GoogleFonts.figtree(
                                fontSize: 11.5,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                          () => _attendance[student.id] = !isPresent,
                        ),
                        child: Icon(
                          isPresent
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          size: 24,
                          color: isPresent ? AppColors.primary : AppColors.greyLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Save button — shows 'Saving…' while in-flight; shows error SnackBar on failure
          PillButton(
            label: _isSaving ? 'Saving…' : 'Save attendance',
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    try {
                      await ref.read(teacherClassRepositoryProvider).saveAttendance(
                            widget.teacherClass.id,
                            _attendance,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to save attendance: $e',
                                style: GoogleFonts.figtree(fontSize: 13),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    } finally {
                      if (mounted && _isSaving) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

// ─── Summary Tile ───
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.figtree(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

