import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../widgets/cards/dashboard_card.dart';
import '../widgets/cards/dashboard_card_body.dart';
import '../widgets/cards/dashboard_card_header.dart';
import '../widgets/cards/status_chip.dart';

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  final NotificationService _service = const NotificationService();

  late Future<List<NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _future = _service.getNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadNotifications();
    });

    await _future;
  }

  StatusChipState _chipState(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return StatusChipState.healthy;

      case NotificationType.info:
        return StatusChipState.inactive;

      case NotificationType.warning:
        return StatusChipState.warning;

      case NotificationType.error:
        return StatusChipState.error;
    }
  }

  String _chipLabel(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'SUCCESS';

      case NotificationType.info:
        return 'INFO';

      case NotificationType.warning:
        return 'WARNING';

      case NotificationType.error:
        return 'ALERT';
    }
  }

  IconData _leadingIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;

      case NotificationType.info:
        return Icons.info;

      case NotificationType.warning:
        return Icons.warning_amber;

      case NotificationType.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: FutureBuilder<List<NotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardCardHeader(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  trailing: IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Unable to load notifications.'),
              ],
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Column(
              children: [
                DashboardCardHeader(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  trailing: IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('No notifications available.'),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardCardHeader(
                title: 'Notifications',
                subtitle: 'Latest fleet and system events',
                icon: Icons.notifications,
                trailing: IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ),

              const SizedBox(height: 20),

              DashboardCardBody(
                spacing: 16,
                children: notifications.map((notification) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _leadingIcon(notification.type),
                        size: 22,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      StatusChip(
                        label: _chipLabel(notification.type),
                        state: _chipState(notification.type),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}