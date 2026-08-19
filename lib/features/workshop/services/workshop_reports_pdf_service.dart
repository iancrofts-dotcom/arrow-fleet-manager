import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/repair_job.dart';
import '../models/inspection_photo.dart';
import '../models/workshop_inspection.dart';
import 'workshop_reporting_service.dart';

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
          child: pw.Text('Arrow Fleet Manager | page ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        build: (context) => [
          pw.Text('Arrow Fleet Manager',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text(title,
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Generated ${_date(DateTime.now())} | $filterSummary',
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

  Future<Uint8List> generateRepairJobs({
    required List<RepairJob> jobs,
    required List<WorkshopInspection> inspections,
    required String filterSummary,
  }) async {
    final logo = await _loadLogo();
    final inspectionById = {
      for (final inspection in inspections)
        if (inspection.id != null) inspection.id!: inspection,
    };
    final completed =
        jobs.where((job) => job.status == RepairJobStatus.completed).length;
    final outstanding = jobs
        .where((job) =>
            job.status != RepairJobStatus.completed &&
            job.status != RepairJobStatus.cancelled)
        .length;
    final estimatedHours =
        jobs.fold<double>(0, (total, job) => total + job.estimatedHours);
    final actualHours =
        jobs.fold<double>(0, (total, job) => total + job.actualHours);
    final estimatedCost =
        jobs.fold<double>(0, (total, job) => total + job.estimatedCost);
    final actualCost =
        jobs.fold<double>(0, (total, job) => total + job.actualCost);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Row(children: [
          if (logo != null)
            pw.Container(width: 42, height: 42, child: pw.Image(logo)),
          if (logo != null) pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Arrow Fleet Manager', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Workshop Repair Job Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ])),
          pw.Text('Generated ${_dateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
        ]),
        footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Arrow Fleet Manager | page ${context.pageNumber}', style: const pw.TextStyle(fontSize: 9))),
        build: (_) => [
          pw.Text(filterSummary, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          pw.Wrap(spacing: 10, runSpacing: 8, children: [
            _metric('Total jobs', '${jobs.length}'), _metric('Completed jobs', '$completed'), _metric('Outstanding jobs', '$outstanding'), _metric('Estimated labour hours', estimatedHours.toStringAsFixed(1)), _metric('Actual labour hours', actualHours.toStringAsFixed(1)), _metric('Estimated cost', _money(estimatedCost)), _metric('Actual cost', _money(actualCost)),
          ]),
          pw.SizedBox(height: 16),
          ...jobs.map((job) {
            final inspection = inspectionById[job.inspectionId];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('${job.jobNumber} | ${job.vehicleRegistration}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                  pw.Text('${_title(job.priority.name)} | ${_title(job.status.name)}', style: const pw.TextStyle(fontSize: 9)),
                ]),
                pw.SizedBox(height: 4),
                pw.Text(job.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                if (job.description.trim().isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 2), child: pw.Text(job.description, style: const pw.TextStyle(fontSize: 9))),
                pw.SizedBox(height: 5),
                pw.Wrap(spacing: 14, runSpacing: 3, children: [
                  pw.Text('Fleet: ${inspection?.fleetNumber ?? 'Not recorded'}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Inspection: ${inspection?.inspectionNumber ?? job.inspectionId}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Technician: ${job.technicianId == null ? 'Unassigned' : job.technicianName}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Parts required: ${job.partsRequired ? 'Yes' : 'No'}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Hours: ${job.estimatedHours.toStringAsFixed(1)} est / ${job.actualHours.toStringAsFixed(1)} actual', style: const pw.TextStyle(fontSize: 8)), pw.Text('Cost: ${_money(job.estimatedCost)} est / ${_money(job.actualCost)} actual', style: const pw.TextStyle(fontSize: 8)), pw.Text('Created: ${_dateTime(job.createdAt)}', style: const pw.TextStyle(fontSize: 8)), if (job.startedAt != null) pw.Text('Started: ${_dateTime(job.startedAt!)}', style: const pw.TextStyle(fontSize: 8)), if (job.completedAt != null) pw.Text('Completed: ${_dateTime(job.completedAt!)}', style: const pw.TextStyle(fontSize: 8)),
                ]),
              ]),
            );
          }),
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  Future<Uint8List> generateVehicleHistory({
    required VehicleWorkshopHistory history,
    required String filterSummary,
  }) async {
    final logo = await _loadLogo();
    final vehicle = history.inspections.isEmpty ? null : history.inspections.first;
    final jobsByInspection = <int, List<RepairJob>>{};
    for (final job in history.jobs) {
      jobsByInspection.putIfAbsent(job.inspectionId, () => []).add(job);
    }
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      header: (_) => pw.Row(children: [
        if (logo != null) pw.Container(width: 42, height: 42, child: pw.Image(logo)),
        if (logo != null) pw.SizedBox(width: 10),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Arrow Fleet Manager', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('Vehicle Workshop History', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))])),
        pw.Text('Generated ${_dateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
      ]),
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Arrow Fleet Manager | page ${context.pageNumber}', style: const pw.TextStyle(fontSize: 9))),
      build: (_) => [
        pw.Text('${vehicle?.registration ?? 'Vehicle not recorded'} | Fleet ${vehicle?.fleetNumber ?? 'Not recorded'}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text(filterSummary, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 12),
        pw.Wrap(spacing: 10, runSpacing: 8, children: [_metric('Inspections', '${history.inspections.length}'), _metric('Failed / repair items', '${history.failedOrRepairRequiredItems}'), _metric('Repair jobs', '${history.jobs.length}'), _metric('Completed repairs', '${history.completedJobs}'), _metric('Outstanding repairs', '${history.outstandingJobs}'), _metric('Actual labour hours', history.actualHours.toStringAsFixed(1)), _metric('Actual repair cost', _money(history.actualCost))]),
        pw.SizedBox(height: 16),
        pw.Text('Workshop history', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ...history.inspections.map((inspection) {
          final jobs = inspection.id == null ? const <RepairJob>[] : jobsByInspection[inspection.id] ?? const <RepairJob>[];
          return pw.Container(margin: const pw.EdgeInsets.only(top: 9), padding: const pw.EdgeInsets.all(9), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${_dateTime(inspection.dateStarted)} | ${inspection.inspectionNumber}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('${_title(inspection.inspectionType.name)} | ${_title(inspection.status.name)} | Sign-off: ${inspection.managerSignature?.trim().isNotEmpty == true ? 'Recorded' : 'Not recorded'}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Saved failed / repair-required items: ${inspection.criticalFailures + inspection.repairsRequired}', style: const pw.TextStyle(fontSize: 9)),
            if (jobs.isEmpty) pw.Text('No linked repair jobs.', style: const pw.TextStyle(fontSize: 9)) else ...jobs.map((job) => pw.Padding(padding: const pw.EdgeInsets.only(top: 5), child: pw.Text('${job.jobNumber} | ${job.title} | ${job.technicianId == null ? 'Unassigned' : job.technicianName} | ${_title(job.status.name)} | ${job.actualHours.toStringAsFixed(1)} hrs | ${_money(job.actualCost)}${job.completedAt == null ? '' : ' | Completed ${_dateTime(job.completedAt!)}'}', style: const pw.TextStyle(fontSize: 8)))),
          ]));
        }),
      ],
    ));
    return Uint8List.fromList(await pdf.save());
  }

  Future<Uint8List> generateTechnicianWork({
    required TechnicianWorkSummary? summary,
    required String technicianName,
    required String filterSummary,
  }) async {
    final data = summary;
    final logo = await _loadLogo();
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(30), header: (_) => pw.Row(children: [if (logo != null) pw.Container(width: 42, height: 42, child: pw.Image(logo)), if (logo != null) pw.SizedBox(width: 10), pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Arrow Fleet Manager', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('Technician Work Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))])), pw.Text('Generated ${_dateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 9))]), footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Arrow Fleet Manager | page ${context.pageNumber}', style: const pw.TextStyle(fontSize: 9))), build: (_) => [
      pw.Text('$technicianName | $filterSummary', style: const pw.TextStyle(fontSize: 9)), pw.SizedBox(height: 12),
      pw.Wrap(spacing: 10, runSpacing: 8, children: [_metric('Assigned jobs', '${data?.jobs.length ?? 0}'), _metric('Active jobs', '${data?.activeJobs ?? 0}'), _metric('Awaiting review', '${data?.awaitingReview ?? 0}'), _metric('Completed jobs', '${data?.completedJobs ?? 0}'), _metric('Vehicles worked on', '${data?.vehicleCount ?? 0}'), _metric('Actual labour hours', (data?.actualHours ?? 0).toStringAsFixed(1)), _metric('Actual cost recorded', _money(data?.actualCost ?? 0))]), pw.SizedBox(height: 16), pw.Text('Work history', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ...(data?.jobs ?? const <RepairJob>[]).map((job) => pw.Container(margin: const pw.EdgeInsets.only(top: 9), padding: const pw.EdgeInsets.all(9), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('${job.jobNumber} | ${job.vehicleRegistration} | ${_title(job.status.name)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)), pw.Text(job.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), if (job.description.trim().isNotEmpty) pw.Text(job.description, style: const pw.TextStyle(fontSize: 9)), pw.Wrap(spacing: 12, children: [pw.Text('Inspection: ${job.inspectionId}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Priority: ${_title(job.priority.name)}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Actual hours: ${job.actualHours.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Actual cost: ${_money(job.actualCost)}', style: const pw.TextStyle(fontSize: 8)), pw.Text('Created: ${_dateTime(job.createdAt)}', style: const pw.TextStyle(fontSize: 8)), if (job.startedAt != null) pw.Text('Started: ${_dateTime(job.startedAt!)}', style: const pw.TextStyle(fontSize: 8)), if (job.completedAt != null) pw.Text('Completed: ${_dateTime(job.completedAt!)}', style: const pw.TextStyle(fontSize: 8))])])) )
    ]));
    return Uint8List.fromList(await pdf.save());
  }

  Future<Uint8List> generateCosts({
    required WorkshopCostSummary summary,
    required String filterSummary,
  }) async {
    final logo = await _loadLogo();
    final vehicleCounts = <String, int>{};
    final priorityCounts = <String, int>{};
    for (final job in summary.jobs) {
      vehicleCounts.update(job.vehicleRegistration, (count) => count + 1, ifAbsent: () => 1);
      priorityCounts.update(job.priority.name, (count) => count + 1, ifAbsent: () => 1);
    }
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(30), header: (_) => pw.Row(children: [if (logo != null) pw.Container(width: 42, height: 42, child: pw.Image(logo)), if (logo != null) pw.SizedBox(width: 10), pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Arrow Fleet Manager', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('Workshop Cost Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))])), pw.Text('Generated ${_dateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 9))]), footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Arrow Fleet Manager | page ${context.pageNumber}', style: const pw.TextStyle(fontSize: 9))), build: (_) => [
      pw.Text(filterSummary, style: const pw.TextStyle(fontSize: 9)), pw.SizedBox(height: 12),
      pw.Wrap(spacing: 10, runSpacing: 8, children: [_metric('Total repair jobs', '${summary.jobs.length}'), _metric('Completed jobs', '${summary.completedJobs}'), _metric('Outstanding jobs', '${summary.outstandingJobs}'), _metric('Estimated cost', _money(summary.estimatedCost)), _metric('Actual cost', _money(summary.actualCost)), _metric('Cost variance', _money(summary.costVariance)), _metric('Estimated labour hours', summary.estimatedHours.toStringAsFixed(1)), _metric('Actual labour hours', summary.actualHours.toStringAsFixed(1))]),
      pw.SizedBox(height: 16), pw.Text('Cost by vehicle', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(headers: const ['Vehicle', 'Jobs', 'Actual cost'], data: summary.actualCostByVehicle.entries.map((entry) => [entry.key, '${vehicleCounts[entry.key] ?? 0}', _money(entry.value)]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), cellStyle: const pw.TextStyle(fontSize: 8)),
      pw.SizedBox(height: 16), pw.Text('Cost by priority', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(headers: const ['Priority', 'Jobs', 'Actual cost'], data: summary.actualCostByPriority.entries.map((entry) => [_title(entry.key), '${priorityCounts[entry.key] ?? 0}', _money(entry.value)]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), cellStyle: const pw.TextStyle(fontSize: 8)),
      pw.SizedBox(height: 16), pw.Text('Supporting jobs', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)), _jobsTable(summary.jobs),
    ]));
    return Uint8List.fromList(await pdf.save());
  }

  /// Builds an A4 record from persisted inspection snapshots, linked jobs and
  /// item-linked evidence. It deliberately never consults the live template.
  Future<Uint8List> generateInspectionReport(InspectionReportData report) async {
    final logo = await _loadLogo();
    final evidence = await _evidenceWidgets(report.photos);
    final inspection = report.inspection;
    final itemsById = {for (final item in report.items) if (item.id != null) item.id!: item};
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Arrow Fleet Manager | page ${context.pageNumber}', style: const pw.TextStyle(fontSize: 9))),
      build: (_) => [
        pw.Row(children: [
          if (logo != null) pw.Container(width: 54, height: 54, child: pw.Image(logo)),
          if (logo != null) pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Arrow Fleet Manager', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)), pw.Text('Inspection Report', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)), pw.Text(inspection.inspectionNumber)])),
        ]),
        _detailSection('Inspection summary', [
          _detailRow('Inspection number', inspection.inspectionNumber),
          _detailRow('Date', _dateTime(inspection.dateStarted)),
          _detailRow('Template / type', inspection.templateName?.trim().isNotEmpty == true ? inspection.templateName! : _title(inspection.inspectionType.name)),
          _detailRow('Result / status', '${_title(inspection.overallResult.name)} / ${_title(inspection.status.name)}'),
          _detailRow('Roadworthy', _title(inspection.vehicleStatus.name)),
          _detailRow('Mileage', '${inspection.mileage}'),
        ]),
        _detailSection('Vehicle and people', [
          _detailRow('Vehicle', '${inspection.registration} | ${inspection.fleetNumber}'),
          _detailRow('Driver', inspection.driverName?.trim().isNotEmpty == true ? inspection.driverName! : 'Not recorded'),
          _detailRow('Inspector / technician', inspection.technicianName.trim().isEmpty ? 'Not recorded' : inspection.technicianName),
        ]),
        pw.SizedBox(height: 14),
        pw.Text('Checklist results', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(headers: const ['Section', 'Item', 'Response', 'Status', 'Repair', 'Notes'], data: report.items.map((item) => [item.sectionTitle ?? '', item.title, item.responseValue ?? '', _title(item.status.name), item.repairRequired ? 'Required' : 'No', item.notes]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), cellStyle: const pw.TextStyle(fontSize: 7)),
        pw.SizedBox(height: 14),
        pw.Text('Repair work', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (report.jobs.isEmpty) pw.Text('No repair jobs recorded.') else pw.TableHelper.fromTextArray(headers: const ['Job', 'Source item', 'Technician', 'Status', 'Parts', 'Actual hours', 'Actual cost', 'Completed'], data: report.jobs.map((job) => [job.jobNumber, itemsById[job.inspectionItemId]?.title ?? 'Not available', job.technicianId == null ? 'Unassigned' : job.technicianName, _title(job.status.name), job.partsRequired ? 'Yes' : 'No', job.actualHours.toStringAsFixed(1), _money(job.actualCost), job.completedAt == null ? '' : _dateTime(job.completedAt!)]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), cellStyle: const pw.TextStyle(fontSize: 7)),
        pw.SizedBox(height: 14),
        pw.Text('Photo evidence', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        if (report.photos.isEmpty) pw.Text('No inspection photos attached.') else if (evidence.isEmpty) pw.Text('Inspection evidence is recorded, but the local photo file is unavailable.') else pw.Wrap(spacing: 8, runSpacing: 8, children: evidence),
        _detailSection('Final status / sign-off', [_detailRow('Inspection status', _title(inspection.status.name)), _detailRow('Manager signature', inspection.managerSignature?.trim().isNotEmpty == true ? inspection.managerSignature! : 'Not signed off'), _detailRow('Notes', inspection.notes)]),
      ],
    ));
    return Uint8List.fromList(await pdf.save());
  }

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      return pw.MemoryImage((await rootBundle.load('assets/images/arrow_logo.png')).buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<List<pw.Widget>> _evidenceWidgets(List<InspectionPhoto> photos) async {
    final widgets = <pw.Widget>[];
    for (final photo in photos) {
      final file = File(photo.filePath);
      if (!await file.exists()) continue;
      try {
        widgets.add(pw.Container(width: 150, height: 105, child: pw.Image(pw.MemoryImage(await file.readAsBytes()), fit: pw.BoxFit.cover)));
      } catch (_) {
        // Persisted evidence that cannot be read remains represented safely.
      }
    }
    return widgets;
  }

  pw.Widget _detailSection(String title, List<pw.Widget> children) => pw.Container(margin: const pw.EdgeInsets.only(top: 14), padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 5), ...children]));
  pw.Widget _detailRow(String label, String value) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))), pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 9)))]));

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
  static String _dateTime(DateTime value) => '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
