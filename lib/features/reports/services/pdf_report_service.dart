import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/fleet_report.dart';
import 'dart:typed_data';

class PdfReportService {
  const PdfReportService();

 Future<Uint8List> generatePdf(
    FleetReport report,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Arrow Fleet Manager',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            'Fleet Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.Text(
            'Generated: ${report.generatedAt}',
          ),

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
            '${report.fleetHealth}%',
          ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
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