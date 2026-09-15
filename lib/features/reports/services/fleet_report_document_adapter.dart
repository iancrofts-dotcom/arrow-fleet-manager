import '../models/fleet_report.dart';
import '../models/report_document.dart';
import 'report_format_service.dart';

class FleetReportDocumentAdapter {
  const FleetReportDocumentAdapter();

  ReportDocument build(FleetReport report) {
    const formatter = ReportFormatService();

    return ReportDocument(
      id: 'fleet-summary',
      title: 'Fleet Summary',
      subtitle: 'Current fleet compliance and operational snapshot.',
      generatedAt: report.generatedAt,
      sections: [
        ReportSection(
          title: 'Fleet',
          rows: [
            ReportRow(label: 'Vehicles', value: '${report.vehicles}'),
            ReportRow(
              label: 'Active Vehicles',
              value: '${report.activeVehicles}',
            ),
            ReportRow(
              label: 'Inactive Vehicles',
              value: '${report.inactiveVehicles}',
            ),
            ReportRow(
              label: 'Fleet Health',
              value: formatter.formatFleetHealth(report.fleetHealth),
            ),
          ],
        ),
        ReportSection(
          title: 'Compliance & Maintenance',
          rows: [
            ReportRow(label: 'MOT Due', value: '${report.motDue}'),
            ReportRow(label: 'Service Due', value: '${report.serviceDue}'),
            ReportRow(label: 'Overdue', value: '${report.overdue}'),
          ],
        ),
        ReportSection(
          title: 'Operations',
          rows: [
            ReportRow(label: 'Inspections', value: '${report.inspections}'),
            ReportRow(label: 'Defects', value: '${report.defects}'),
          ],
        ),
      ],
    );
  }
}
