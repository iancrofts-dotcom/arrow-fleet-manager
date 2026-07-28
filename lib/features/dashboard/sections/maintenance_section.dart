import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
import '../models/dashboard_summary.dart';
import '../widgets/kpi_card.dart';

class MaintenanceSection extends StatelessWidget {
  final DashboardSummary summary;

  const MaintenanceSection({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Maintenance",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        Text(
          "Service and maintenance status.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            const spacing = 20.0;

            final cardWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    icon: Icons.build_circle,
                    title: "Service Due",
                    value: summary.maintenanceDue.toString(),
                    subtitle: "Scheduled maintenance",
                    color: Colors.amber,
                    onTap: () => DashboardNavigation.openServiceDue(context),
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    icon: Icons.warning_amber_rounded,
                    title: "Overdue Service",
                    value: summary.maintenanceOverdue.toString(),
                    subtitle: "Immediate attention",
                    color: Colors.red,
                    onTap: () => DashboardNavigation.openRoute(
                      context,
                      '/maintenance',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}