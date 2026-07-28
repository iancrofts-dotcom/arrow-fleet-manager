import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../widgets/fleet_health_card.dart';
import '../widgets/fleet_operations_card.dart';
import '../widgets/fleet_analytics_card.dart';
import '../widgets/dashboard_insights_card.dart';
import '../widgets/compliance_summary_card.dart';
import '../widgets/dashboard_alerts_card.dart';
import '../widgets/recent_activity_card.dart';

class AnalyticsSection extends StatelessWidget {
  final DashboardSummary summary;

  const AnalyticsSection({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FleetHealthCard(
          healthScore: summary.fleetHealth,
          maintenanceOverdue: summary.maintenanceOverdue,
          complianceExpired: summary.complianceExpired,
          healthyVehicles:
              summary.vehicleCount - summary.maintenanceOverdue,
        ),

        const SizedBox(height: 30),

        FleetOperationsCard(
          assignedVehicles: summary.assignedVehicles,
          totalVehicles: summary.vehicleCount,
          assignedDrivers: summary.assignedDrivers,
          totalDrivers: summary.driverCount,
          fleetHealth: summary.fleetHealth,
        ),

        const SizedBox(height: 30),

        FleetAnalyticsCard(
          vehicleCount: summary.vehicleCount,
          driverCount: summary.driverCount,
          assignedVehicles: summary.assignedVehicles,
          assignedDrivers: summary.assignedDrivers,
          fleetHealth: summary.fleetHealth,
        ),

        const SizedBox(height: 30),

        DashboardInsightsCard(
          insights: summary.insights,
        ),

        const SizedBox(height: 30),

        ComplianceSummaryCard(
          motDue: summary.motDue,
          serviceDue: summary.serviceDue,
          overdue: summary.overdue,
        ),

        const SizedBox(height: 30),

        DashboardAlertsCard(
          alerts: summary.alerts,
        ),

        const SizedBox(height: 30),

        RecentActivityCard(
          activities: summary.recentActivity,
        ),
      ],
    );
  }
}