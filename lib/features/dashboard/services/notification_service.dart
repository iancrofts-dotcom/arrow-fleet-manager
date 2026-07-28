import '../models/notification_item.dart';

class NotificationService {
  const NotificationService();

  Future<List<NotificationItem>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    return [
      NotificationItem(
        id: '1',
        title: 'MOT Expiring',
        message: 'Vehicle AB12 CDE requires an MOT within 7 days.',
        type: NotificationType.warning,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationItem(
        id: '2',
        title: 'Insurance Renewal',
        message: 'Insurance policy for Vehicle XY34 ZYX expires in 14 days.',
        type: NotificationType.warning,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: '3',
        title: 'Driver Added',
        message: 'A new driver has been successfully added to the fleet.',
        type: NotificationType.success,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      NotificationItem(
        id: '4',
        title: 'Inspection Overdue',
        message: 'Vehicle LM56 NOP has an overdue daily inspection.',
        type: NotificationType.error,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationItem(
        id: '5',
        title: 'System Backup',
        message: 'Nightly database backup completed successfully.',
        type: NotificationType.info,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }

  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();

    return notifications.where((notification) => !notification.isRead).length;
  }
}