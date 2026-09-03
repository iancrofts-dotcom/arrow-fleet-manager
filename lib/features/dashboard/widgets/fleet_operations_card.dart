import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
import '../../auth/services/permission_service.dart';

class FleetOperationsCard extends StatelessWidget {
  final int assignedVehicles;
  final int totalVehicles;
  final int assignedDrivers;
  final int totalDrivers;

  const FleetOperationsCard({
    super.key,
    required this.assignedVehicles,
    required this.totalVehicles,
    required this.assignedDrivers,
    required this.totalDrivers,
  });

  @override
  Widget build(BuildContext context) {
    final utilisation = totalVehicles == 0
        ? 0
        : ((assignedVehicles / totalVehicles) * 100).round();

    final availability = totalDrivers == 0
        ? 0
        : (((totalDrivers - assignedDrivers) / totalDrivers) * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Operations',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            _MetricRow(
              label: 'Fleet Utilisation',
              value: '$utilisation%',
              icon: Icons.local_shipping,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => DashboardNavigation.openFleet(context),
            ),

            const Divider(),

            _MetricRow(
              label: 'Driver Availability',
              value: '$availability%',
              icon: Icons.person,
              color: Theme.of(context).colorScheme.tertiary,
              onTap: PermissionService.instance.canViewDrivers
                  ? () => DashboardNavigation.openDrivers(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
