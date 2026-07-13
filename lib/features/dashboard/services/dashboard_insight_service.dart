import 'package:flutter/material.dart';

import '../models/dashboard_insight.dart';
import 'fleet_metrics_service.dart';

class DashboardInsightService {
  const DashboardInsightService();

  List<DashboardInsight> generateInsights(
    FleetMetrics metrics,
  ) {
    final insights = <DashboardInsight>[];

    if (metrics.overdue > 0) {
      insights.add(
        DashboardInsight(
          icon: Icons.warning_amber_rounded,
          title: 'Overdue Items',
          message:
              '${metrics.overdue} vehicle(s) require immediate attention.',
        ),
      );
    }

    if (metrics.motDue > 0) {
      insights.add(
        DashboardInsight(
          icon: Icons.directions_car,
          title: 'MOT Due',
          message:
              '${metrics.motDue} MOT inspection(s) due within 30 days.',
        ),
      );
    }

    if (metrics.serviceDue > 0) {
      insights.add(
        DashboardInsight(
          icon: Icons.build,
          title: 'Service Due',
          message:
              '${metrics.serviceDue} vehicle service(s) due within 30 days.',
        ),
      );
    }

    if (metrics.inactive > 0) {
      insights.add(
        DashboardInsight(
          icon: Icons.pause_circle,
          title: 'Inactive Vehicles',
          message:
              '${metrics.inactive} vehicle(s) are currently inactive.',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const DashboardInsight(
          icon: Icons.check_circle,
          title: 'Fleet Status',
          message: 'No outstanding fleet issues detected.',
        ),
      );
    }

    return insights;
  }
}