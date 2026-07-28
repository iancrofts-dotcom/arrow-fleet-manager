import 'package:flutter/material.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../models/dashboard_alert.dart';
import '../models/dashboard_summary.dart';
import '../widgets/priority_card.dart';

class PrioritySection extends StatelessWidget {
  const PrioritySection({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  PriorityLevel _priorityLevel(
    DashboardAlertSeverity severity,
  ) {
    switch (severity) {
      case DashboardAlertSeverity.critical:
        return PriorityLevel.critical;

      case DashboardAlertSeverity.warning:
        return PriorityLevel.warning;

      case DashboardAlertSeverity.info:
        return PriorityLevel.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = summary.alerts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Centre',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        Text(
          'Items requiring your immediate attention.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 20),

        if (alerts.isEmpty)
          const PriorityCard(
            icon: Icons.check_circle,
            title: 'Fleet Operating Normally',
            description:
                'There are currently no high priority operational alerts.',
            level: PriorityLevel.success,
          )
        else
          ...alerts.expand(
            (alert) => [
              PriorityCard(
                icon: alert.icon,
                title: alert.title,
                description: alert.message,
                level: _priorityLevel(alert.severity),
               onTap: () => DashboardNavigation.openRoute(
  context,
  alert.route,
),
              ),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }
}