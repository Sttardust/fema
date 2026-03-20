import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../domain/class_models.dart';
import '../domain/class_repository.dart';

class ClassManagementScreen extends ConsumerWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student enrollment flow is next to implement.')),
              );
            },
          ),
        ],
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return _EmptyState(onAddPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create classes in Firestore to populate this screen.')),
              );
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClassStats(classes: classes),
                const SizedBox(height: AppConstants.space24),
                Text('Your Classes', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppConstants.space12),
                _ClassList(classes: classes),
                const SizedBox(height: AppConstants.space24),
                Text('Recent Activity', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppConstants.space12),
                _RecentActivity(classes: classes),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load classes: $error')),
      ),
    );
  }
}

class _ClassStats extends StatelessWidget {
  const _ClassStats({required this.classes});

  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    final totalStudents = classes.fold<int>(0, (sum, item) => sum + item.studentCount);
    final averageAttendance = classes.isEmpty
        ? 0.0
        : classes.fold<double>(0, (sum, item) => sum + item.attendanceRate) / classes.length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Students',
            count: '$totalStudents',
            icon: Icons.people_outline,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Attendance',
            count: '${averageAttendance.toStringAsFixed(0)}%',
            icon: Icons.calendar_today_outlined,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _ClassList extends StatelessWidget {
  const _ClassList({required this.classes});

  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: classes.map((teacherClass) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius12),
            side: BorderSide(color: AppColors.greyLight),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                title: Text(
                  teacherClass.name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${teacherClass.studentCount} Students • Avg Score: ${teacherClass.averageScore.toStringAsFixed(0)}%',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStudentDetails(context, teacherClass),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAttendanceDialog(context, teacherClass),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Take Attendance'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAttendanceDialog(BuildContext context, TeacherClass teacherClass) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AttendanceSheet(teacherClass: teacherClass),
    );
  }

  void _showStudentDetails(BuildContext context, TeacherClass teacherClass) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _StudentListSheet(teacherClass: teacherClass),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.classes});

  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    final activity = classes.take(3).map((teacherClass) {
      return {
        'msg': 'Loaded ${teacherClass.studentCount} students for ${teacherClass.name}',
        'time': 'Live',
      };
    }).toList();

    return Column(
      children: activity.map((act) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(act['msg']!, style: AppTextStyles.bodySmall),
                    Text(act['time']!, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance: ${widget.teacherClass.name}',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.teacherClass.students.map((student) {
            return SwitchListTile(
              title: Text(student.name),
              subtitle: Text(student.grade),
              value: _attendance[student.id] ?? true,
              onChanged: (val) => setState(() => _attendance[student.id] = val),
              activeThumbColor: AppColors.primary,
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Attendance', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StudentListSheet extends StatelessWidget {
  const _StudentListSheet({required this.teacherClass});

  final TeacherClass teacherClass;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Students: ${teacherClass.name}',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.separated(
              itemCount: teacherClass.students.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final student = teacherClass.students[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    student.name,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Avg Score: ${student.averageScore.toStringAsFixed(0)} • Attendance: ${student.attendanceRate.toStringAsFixed(0)}%',
                    style: AppTextStyles.caption,
                  ),
                  trailing: TextButton(
                    onPressed: () => _showDetailDialog(context, student),
                    child: const Text('View Profile'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ClassStudent student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('Grade', student.grade),
            _detailItem('Average Score', '${student.averageScore.toStringAsFixed(0)}%'),
            _detailItem('Attendance Rate', '${student.attendanceRate.toStringAsFixed(0)}%'),
            _detailItem(
              'Learning Goals',
              student.learningGoals.isEmpty ? 'No learning goals recorded' : student.learningGoals.join(', '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              'No classes found',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add class documents under the Firestore `classes` collection with a matching `teacherId`.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.info_outline),
              label: const Text('Setup Hint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(count, style: AppTextStyles.headlineSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
        ],
      ),
    );
  }
}
