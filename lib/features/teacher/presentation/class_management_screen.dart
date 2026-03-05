import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firestore_service.dart';

class ClassManagementScreen extends ConsumerWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              // TODO: Implement add student logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(),
            const SizedBox(height: AppConstants.space24),
            Text('Your Classes', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.space12),
            _buildClassList(context, ref),
            const SizedBox(height: AppConstants.space24),
            Text('Recent Activity', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.space12),
            _buildActivityLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        const Expanded(
          child: _StatCard(
            title: 'Students',
            count: '124',
            icon: Icons.people_outline,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Attendance',
            count: '98%',
            icon: Icons.calendar_today_outlined,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildClassList(BuildContext context, WidgetRef ref) {
    final classes = [
      {'id': 'math10a', 'name': 'Grade 10 Math - Section A', 'students': '32', 'avgScore': '84%'},
      {'id': 'sci9b', 'name': 'Grade 9 Science - Section B', 'students': '45', 'avgScore': '78%'},
      {'id': 'amh10c', 'name': 'Grade 10 Amharic - Section C', 'students': '28', 'avgScore': '92%'},
    ];

    return Column(
      children: classes.map((cls) => Card(
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
              title: Text(cls['name']!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('${cls['students']} Students • Avg Score: ${cls['avgScore']}', style: AppTextStyles.caption),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showStudentDetails(context, cls['name']!),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAttendanceDialog(context, ref, cls['id']!, cls['name']!),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Take Attendance'),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _showAttendanceDialog(BuildContext context, WidgetRef ref, String classId, String className) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AttendanceSheet(classId: classId, className: className),
    );
  }

  void _showStudentDetails(BuildContext context, String className) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _StudentListSheet(className: className),
    );
  }

  Widget _buildActivityLog() {
    final activity = [
      {'msg': 'Abebe Kebe completed Quiz 4', 'time': '2h ago'},
      {'msg': 'New student added to Grade 10 Math', 'time': '5h ago'},
      {'msg': 'Weekly progress report sent to Parents', 'time': 'Yesterday'},
    ];

    return Column(
      children: activity.map((act) => Padding(
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
      )).toList(),
    );
  }
}

class _AttendanceSheet extends ConsumerStatefulWidget {
  final String classId;
  final String className;
  const _AttendanceSheet({required this.classId, required this.className});

  @override
  ConsumerState<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends ConsumerState<_AttendanceSheet> {
  final Map<String, bool> _attendance = {
    'Abebe Kebe': true,
    'Sara Yosef': true,
    'Dawit Tekle': false,
    'Marta Haile': true,
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
              Text('Attendance: ${widget.className}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          ..._attendance.keys.map((name) => SwitchListTile(
            title: Text(name),
            value: _attendance[name]!,
            onChanged: (val) => setState(() => _attendance[name] = val),
            activeThumbColor: AppColors.primary,
          )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                setState(() => _isSaving = true);
                try {
                  await ref.read(firestoreServiceProvider).saveAttendance(widget.classId, DateTime.now(), _attendance);
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
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
  final String className;
  const _StudentListSheet({required this.className});

  @override
  Widget build(BuildContext context) {
    final students = [
      {'name': 'Abebe Kebe', 'avg': '88%', 'attendance': '95%'},
      {'name': 'Sara Yosef', 'avg': '92%', 'attendance': '100%'},
      {'name': 'Dawit Tekle', 'avg': '76%', 'attendance': '85%'},
      {'name': 'Marta Haile', 'avg': '82%', 'attendance': '98%'},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Students: $className', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(student['name']!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('Avg Score: ${student['avg']} • Attendance: ${student['attendance']}', style: AppTextStyles.caption),
                  trailing: TextButton(
                    onPressed: () {
                      _showDetailDialog(context, student);
                    },
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

  void _showDetailDialog(BuildContext context, Map<String, String> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['name']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('Grade', '10'),
            _detailItem('Average Score', student['avg']!),
            _detailItem('Attendance Rate', student['attendance']!),
            _detailItem('Learning Goals', 'Master Trigonometry, Improve Essay Writing'),
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
      padding: const EdgeInsets.only(bottom: 8.0),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

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
