import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';

class WorkshopReportsPdfService {
  const WorkshopReportsPdfService();

  Future<Uint8List> generate({
    required String title,
    required List<RepairJob> jobs,
    required List<WorkshopInspection> inspections,
    required String filterSummary,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Arrow Fleet Manager • page ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        build: (context) => [
          pw.Text('Arrow Fleet Manager',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text(title,
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Generated ${_date(DateTime.now())} • $filterSummary',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 14),
          _summary(jobs, inspections),
          pw.SizedBox(height: 14),
          pw.Text('Repair jobs', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _jobsTable(jobs),
          if (inspections.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Inspections', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _inspectionsTable(inspections),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _summary(List<RepairJob> jobs, List<WorkshopInspection> inspections) {
    final completed = jobs.where((job) => job.status == RepairJobStatus.completed).length;
    final awaitingReview = jobs.where((job) => job.status == RepairJobStatus.awaitingInspection).length;
    final estimatedHours = jobs.fold<double>(0, (total, job) => total + job.estimatedHours);
    final actualHours = jobs.fold<double>(0, (total, job) => total + job.actualHours);
    final estimatedCost = jobs.fold<double>(0, (total, job) => total + job.estimatedCost);
    final actualCost = jobs.fold<double>(0, (total, job) => total + job.actualCost);
    return pw.Wrap(spacing: 14, runSpacing: 8, children: [
      _metric('Repair jobs', jobs.length.toString()),
      _metric('Completed', completed.toString()),
      _metric('Awaiting review', awaitingReview.toString()),
      _metric('Inspections', inspections.length.toString()),
      _metric('Estimated hours', estimatedHours.toStringAsFixed(1)),
      _metric('Actual labour hours', actualHours.toStringAsFixed(1)),
      _metric('Estimated cost', _money(estimatedCost)),
      _metric('Actual cost', _money(actualCost)),
    ]);
  }

  pw.Widget _metric(String label, String value) => pw.Container(
        width: 100,
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ]),
      );

  pw.Widget _jobsTable(List<RepairJob> jobs) => pw.TableHelper.fromTextArray(
        headers: const ['Job', 'Vehicle', 'Inspection', 'Defect', 'Priority', 'Technician', 'Status', 'Est/Actual hrs', 'Est/Actual cost', 'Dates'],
        data: jobs.map((job) => [
          job.jobNumber,
          job.vehicleRegistration,
          '${job.inspectionId}',
          job.title,
          _title(job.priority.name),
          job.technicianId == null ? 'Unassigned' : job.technicianName,
          _title(job.status.name),
          '${job.estimatedHours.toStringAsFixed(1)} / ${job.actualHours.toStringAsFixed(1)}',
          '${_money(job.estimatedCost)} / ${_money(job.actualCost)}',
          '${_date(job.createdAt)}${job.completedAt == null ? '' : '\nCompleted ${_date(job.completedAt!)}'}',
        ]).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 7),
        cellAlignment: pw.Alignment.centerLeft,
      );

  pw.Widget _inspectionsTable(List<WorkshopInspection> inspections) => pw.TableHelper.fromTextArray(
        headers: const ['Inspection', 'Vehicle', 'Type', 'Driver / inspector', 'Result', 'Defects', 'Repairs', 'Date', 'Sign-off'],
        data: inspections.map((inspection) => [
          inspection.inspectionNumber,
          '${inspection.registration} / ${inspection.fleetNumber}',
          _title(inspection.inspectionType.name),
          inspection.driverName?.isNotEmpty == true ? inspection.driverName! : inspection.technicianName,
          _title(inspection.overallResult.name),
          '${inspection.criticalFailures + inspection.advisories}',
          '${inspection.repairsRequired}',
          _date(inspection.dateStarted),
          _title(inspection.status.name),
        ]).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 7),
      );

  static String _title(String value) => value.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])|_'), (match) => ' ').split(' ').map((part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
  static String _money(double value) => '£${value.toStringAsFixed(2)}';
  static String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
