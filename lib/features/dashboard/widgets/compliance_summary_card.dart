import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';

class ComplianceSummaryCard extends StatelessWidget {
  final int motDue;
  final int serviceDue;
  final int overdue;

  const ComplianceSummaryCard({
    super.key,
    required this.motDue,
    required this.serviceDue,
    required this.overdue,
  });

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ],
      ),
      onTap: onTap,
    );
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
              "Upcoming Compliance",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            _buildRow(
              context,
              icon: Icons.assignment_turned_in,
              title: "MOT Due",
              value: motDue,
              onTap: () => DashboardNavigation.openMotDue(context),
            ),

            _buildRow(
              context,
              icon: Icons.build,
              title: "Service Due",
              value: serviceDue,
              onTap: () => DashboardNavigation.openServiceDue(context),
            ),

            _buildRow(
              context,
              icon: Icons.warning,
              title: "Overdue",
              value: overdue,
              onTap: () => DashboardNavigation.openOverdue(context),
            ),
          ],
        ),
      ),
    );
  }
}