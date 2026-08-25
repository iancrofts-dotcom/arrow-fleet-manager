import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/fleet_report.dart';
import '../services/report_format_service.dart';

class FleetReportCard extends StatelessWidget {
  final FleetReport report;

  const FleetReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    const formatter = ReportFormatService();

    return SectionCard(
      title: 'Fleet Report',
      subtitle: 'Generated: ${formatter.formatDate(report.generatedAt)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),

          _buildRow('Vehicles', report.vehicles.toString()),
          _buildRow('Active Vehicles', report.activeVehicles.toString()),
          _buildRow('Inactive Vehicles', report.inactiveVehicles.toString()),
          _buildRow('Inspections', report.inspections.toString()),
          _buildRow('Defects', report.defects.toString()),
          _buildRow('MOT Due', report.motDue.toString()),
          _buildRow('Service Due', report.serviceDue.toString()),
          _buildRow('Overdue', report.overdue.toString()),

          const Divider(height: 24),

          _buildRow(
            'Fleet Health',
            formatter.formatFleetHealth(report.fleetHealth),
            valueStyle: TextStyle(
              color: report.fleetHealth >= 90
                  ? Colors.green
                  : report.fleetHealth >= 75
                  ? Colors.orange
                  : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
