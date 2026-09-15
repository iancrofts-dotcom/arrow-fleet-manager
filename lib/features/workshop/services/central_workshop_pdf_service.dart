import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../backend/workshop/backend_workshop_evidence.dart';
import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/central_workshop_summary.dart';

class CentralWorkshopPdfService {
  const CentralWorkshopPdfService();

  Future<Uint8List> jobCard({
    required BackendWorkshopRepairJob job,
    required BackendWorkshopInspection inspection,
    List<BackendWorkshopEvidence> evidence = const [],
    Map<String, Uint8List> evidenceBytes = const {},
  }) async {
    final pdf = pw.Document();
    final photoWidgets = <pw.Widget>[];
    for (final item in evidence) {
      final bytes = evidenceBytes[item.id];
      if (bytes == null ||
          !item.contentType.toLowerCase().startsWith('image/')) {
        continue;
      }
      try {
        photoWidgets.add(
          pw.Container(
            width: 235,
            margin: const pw.EdgeInsets.only(right: 8, bottom: 8),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(
                  pw.MemoryImage(bytes),
                  width: 220,
                  height: 150,
                  fit: pw.BoxFit.contain,
                ),
                pw.SizedBox(height: 4),
                pw.Text(item.fileName, style: const pw.TextStyle(fontSize: 8)),
                if (item.caption.trim().isNotEmpty)
                  pw.Text(item.caption, style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        );
      } catch (_) {
        // A malformed image should not block the remainder of the job card.
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'FleetIQ Workshop Job Card',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          pw.Text(
            'FleetIQ Workshop Job Card',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('${job.jobNumber} · ${job.vehicleRegistration}'),
          pw.Text(
            'Generated ${_date(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          _section('Vehicle & source inspection', [
            _row('Registration', job.vehicleRegistration),
            _row('Inspection', inspection.inspectionNumber),
            _row('Inspection type', _label(inspection.inspectionType)),
            _row('Inspection started', _date(inspection.dateStarted)),
            _row(
              'Driver / inspector',
              inspection.driverName?.trim().isNotEmpty == true
                  ? inspection.driverName!
                  : inspection.technicianName,
            ),
            _row('Inspection mileage', inspection.mileage.toString()),
            _row(
              'Technician mileage',
              job.technicianMileage?.toString() ?? 'Not recorded',
            ),
            _row('Inspection result', _label(inspection.overallResult)),
            _row('Inspection notes', inspection.notes),
          ]),
          _section('Defect / repair requirement', [
            _row('Defect', job.title),
            _row('Driver defect notes', job.description),
            _row('Priority', _label(job.priority)),
            _row('Status', _label(job.status)),
            _row('Parts required', job.partsRequired ? 'Yes' : 'No'),
          ]),
          _section('Technician work record', [
            _row(
              'Assigned technician',
              job.technicianName.isEmpty ? 'Unassigned' : job.technicianName,
            ),
            _row('Work carried out', job.workNotes),
            _row('Parts notes', job.partsNotes),
            _row('Estimated hours', job.estimatedHours.toStringAsFixed(1)),
            _row('Actual hours', job.actualHours.toStringAsFixed(1)),
            _row('Estimated cost', '£${job.estimatedCost.toStringAsFixed(2)}'),
            _row('Actual cost', '£${job.actualCost.toStringAsFixed(2)}'),
            _row('Roadworthy', job.roadworthy ? 'Yes' : 'No'),
          ]),
          _section('Management sign-off', [
            _row(
              'Signed off by',
              job.signedOffName.isEmpty
                  ? 'Awaiting sign-off'
                  : job.signedOffName,
            ),
            _row(
              'Signed off at',
              job.signedOffAt == null ? '—' : _date(job.signedOffAt!),
            ),
          ]),
          pw.SizedBox(height: 12),
          pw.Text(
            'Defect photo / evidence',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (photoWidgets.isEmpty)
            pw.Text(
              evidence.isEmpty
                  ? 'No evidence linked to this defect.'
                  : '${evidence.length} evidence file(s) linked; no printable image was available.',
              style: const pw.TextStyle(fontSize: 9),
            )
          else
            pw.Wrap(children: photoWidgets),
          if (evidence.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Evidence audit',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            for (final item in evidence)
              pw.Text(
                '${item.fileName} · ${item.uploaderName.isEmpty ? 'FleetIQ user' : item.uploaderName} · ${_date(item.createdAt)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  Future<Uint8List> workshopReport({
    required List<BackendWorkshopInspection> inspections,
    required List<BackendWorkshopRepairJob> repairs,
  }) async {
    final summary = CentralWorkshopSummary.fromData(
      inspections: inspections,
      repairJobs: repairs,
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('FleetIQ Workshop Report | ${context.pageNumber}'),
        ),
        build: (_) => [
          pw.Text(
            'FleetIQ Workshop Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Generated ${_date(DateTime.now())}'),
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _metric('Inspections', '${summary.totalInspections}'),
              _metric('Open', '${summary.openInspections}'),
              _metric('Completed', '${summary.completedInspections}'),
              _metric('Outstanding repairs', '${summary.outstandingRepairs}'),
              _metric('Waiting parts', '${summary.awaitingParts}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Repair jobs',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Job',
              'Vehicle',
              'Repair',
              'Priority',
              'Status',
              'Technician',
              'Mileage',
              'Hours',
              'Actual cost',
            ],
            data: [
              for (final job in repairs)
                [
                  job.jobNumber,
                  job.vehicleRegistration,
                  job.title,
                  _label(job.priority),
                  _label(job.status),
                  job.technicianName.isEmpty
                      ? 'Unassigned'
                      : job.technicianName,
                  job.technicianMileage?.toString() ?? '—',
                  job.actualHours.toStringAsFixed(1),
                  '£${job.actualCost.toStringAsFixed(2)}',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _section(String title, List<pw.Widget> children) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 12),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
        pw.SizedBox(height: 5),
        ...children,
      ],
    ),
  );

  pw.Widget _row(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value.trim().isEmpty ? '—' : value,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    ),
  );

  pw.Widget _metric(String label, String value) => pw.Container(
    width: 145,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  static String _label(String value) => value
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
