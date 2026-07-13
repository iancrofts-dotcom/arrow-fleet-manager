import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/fleet_report.dart';
import 'report_branding_service.dart';
import 'report_format_service.dart';

class PdfReportService {
  const PdfReportService();

  Future<Uint8List> generatePdf(
    FleetReport report,
  ) async {
    const formatter = ReportFormatService();
    const branding = ReportBrandingService();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),

        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${branding.footer} • ${branding.version}',
            style: const pw.TextStyle(
              fontSize: 10,
            ),
          ),
        ),

        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              branding.companyName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.Text(
            branding.reportTitle,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            'Generated: ${formatter.formatDate(report.generatedAt)}',
          ),

          pw.SizedBox(height: 16),

          pw.Divider(),

          _row('Vehicles', report.vehicles),
          _row('Active Vehicles', report.activeVehicles),
          _row('Inactive Vehicles', report.inactiveVehicles),
          _row('Inspections', report.inspections),
          _row('Defects', report.defects),
          _row('MOT Due', report.motDue),
          _row('Service Due', report.serviceDue),
          _row('Overdue', report.overdue),

          pw.Divider(),

          _row(
            'Fleet Health',
            formatter.formatFleetHealth(
              report.fleetHealth,
            ),
          ),
        ],
      ),
    );

    return Uint8List.fromList(
      await pdf.save(),
    );
  }

  pw.Widget _row(
    String title,
    Object value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title),
          pw.Text(value.toString()),
        ],
      ),
    );
  }
}