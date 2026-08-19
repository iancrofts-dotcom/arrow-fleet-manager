import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../reports/services/report_branding_service.dart';
import '../models/inspection_item.dart';
import '../models/inspection_photo.dart';
import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';

/// Creates a printable repair job card from the persisted workshop records.
/// The inspection and its photos remain the evidence source; no files are
/// copied into a repair job.
class WorkshopJobCardPdfService {
  const WorkshopJobCardPdfService();

  Future<Uint8List> generate({
    required RepairJob job,
    required WorkshopInspection inspection,
    InspectionItem? sourceItem,
    List<InspectionPhoto> photos = const [],
  }) async {
    final logo = await _loadLogo();
    final photoWidgets = await _photoWidgets(photos);
    final pdf = pw.Document();
    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${const ReportBrandingService().footer} • page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          _header(logo, job, generatedAt),
          _section('Vehicle', [
            _row('Registration', job.vehicleRegistration),
            _row('Fleet number', inspection.fleetNumber),
            _row('Mileage', '${inspection.mileage}'),
          ]),
          _section('Source inspection', [
            _row('Inspection number', inspection.inspectionNumber),
            _row('Type', _titleCase(inspection.inspectionType.name)),
            _row('Inspection date', _dateTime(inspection.dateStarted)),
            _row('Driver / inspector', inspection.driverName?.trim().isNotEmpty == true
                ? inspection.driverName!
                : inspection.technicianName),
            _row('Inspection result', _titleCase(inspection.overallResult.name)),
          ]),
          _section('Defect / repair', [
            _row('Defect', job.title),
            _row('Description', job.description),
            _row('Priority', _titleCase(job.priority.name)),
            _row('Parts required', job.partsRequired ? 'Yes' : 'No'),
            _row('Source checklist item', sourceItem?.title ?? 'Not available'),
            _row('Photo evidence', photos.isEmpty ? 'No inspection photos attached' : '${photos.length} attached'),
          ]),
          _section('Technician', [
            _row('Assigned technician', job.technicianId == null
                ? 'Unassigned'
                : (job.technicianName.trim().isEmpty ? 'Assigned technician' : job.technicianName)),
            _row('Date assigned / created', _dateTime(job.createdAt)),
            _row('Job status', _titleCase(job.status.name)),
          ]),
          _section('Time / cost', [
            _row('Estimated labour hours', _hours(job.estimatedHours)),
            _row('Actual labour hours', _hours(job.actualHours)),
            _row('Estimated cost', _money(job.estimatedCost)),
            _row('Actual cost', _money(job.actualCost)),
          ]),
          _section('Work and review notes', [
            _row('Operational notes', job.description),
            _row('Inspection notes', sourceItem?.notes.trim().isNotEmpty == true
                ? sourceItem!.notes
                : inspection.notes),
          ]),
          _section('Management', [
            _row('Review status', job.status == RepairJobStatus.completed
                ? 'Approved / completed'
                : job.status == RepairJobStatus.awaitingInspection
                    ? 'Awaiting management review'
                    : 'Not yet reviewed'),
            _row('Completion date', job.completedAt == null ? 'Not completed' : _dateTime(job.completedAt!)),
            _row('Inspection sign-off', _titleCase(inspection.status.name)),
          ]),
          if (photoWidgets.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Inspection evidence', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photoWidgets,
            ),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      return pw.MemoryImage((await rootBundle.load('assets/images/arrow_logo.png')).buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _header(pw.ImageProvider? logo, RepairJob job, DateTime generatedAt) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null) pw.Container(width: 58, height: 58, child: pw.Image(logo, fit: pw.BoxFit.contain)),
          if (logo != null) pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Arrow Fleet Manager', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
            pw.Text('Job Card', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)),
            pw.Text('Repair job ${job.jobNumber}'),
          ])),
          pw.Text('Generated\n${_dateTime(generatedAt)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
        ],
      );

  pw.Widget _section(String title, List<pw.Widget> rows) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 14),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          ...rows,
        ]),
      );

  pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 145, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 9))),
        ]),
      );

  Future<List<pw.Widget>> _photoWidgets(List<InspectionPhoto> photos) async {
    final widgets = <pw.Widget>[];
    for (final photo in photos) {
      final file = File(photo.filePath);
      if (!await file.exists()) continue;
      try {
        widgets.add(pw.Container(width: 150, height: 105, child: pw.Image(pw.MemoryImage(await file.readAsBytes()), fit: pw.BoxFit.cover)));
      } catch (_) {
        // A missing or unsupported evidence file is represented by the
        // evidence count above; it must not prevent card generation.
      }
    }
    return widgets;
  }

  static String _titleCase(String value) => value.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])|_'), (match) => match.group(0) == '_' ? ' ' : ' ').split(' ').map((part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
  static String _dateTime(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String _hours(double value) => '${value.toStringAsFixed(1)} hrs';
  static String _money(double value) => '£${value.toStringAsFixed(2)}';
}
