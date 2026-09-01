import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
import '../models/dashboard_activity.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key, required this.activities});

  final List<DashboardActivity> activities;

  IconData _iconForType(DashboardActivityType type) {
    switch (type) {
      case DashboardActivityType.assignment:
        return Icons.person_add;
      case DashboardActivityType.maintenance:
        return Icons.build;
      case DashboardActivityType.compliance:
        return Icons.verified_user;
      case DashboardActivityType.vehicle:
        return Icons.local_shipping;
      case DashboardActivityType.driver:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            if (activities.isEmpty)
              const ListTile(
                leading: Icon(Icons.history),
                title: Text('No recent activity'),
              )
            else
              ...activities.map(
                (activity) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForType(activity.type),
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(activity.title),
                  subtitle: Text(activity.subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(activity.relativeDate),
                      if (DashboardNavigation.canOpenRoute(activity.route)) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ],
                  ),
                  onTap: DashboardNavigation.canOpenRoute(activity.route)
                      ? () => DashboardNavigation.openRoute(
                          context,
                          activity.route,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
