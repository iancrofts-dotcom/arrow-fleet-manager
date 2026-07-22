import 'package:flutter/material.dart';

class FleetOperationsCard extends StatelessWidget {
  final int assignedVehicles;
  final int totalVehicles;
  final int assignedDrivers;
  final int totalDrivers;
  final int fleetHealth;

  const FleetOperationsCard({
    super.key,
    required this.assignedVehicles,
    required this.totalVehicles,
    required this.assignedDrivers,
    required this.totalDrivers,
    required this.fleetHealth,
  });

  @override
  Widget build(BuildContext context) {
    final utilisation = totalVehicles == 0
        ? 0
        : ((assignedVehicles / totalVehicles) * 100).round();

    final availability = totalDrivers == 0
        ? 0
        : (((totalDrivers - assignedDrivers) / totalDrivers) * 100).round();

    final compliance = fleetHealth.round();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            _MetricRow(
              label: 'Fleet Utilisation',
              value: '$utilisation%',
              icon: Icons.local_shipping,
              color: Colors.blue,
            ),

            const Divider(),

            _MetricRow(
              label: 'Driver Availability',
              value: '$availability%',
              icon: Icons.person,
              color: Colors.green,
            ),

            const Divider(),

            _MetricRow(
              label: 'Fleet Health',
              value: '$fleetHealth%',
              icon: Icons.favorite,
              color: Colors.orange,
            ),

            const Divider(),

            _MetricRow(
              label: 'Compliance Score',
              value: '$compliance%',
              icon: Icons.verified,
              color: Colors.teal,
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

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}