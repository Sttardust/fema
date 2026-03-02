import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models.dart';

import '../../auth/domain/auth_repository.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/models.dart';

// Stream Provider for Notifications
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = authRepo.currentUser;

  if (user == null) return Stream.value([]);

  return firestoreService.getUserNotifications(user.uid).map((list) {
    return list.map((data) => AppNotification(
      id: data['id'],
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _parseNotificationType(data['type']),
      isRead: data['isRead'] ?? false,
      actionRoute: data['actionRoute'],
    )).toList();
  });
});

NotificationType _parseNotificationType(String? type) {
  switch (type?.toLowerCase()) {
    case 'message': return NotificationType.message;
    case 'alert': return NotificationType.alert;
    case 'achievement': return NotificationType.achievement;
    default: return NotificationType.update;
  }
}

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
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(AppConstants.space16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _NotificationTile(notification: notifications[index]);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
