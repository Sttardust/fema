import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models.dart';

// Mock Provider for Notifications
final notificationsProvider = StateProvider<List<AppNotification>>((ref) {
  return [
    AppNotification(
      id: '1',
      title: 'Welcome to FEMA!',
      body: 'Get started by exploring our courses in the library.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.update,
    ),
    AppNotification(
      id: '2',
      title: 'New Math Content Available',
      body: 'Grade 8 Algebra Part 2 has been added.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.message,
      actionRoute: '/library',
    ),
    AppNotification(
      id: '3',
      title: 'Quiz Reminder',
      body: 'Don\'t forget to complete your placement quiz!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.alert,
      isRead: true,
    ),
  ];
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.space16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _NotificationTile(notification: notifications[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.greyLight),
          const SizedBox(height: AppConstants.space16),
          Text(
            'No notifications yet',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: notification.isRead ? AppColors.greyLight : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingIcon(),
          const SizedBox(width: AppConstants.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(notification.timestamp),
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.message:
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
      case NotificationType.alert:
        icon = Icons.warning_amber_outlined;
        color = Colors.orange;
        break;
      case NotificationType.achievement:
        icon = Icons.emoji_events_outlined;
        color = Colors.amber;
        break;
      case NotificationType.update:
      default:
        icon = Icons.info_outline;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
