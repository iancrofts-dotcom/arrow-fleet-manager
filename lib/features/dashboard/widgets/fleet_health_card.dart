import 'package:flutter/material.dart';

class FleetHealthCard extends StatelessWidget {
  const FleetHealthCard({
    super.key,
    required this.healthScore,
    required this.maintenanceOverdue,
    required this.complianceExpired,
    required this.healthyVehicles,
  });

  final int healthScore;
  final int maintenanceOverdue;
  final int complianceExpired;
  final int healthyVehicles;

  String get status {
    if (healthScore >= 90) return 'Excellent';
    if (healthScore >= 75) return 'Good';
    if (healthScore >= 50) return 'Needs Attention';
    return 'Critical';
  }

  Color _statusColor(BuildContext context) {
    if (healthScore >= 90) {
      return Colors.green;
    }
    if (healthScore >= 75) {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Health',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: healthScore / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$healthScore%',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  avatar: Icon(
                    Icons.health_and_safety,
                    size: 18,
                    color: statusColor,
                  ),
                  label: Text(status),
                ),
              ],
            ),
            const Divider(height: 32),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              title: const Text('Healthy Vehicles'),
              trailing: Text(
                healthyVehicles.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.build,
                color: Colors.orange,
              ),
              title: const Text('Maintenance Overdue'),
              trailing: Text(
                maintenanceOverdue.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.verified_user,
                color: Colors.red,
              ),
              title: const Text('Compliance Expired'),
              trailing: Text(
                complianceExpired.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}