import 'package:flutter/material.dart';

import '../models/dashboard_activity.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.activities,
  });

  final List<DashboardActivity> activities;

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
                  leading: const Icon(
                    Icons.assignment_turned_in,
                  ),
                  title: Text(activity.title),
                  subtitle: Text(activity.subtitle),
                  trailing: Text(activity.formattedDate),
                ),
              ),
          ],
        ),
      ),
    );
  }
}