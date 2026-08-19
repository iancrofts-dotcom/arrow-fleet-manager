import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../../reports/services/pdf_export_service.dart';
import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';
import '../repositories/workshop_repository.dart';
import '../services/workshop_reports_pdf_service.dart';

enum _WorkshopReportType { repairJobs, vehicleHistory, technicianWork, costs, inspections }

class WorkshopReportsScreen extends StatefulWidget {
  const WorkshopReportsScreen({super.key});

  @override
  State<WorkshopReportsScreen> createState() => _WorkshopReportsScreenState();
}

class _WorkshopReportsScreenState extends State<WorkshopReportsScreen> {
  final WorkshopRepository _repository = WorkshopRepository();
  final WorkshopReportsPdfService _pdfService = const WorkshopReportsPdfService();
  final PdfExportService _pdfExportService = const PdfExportService();
  late Future<_WorkshopReportData> _future;
  _WorkshopReportType _type = _WorkshopReportType.repairJobs;
  String _vehicle = 'All vehicles';
  String _technician = 'All technicians';
  String _status = 'All statuses';
  String _priority = 'All priorities';
  String _period = 'Last 30 days';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WorkshopReportData> _load() async => _WorkshopReportData(
        jobs: await _repository.getAllRepairJobs(),
        inspections: await _repository.getAllInspections(),
      );

  List<RepairJob> _filteredJobs(_WorkshopReportData data) {
    final now = DateTime.now();
    final from = switch (_period) {
      'Today' => DateTime(now.year, now.month, now.day),
      'Last 7 days' => now.subtract(const Duration(days: 7)),
      'Last 30 days' => now.subtract(const Duration(days: 30)),
      _ => null,
    };
    return data.jobs.where((job) =>
        (from == null || !job.createdAt.isBefore(from)) &&
        (_vehicle == 'All vehicles' || job.vehicleRegistration == _vehicle) &&
        (_technician == 'All technicians' || job.technicianName == _technician) &&
        (_status == 'All statuses' || job.status.name == _status) &&
        (_priority == 'All priorities' || job.priority.name == _priority)).toList();
  }

  List<WorkshopInspection> _filteredInspections(_WorkshopReportData data, List<RepairJob> jobs) {
    if (_type == _WorkshopReportType.inspections && _vehicle == 'All vehicles') return data.inspections;
    final inspectionIds = jobs.map((job) => job.inspectionId).toSet();
    return data.inspections.where((inspection) => inspectionIds.contains(inspection.id)).toList();
  }

  String get _title => switch (_type) {
        _WorkshopReportType.repairJobs => 'Repair Job Report',
        _WorkshopReportType.vehicleHistory => 'Vehicle Workshop History',
        _WorkshopReportType.technicianWork => 'Technician Work Report',
        _WorkshopReportType.costs => 'Workshop Cost Report',
        _WorkshopReportType.inspections => 'Inspection Report',
      };

  Future<Uint8List> _createPdf(_WorkshopReportData data) {
    final jobs = _filteredJobs(data);
    return _pdfService.generate(
      title: _title,
      jobs: jobs,
      inspections: _filteredInspections(data, jobs),
      filterSummary: '$_period • $_vehicle • $_technician • $_status • $_priority',
    );
  }

  Future<void> _preview(_WorkshopReportData data) async {
    final bytes = await _createPdf(data);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfPreview(build: (_) async => bytes)));
  }

  Future<void> _printOrSave(_WorkshopReportData data) async {
    final bytes = await _createPdf(data);
    if (!mounted) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
    final file = await _pdfExportService.savePdf(bytes, 'workshop_report_${DateTime.now().millisecondsSinceEpoch}');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
  }

  Future<void> _exportCsv(_WorkshopReportData data) async {
    final rows = <String>[
      'Job number,Vehicle,Inspection,Defect,Priority,Technician,Status,Estimated hours,Actual labour hours,Estimated cost,Actual cost',
      ..._filteredJobs(data).map((job) => [job.jobNumber, job.vehicleRegistration, job.inspectionId, job.title, job.priority.name, job.technicianName, job.status.name, job.estimatedHours, job.actualHours, job.estimatedCost, job.actualCost].map((value) => '"${value.toString().replaceAll('"', '""')}"').join(',')),
    ];
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/workshop_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(rows.join('\n'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved to ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageWorkshop) return const _WorkshopReportsAccessDenied();
    return AppPageScaffold(
      title: 'Workshop Reports',
      subtitle: 'Operational repair, inspection, technician and cost reporting.',
      child: FutureBuilder<_WorkshopReportData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoadingState(label: 'Loading Workshop reports...');
          if (snapshot.hasError) return AppErrorState(message: 'Unable to load Workshop reporting data.', onRetry: () => setState(() => _future = _load()));
          final data = snapshot.data!;
          final jobs = _filteredJobs(data);
          final registrations = data.jobs.map((job) => job.vehicleRegistration).where((value) => value.isNotEmpty).toSet().toList()..sort();
          final technicians = data.jobs.map((job) => job.technicianName).where((value) => value.trim().isNotEmpty).toSet().toList()..sort();
          return ListView(padding: EdgeInsets.zero, children: [
            _section('Report filters', Wrap(spacing: 12, runSpacing: 12, children: [
              _dropdown('Report', _type, _WorkshopReportType.values, (value) => setState(() => _type = value!), _reportTypeLabel),
              _stringDropdown('Period', _period, const ['Today', 'Last 7 days', 'Last 30 days', 'All time'], (value) => setState(() => _period = value!)),
              _stringDropdown('Vehicle', _vehicle, ['All vehicles', ...registrations], (value) => setState(() => _vehicle = value!)),
              _stringDropdown('Technician', _technician, ['All technicians', ...technicians], (value) => setState(() => _technician = value!)),
              _stringDropdown('Status', _status, ['All statuses', ...RepairJobStatus.values.map((value) => value.name)], (value) => setState(() => _status = value!)),
              _stringDropdown('Priority', _priority, ['All priorities', ...RepairPriority.values.map((value) => value.name)], (value) => setState(() => _priority = value!)),
            ])),
            const SizedBox(height: 24),
            _section(_title, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${jobs.length} repair job${jobs.length == 1 ? '' : 's'} match the current filters.'),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                OutlinedButton.icon(onPressed: () => _preview(data), icon: const Icon(Icons.preview_outlined), label: const Text('Preview PDF')),
                FilledButton.tonalIcon(onPressed: () => _printOrSave(data), icon: const Icon(Icons.print_outlined), label: const Text('Print / Save PDF')),
                OutlinedButton.icon(onPressed: () => _exportCsv(data), icon: const Icon(Icons.table_view_outlined), label: const Text('Export CSV')),
              ]),
            ])),
            const SizedBox(height: 24),
            if (jobs.isEmpty)
              const AppEmptyState(title: 'No matching Workshop records', message: 'Adjust the filters to include other repair jobs.')
            else
              _section('Report preview', Column(children: jobs.take(20).map((job) => ListTile(contentPadding: EdgeInsets.zero, title: Text('${job.jobNumber} • ${job.title}'), subtitle: Text('${job.vehicleRegistration} • ${job.technicianName.isEmpty ? 'Unassigned' : job.technicianName} • ${job.status.name}'), trailing: Text('£${job.actualCost.toStringAsFixed(2)}'))).toList())),
          ]);
        },
      ),
    );
  }

  Widget _section(String title, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 10), SectionCard(child: child)]);
  Widget _dropdown<T>(String label, T value, List<T> values, ValueChanged<T?> onChanged, String Function(T) display) => SizedBox(width: 190, child: DropdownButtonFormField<T>(initialValue: value, decoration: InputDecoration(labelText: label), items: values.map((item) => DropdownMenuItem(value: item, child: Text(display(item)))).toList(), onChanged: onChanged));
  Widget _stringDropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) => _dropdown(label, value, values, onChanged, (item) => item);
  static String _reportTypeLabel(_WorkshopReportType type) => switch (type) { _WorkshopReportType.repairJobs => 'Repair jobs', _WorkshopReportType.vehicleHistory => 'Vehicle history', _WorkshopReportType.technicianWork => 'Technician work', _WorkshopReportType.costs => 'Costs', _WorkshopReportType.inspections => 'Inspections' };
}

class _WorkshopReportData { const _WorkshopReportData({required this.jobs, required this.inspections}); final List<RepairJob> jobs; final List<WorkshopInspection> inspections; }
class _WorkshopReportsAccessDenied extends StatelessWidget { const _WorkshopReportsAccessDenied(); @override Widget build(BuildContext context) => const Scaffold(body: AppEmptyState(title: 'Access denied', message: 'Workshop reports are available to Workshop management only.')); }
