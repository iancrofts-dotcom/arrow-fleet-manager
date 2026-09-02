import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
import '../models/fleet_health.dart';

class FleetHealthCard extends StatelessWidget {
  const FleetHealthCard({
    super.key,
    required this.fleetHealth,
    required this.maintenanceOverdue,
    required this.complianceExpired,
    required this.healthyVehicles,
  });

  final FleetHealth fleetHealth;
  final int maintenanceOverdue;
  final int complianceExpired;
  final int healthyVehicles;

  @override
  Widget build(BuildContext context) {
    final statusColor = fleetHealth.colour;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Health',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            LinearProgressIndicator(
              value: fleetHealth.score / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fleetHealth.formattedScore,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  avatar: Icon(
                    Icons.health_and_safety,
                    size: 18,
                    color: statusColor,
                  ),
                  label: Text(fleetHealth.label),
                ),
              ],
            ),

            const Divider(height: 32),

            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Healthy Vehicles'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    healthyVehicles.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              onTap: () => DashboardNavigation.openFleet(context),
            ),

            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.build, color: Colors.orange),
              title: const Text('Maintenance Overdue'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    maintenanceOverdue.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user, color: Colors.red),
              title: const Text('Compliance Expired'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    complianceExpired.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
