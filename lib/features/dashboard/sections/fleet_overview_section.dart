import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
import '../models/dashboard_summary.dart';
import '../widgets/kpi_card.dart';

class FleetOverviewSection extends StatelessWidget {
  final DashboardSummary summary;

  const FleetOverviewSection({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fleet Snapshot",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        Text(
          "A live overview of your fleet.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            int columns;

            if (constraints.maxWidth >= 1400) {
              columns = 4;
            } else if (constraints.maxWidth >= 900) {
              columns = 2;
            } else {
              columns = 1;
            }

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
                    icon: Icons.local_shipping,
                    title: "Fleet Vehicles",
                    value: summary.vehicleCount.toString(),
                    subtitle: "Registered vehicles",
                    color: Colors.blue,
                    onTap: () => DashboardNavigation.openFleet(context),
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    icon: Icons.badge,
                    title: "Drivers",
                    value: summary.driverCount.toString(),
                    subtitle: "Active drivers",
                    color: Colors.indigo,
                    onTap: () => DashboardNavigation.openDrivers(context),
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    icon: Icons.assignment_turned_in,
                    title: "MOT Due",
                    value: summary.motDue.toString(),
                    subtitle: "Upcoming inspections",
                    color: Colors.orange,
                    onTap: () => DashboardNavigation.openMotDue(context),
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    icon: Icons.warning_amber_rounded,
                    title: "Overdue",
                    value: summary.overdue.toString(),
                    subtitle: "Requires attention",
                    color: Colors.red,
                    onTap: () => DashboardNavigation.openOverdue(context),
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