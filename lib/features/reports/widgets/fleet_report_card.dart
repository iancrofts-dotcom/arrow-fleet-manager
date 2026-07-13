import 'package:flutter/material.dart';

import '../models/fleet_report.dart';

class FleetReportCard extends StatelessWidget {
  final FleetReport report;

  const FleetReportCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildRow('Generated', report.generatedAt.toString()),
            _buildRow('Vehicles', '${report.vehicles}'),
            _buildRow('Active', '${report.activeVehicles}'),
            _buildRow('Inactive', '${report.inactiveVehicles}'),
            _buildRow('Inspections', '${report.inspections}'),
            _buildRow('Defects', '${report.defects}'),
            _buildRow('MOT Due', '${report.motDue}'),
            _buildRow('Service Due', '${report.serviceDue}'),
            _buildRow('Overdue', '${report.overdue}'),
            const Divider(),
            _buildRow(
              'Fleet Health',
              '${report.fleetHealth}%',
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}