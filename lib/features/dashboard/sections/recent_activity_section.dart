import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import '../services/activity_service.dart';
import '../widgets/cards/dashboard_card.dart';
import '../widgets/cards/dashboard_card_body.dart';
import '../widgets/cards/dashboard_card_header.dart';

class RecentActivitySection extends StatefulWidget {
  const RecentActivitySection({super.key});

  @override
  State<RecentActivitySection> createState() =>
      _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  final ActivityService _service = const ActivityService();

  late Future<List<ActivityItem>> _future;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  void _loadActivity() {
    _future = _service.getRecentActivity();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadActivity();
    });

    await _future;
  }

  IconData _icon(ActivityType type) {
    switch (type) {
      case ActivityType.vehicle:
        return Icons.directions_car;

      case ActivityType.driver:
        return Icons.person;

      case ActivityType.maintenance:
        return Icons.build;

      case ActivityType.inspection:
        return Icons.fact_check;

      case ActivityType.compliance:
        return Icons.verified_user;

      case ActivityType.system:
        return Icons.computer;
    }
  }

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: FutureBuilder<List<ActivityItem>>(
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
                  title: 'Recent Activity',
                  icon: Icons.history,
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refresh,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Unable to load recent activity.'),
              ],
            );
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return Column(
              children: [
                DashboardCardHeader(
                  title: 'Recent Activity',
                  icon: Icons.history,
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refresh,
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('No recent activity.'),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardCardHeader(
                title: 'Recent Activity',
                subtitle: 'Latest fleet events',
                icon: Icons.history,
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                ),
              ),

              const SizedBox(height: 20),

              DashboardCardBody(
                spacing: 18,
                children: activities.map((activity) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Icon(
                          _icon(activity.type),
                          size: 18,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        _timeAgo(activity.timestamp),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
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