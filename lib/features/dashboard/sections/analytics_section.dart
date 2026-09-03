import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../widgets/fleet_operations_card.dart';
import '../widgets/recent_activity_card.dart';

class AnalyticsSection extends StatelessWidget {
  final DashboardSummary summary;
  final List<Widget> children;

  const AnalyticsSection({
    super.key,
    required this.summary,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final operations = FleetOperationsCard(
      assignedVehicles: summary.assignedVehicles,
      totalVehicles: summary.vehicleCount,
      assignedDrivers: summary.assignedDrivers,
      totalDrivers: summary.driverCount,
    );
    final activity = RecentActivityCard(
      activities: summary.recentActivity.take(5).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 960;
        final pair = desktop
            ? Row(
                key: const Key('dashboard-operations-activity-pair'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: operations),
                  const SizedBox(width: 24),
                  Expanded(child: activity),
                ],
              )
            : Column(
                key: const Key('dashboard-operations-activity-pair'),
                children: [operations, const SizedBox(height: 24), activity],
              );

        return Column(
          children: [
            pair,
            if (children.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...children,
            ],
          ],
        );
      },
    );
  }
}
