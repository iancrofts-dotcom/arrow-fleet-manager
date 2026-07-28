import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';

class FleetAnalyticsCard extends StatelessWidget {
  final int vehicleCount;
  final int driverCount;
  final int assignedVehicles;
  final int assignedDrivers;
  final int fleetHealth;

  const FleetAnalyticsCard({
    super.key,
    required this.vehicleCount,
    required this.driverCount,
    required this.assignedVehicles,
    required this.assignedDrivers,
    required this.fleetHealth,
  });

  @override
  Widget build(BuildContext context) {
    final utilisation = vehicleCount == 0
        ? 0
        : ((assignedVehicles / vehicleCount) * 100).round();

    final driverCoverage = driverCount == 0
        ? 0
        : ((assignedDrivers / driverCount) * 100).round();

    final risk = fleetHealth >= 90
        ? 'Low'
        : fleetHealth >= 75
            ? 'Medium'
            : 'High';

    final riskColor = fleetHealth >= 90
        ? Colors.green
        : fleetHealth >= 75
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            _AnalyticsRow(
              label: 'Total Fleet Size',
              value: vehicleCount.toString(),
              icon: Icons.local_shipping,
              onTap: () => DashboardNavigation.openFleet(context),
            ),

            const Divider(),

            _AnalyticsRow(
              label: 'Vehicle Utilisation',
              value: '$utilisation%',
              icon: Icons.bar_chart,
              onTap: () => DashboardNavigation.openFleet(context),
            ),

            const Divider(),

            _AnalyticsRow(
              label: 'Driver Coverage',
              value: '$driverCoverage%',
              icon: Icons.people,
              onTap: () => DashboardNavigation.openDrivers(context),
            ),

            const Divider(),

            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => DashboardNavigation.openRoute(
                context,
                '/maintenance',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Maintenance Risk'),
                    ),
                    Chip(
                      label: Text(risk),
                      backgroundColor: riskColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _AnalyticsRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}