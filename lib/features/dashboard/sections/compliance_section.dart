import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
import '../models/dashboard_summary.dart';
import '../widgets/kpi_card.dart';

class ComplianceSection extends StatelessWidget {
  final DashboardSummary summary;

  const ComplianceSection({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compliance",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          "Monitor fleet compliance and regulatory status.",
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
                    icon: Icons.verified_user,
                    title: "Compliance Due",
                    value: summary.complianceDue.toString(),
                    subtitle: "Upcoming renewals",
                    color: Colors.deepOrange,
                    onTap: () => DashboardNavigation.openRoute(
                      context,
                      '/driver-compliance',
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    icon: Icons.gpp_bad,
                    title: "Expired",
                    value: summary.complianceExpired.toString(),
                    subtitle: "Immediate action required",
                    color: Colors.redAccent,
                    onTap: () => DashboardNavigation.openRoute(
                      context,
                      '/driver-compliance',
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