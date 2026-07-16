import 'package:flutter/material.dart';

import '../models/dashboard_activity.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.activities,
  });

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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  leading: Icon(
                    _iconForType(activity.type),
                  ),
                  title: Text(activity.title),
                  subtitle: Text(activity.subtitle),
                  trailing: Text(
                    activity.relativeDate,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}