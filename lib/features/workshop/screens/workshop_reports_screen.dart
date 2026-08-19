import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/models/user.dart';
import '../../auth/models/user_role.dart';
import '../../auth/services/permission_service.dart';
import '../../auth/services/user_service.dart';
import '../../reports/services/pdf_export_service.dart';
import '../models/repair_job.dart';
import '../models/inspection_item.dart';
import '../models/workshop_inspection.dart';
import '../services/workshop_reporting_service.dart';
import '../services/workshop_reports_pdf_service.dart';

enum _WorkshopReportType {
  repairJobs,
  vehicleHistory,
  technicianWork,
  costs,
  inspection,
}

class WorkshopReportsScreen extends StatefulWidget {
  const WorkshopReportsScreen({super.key});

  @override
  State<WorkshopReportsScreen> createState() => _WorkshopReportsScreenState();
}

class _WorkshopReportsScreenState extends State<WorkshopReportsScreen> {
  final _reporting = WorkshopReportingService();
  final _pdfService = const WorkshopReportsPdfService();
  final _pdfExportService = const PdfExportService();
  late Future<_ReportPageData> _future;

  _WorkshopReportType _type = _WorkshopReportType.repairJobs;
  _ReportPeriod _period = _ReportPeriod.last30Days;
  DateTimeRange? _customRange;
  int? _vehicleId;
  String? _technicianId;
  RepairJobStatus? _status;
  RepairPriority? _priority;
  int? _inspectionId;
  Future<VehicleWorkshopHistory>? _vehicleHistoryFuture;
  String? _vehicleHistoryKey;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportPageData> _load() async {
    final results = await Future.wait<Object>([
      _reporting.loadSource(),
      UserService.instance.getUsersByRole(UserRole.technician),
    ]);
    return _ReportPageData(
      source: results[0] as WorkshopReportSource,
      technicians: results[1] as List<User>,
    );
  }

  WorkshopReportFilter _filter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = switch (_period) {
      _ReportPeriod.today => DateTimeRange(start: today, end: today),
      _ReportPeriod.last7Days =>
        DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today),
      _ReportPeriod.last30Days =>
        DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today),
      _ReportPeriod.custom => _customRange,
    };
    return WorkshopReportFilter(
      start: range?.start,
      end: range?.end,
      vehicleId: _vehicleId,
      technicianId: _technicianId,
      status: _status,
      priority: _priority,
    );
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      initialDateRange: _customRange,
    );
    if (!mounted || selected == null) return;
    if (selected.start.isAfter(selected.end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The start date must not be after the end date.')),
      );
      return;
    }
    setState(() {
      _customRange = selected;
      _period = _ReportPeriod.custom;
    });
  }

  List<RepairJob> _jobs(_ReportPageData data) =>
      _reporting.filterJobs(data.source.jobs, _filter());

  List<WorkshopInspection> _inspections(_ReportPageData data) =>
      _reporting.filterInspections(data.source.inspections, _filter());

  String _technicianLabel(_ReportPageData data, String? id) {
    if (id == null || id.isEmpty) return 'Unassigned / legacy';
    final matching = data.technicians
        .where((user) => user.id == id)
        .map((user) => user.username)
        .toList(growable: false);
    return matching.isEmpty ? 'Technician $id' : matching.first;
  }

  Future<Uint8List> _createPdf(_ReportPageData data) async {
    final jobs = _jobs(data);
    final inspections = _inspections(data);
    final filterSummary = _filterSummary(data);
    return switch (_type) {
      _WorkshopReportType.repairJobs => _pdfService.generateRepairJobs(
          jobs: jobs,
          inspections: inspections,
          filterSummary: filterSummary,
        ),
      _WorkshopReportType.vehicleHistory => _createVehicleHistoryPdf(data, jobs, inspections),
      _WorkshopReportType.technicianWork => _pdfService.generateTechnicianWork(
          summary: _technicianId == null
              ? null
              : _reporting.technicianSummary(jobs, _technicianId!),
          technicianName: _technicianLabel(data, _technicianId),
          filterSummary: filterSummary,
        ),
      _WorkshopReportType.costs => _pdfService.generateCosts(
          summary: _reporting.costSummary(jobs),
          filterSummary: filterSummary,
        ),
      _WorkshopReportType.inspection => _createInspectionPdf(),
    };
  }

  Future<Uint8List> _createVehicleHistoryPdf(
    _ReportPageData data,
    List<RepairJob> jobs,
    List<WorkshopInspection> inspections,
  ) async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) throw StateError('Select a vehicle first.');
    final items = <int, List<InspectionItem>>{};
    for (final inspection in inspections.where((item) => item.id != null)) {
      final report = await _reporting.loadInspectionReport(inspection.id!);
      items[inspection.id!] = report.items;
    }
    final history = _reporting.vehicleHistory(
      vehicleId: vehicleId,
      inspections: inspections,
      jobs: jobs,
      itemsByInspection: items,
    );
    return _pdfService.generateVehicleHistory(
      history: history,
      filterSummary: _filterSummary(data),
    );
  }

  Future<VehicleWorkshopHistory> _loadVehicleHistory(
    _ReportPageData data,
    List<RepairJob> jobs,
    List<WorkshopInspection> inspections,
  ) async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) {
      throw StateError('Select a vehicle first.');
    }
    final items = <int, List<InspectionItem>>{};
    for (final inspection in inspections.where((item) => item.id != null)) {
      final report = await _reporting.loadInspectionReport(inspection.id!);
      items[inspection.id!] = report.items;
    }
    return _reporting.vehicleHistory(
      vehicleId: vehicleId,
      inspections: inspections,
      jobs: jobs,
      itemsByInspection: items,
    );
  }

  Future<Uint8List> _createInspectionPdf() async {
    final inspectionId = _inspectionId;
    if (inspectionId == null) throw StateError('Select an inspection first.');
    final report = await _reporting.loadInspectionReport(inspectionId);
    return _pdfService.generateInspectionReport(report);
  }

  Future<void> _preview(_ReportPageData data) async {
    try {
      final bytes = await _createPdf(data);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfPreview(build: (_) async => bytes)),
      );
    } on StateError catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _printOrSave(_ReportPageData data) async {
    try {
      final bytes = await _createPdf(data);
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      final file = await _pdfExportService.savePdf(
        bytes,
        'workshop_report_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) _showMessage('PDF saved to ${file.path}');
    } on StateError catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _exportCsv(_ReportPageData data) async {
    if (_type == _WorkshopReportType.inspection) return;
    final jobs = _jobs(data);
    final rows = _csvRows(data, jobs);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/workshop_${_type.name}_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(rows.join('\n'));
    if (mounted) _showMessage('CSV saved to ${file.path}');
  }

  List<String> _csvRows(_ReportPageData data, List<RepairJob> jobs) {
    String row(Iterable<Object?> values) => values
        .map((value) => '"${value.toString().replaceAll('"', '""')}"')
        .join(',');
    switch (_type) {
      case _WorkshopReportType.vehicleHistory:
        return [
          row(['Inspection', 'Vehicle', 'Type', 'Result', 'Status', 'Date']),
          ..._inspections(data).map((inspection) => row([
                inspection.inspectionNumber,
                inspection.registration,
                inspection.inspectionType.name,
                inspection.overallResult.name,
                inspection.status.name,
                inspection.dateStarted.toIso8601String(),
              ])),
        ];
      case _WorkshopReportType.costs:
        return [
          row(['Job', 'Vehicle', 'Priority', 'Status', 'Estimated cost', 'Actual cost', 'Estimated hours', 'Actual hours']),
          ...jobs.map((job) => row([job.jobNumber, job.vehicleRegistration, job.priority.name, job.status.name, job.estimatedCost, job.actualCost, job.estimatedHours, job.actualHours])),
        ];
      case _WorkshopReportType.technicianWork:
      case _WorkshopReportType.repairJobs:
        return [
          row(['Job', 'Vehicle', 'Inspection', 'Defect', 'Technician ID', 'Technician', 'Priority', 'Status', 'Parts required', 'Estimated hours', 'Actual hours', 'Estimated cost', 'Actual cost', 'Created', 'Started', 'Completed']),
          ...jobs.map((job) => row([job.jobNumber, job.vehicleRegistration, job.inspectionId, job.title, job.technicianId ?? '', _technicianLabel(data, job.technicianId), job.priority.name, job.status.name, job.partsRequired, job.estimatedHours, job.actualHours, job.estimatedCost, job.actualCost, job.createdAt.toIso8601String(), job.startedAt?.toIso8601String() ?? '', job.completedAt?.toIso8601String() ?? ''])),
        ];
      case _WorkshopReportType.inspection:
        return const [];
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  String _filterSummary(_ReportPageData data) {
    final vehicles = data.source.inspections
        .where((inspection) => inspection.vehicleId == _vehicleId)
        .map((inspection) => inspection.registration)
        .toList(growable: false);
    final vehicle = vehicles.isEmpty ? null : vehicles.first;
    return [_period.label(_customRange), vehicle ?? 'All vehicles', _technicianLabel(data, _technicianId), _status?.name ?? 'All statuses', _priority?.name ?? 'All priorities'].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageWorkshop) {
      return const _WorkshopReportsAccessDenied();
    }
    return AppPageScaffold(
      title: 'Workshop Reports',
      subtitle: 'Operational repair, inspection, technician and cost reporting.',
      child: FutureBuilder<_ReportPageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading Workshop reports...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load Workshop reporting data.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          return _content(snapshot.data!);
        },
      ),
    );
  }

  Widget _content(_ReportPageData data) {
    final jobs = _jobs(data);
    final inspections = _inspections(data);
    final vehicles = <int, WorkshopInspection>{
      for (final inspection in data.source.inspections) inspection.vehicleId: inspection,
    }.values.toList()..sort((a, b) => a.registration.compareTo(b.registration));
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SectionCard(title: 'Report type and filters', child: _filters(data, vehicles)),
        const SizedBox(height: 24),
        SectionCard(title: _title, child: _summary(data, jobs, inspections)),
        const SizedBox(height: 24),
        SectionCard(title: 'Export actions', child: Wrap(spacing: 10, runSpacing: 10, children: [
          OutlinedButton.icon(onPressed: () => _preview(data), icon: const Icon(Icons.preview_outlined), label: const Text('Preview PDF')),
          FilledButton.tonalIcon(onPressed: () => _printOrSave(data), icon: const Icon(Icons.print_outlined), label: const Text('Print / Save PDF')),
          if (_type != _WorkshopReportType.inspection) OutlinedButton.icon(onPressed: () => _exportCsv(data), icon: const Icon(Icons.table_view_outlined), label: const Text('Export CSV')),
        ])),
        const SizedBox(height: 24),
        _results(data, jobs, inspections),
      ],
    );
  }

  Widget _filters(_ReportPageData data, List<WorkshopInspection> vehicles) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _dropdown('Report', _type, _WorkshopReportType.values, (value) => setState(() => _type = value!), _typeLabel),
          _dropdown('Period', _period, _ReportPeriod.values, (value) {
            if (value == _ReportPeriod.custom) {
              _selectCustomRange();
            } else {
              setState(() => _period = value!);
            }
          }, (value) => value.label(_customRange)),
          if (_period == _ReportPeriod.custom)
            OutlinedButton.icon(onPressed: _selectCustomRange, icon: const Icon(Icons.date_range_outlined), label: Text(_period.label(_customRange))),
          if (_type != _WorkshopReportType.technicianWork)
            _nullableDropdown<int>('Vehicle', _vehicleId, vehicles.map((vehicle) => _Option(vehicle.vehicleId, '${vehicle.registration} • ${vehicle.fleetNumber}')).toList(), (value) => setState(() => _vehicleId = value)),
          if (_type == _WorkshopReportType.technicianWork || _type == _WorkshopReportType.repairJobs)
            _nullableDropdown<String>('Technician', _technicianId, data.technicians.map((user) => _Option(user.id, user.username)).toList(), (value) => setState(() => _technicianId = value)),
          if (_type == _WorkshopReportType.repairJobs || _type == _WorkshopReportType.costs)
            _nullableDropdown('Status', _status, RepairJobStatus.values.map((value) => _Option(value, _readable(value.name))).toList(), (value) => setState(() => _status = value)),
          if (_type == _WorkshopReportType.repairJobs || _type == _WorkshopReportType.costs)
            _nullableDropdown('Priority', _priority, RepairPriority.values.map((value) => _Option(value, _readable(value.name))).toList(), (value) => setState(() => _priority = value)),
          if (_type == _WorkshopReportType.inspection)
            _nullableDropdown<int>('Inspection', _inspectionId, data.source.inspections.where((inspection) => inspection.id != null).map((inspection) => _Option(inspection.id!, '${inspection.inspectionNumber} • ${inspection.registration}')).toList(), (value) => setState(() => _inspectionId = value)),
        ],
      );

  Widget _summary(_ReportPageData data, List<RepairJob> jobs, List<WorkshopInspection> inspections) {
    if (_type == _WorkshopReportType.vehicleHistory && _vehicleId == null) return const Text('Select a vehicle to view its Workshop history.');
    if (_type == _WorkshopReportType.technicianWork && _technicianId == null) return const Text('Select a Technician account to view assigned work.');
    if (_type == _WorkshopReportType.inspection && _inspectionId == null) return const Text('Select a Workshop inspection to create its detailed report.');
    if (_type == _WorkshopReportType.vehicleHistory) {
      final key = '$_vehicleId|${_period.name}|${_customRange?.start}|${_customRange?.end}|${_status?.name}|${_priority?.name}';
      if (_vehicleHistoryKey != key) {
        _vehicleHistoryKey = key;
        _vehicleHistoryFuture = _loadVehicleHistory(data, jobs, inspections);
      }
      return FutureBuilder<VehicleWorkshopHistory>(
        future: _vehicleHistoryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading vehicle history summary...');
          final history = snapshot.data!;
          return Wrap(spacing: 18, runSpacing: 12, children: [
            _metric('Inspections', '${history.inspections.length}'),
            _metric('Failed / Repair Required Items', '${history.failedOrRepairRequiredItems}'),
            _metric('Repair Jobs', '${history.jobs.length}'),
            _metric('Completed Repairs', '${history.completedJobs}'),
            _metric('Outstanding Repairs', '${history.outstandingJobs}'),
            _metric('Actual Labour Hours', history.actualHours.toStringAsFixed(1)),
            _metric('Actual Repair Cost', _money(history.actualCost)),
          ]);
        },
      );
    }
    final values = switch (_type) {
      _WorkshopReportType.repairJobs => {'Matching jobs': jobs.length, 'Inspections': inspections.length},
      _WorkshopReportType.vehicleHistory => <String, Object>{},
      _WorkshopReportType.technicianWork => _technicianSummary(jobs),
      _WorkshopReportType.costs => _costSummary(jobs),
      _WorkshopReportType.inspection => {'Selected inspection': _inspectionId},
    };
    return Wrap(spacing: 18, runSpacing: 12, children: values.entries.map((entry) => _metric(entry.key, '${entry.value}')).toList());
  }

  Map<String, Object> _technicianSummary(List<RepairJob> jobs) {
    final id = _technicianId!;
    final summary = _reporting.technicianSummary(jobs, id);
    return {'Assigned': summary.jobs.length, 'Active': summary.activeJobs, 'Awaiting review': summary.awaitingReview, 'Completed': summary.completedJobs, 'Vehicles': summary.vehicleCount, 'Actual hours': summary.actualHours.toStringAsFixed(1), 'Actual cost': _money(summary.actualCost)};
  }

  Map<String, Object> _costSummary(List<RepairJob> jobs) {
    final summary = _reporting.costSummary(jobs);
    return {'Jobs': summary.jobs.length, 'Completed': summary.completedJobs, 'Outstanding': summary.outstandingJobs, 'Estimated cost': _money(summary.estimatedCost), 'Actual cost': _money(summary.actualCost), 'Variance': _money(summary.costVariance), 'Estimated hours': summary.estimatedHours.toStringAsFixed(1), 'Actual hours': summary.actualHours.toStringAsFixed(1)};
  }

  Widget _results(_ReportPageData data, List<RepairJob> jobs, List<WorkshopInspection> inspections) {
    if (_type == _WorkshopReportType.inspection) return const AppEmptyState(title: 'Inspection report', message: 'Use the selected inspection to preview or save a structured report.');
    if (_type == _WorkshopReportType.vehicleHistory && _vehicleId == null) return const SizedBox.shrink();
    if (_type == _WorkshopReportType.technicianWork && _technicianId == null) return const SizedBox.shrink();
    if (jobs.isEmpty && inspections.isEmpty) return const AppEmptyState(title: 'No matching Workshop records', message: 'Adjust the selected report filters.');
    return SectionCard(title: 'Results', child: Column(children: [
      ...inspections.take(20).map((inspection) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.assignment_outlined), title: Text('${inspection.inspectionNumber} • ${inspection.registration}'), subtitle: Text('${_readable(inspection.inspectionType.name)} • ${_readable(inspection.overallResult.name)} • ${_date(inspection.dateStarted)}'), trailing: Text(_readable(inspection.status.name)))),
      ...jobs.take(30).map((job) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.build_outlined), title: Text('${job.jobNumber} • ${job.title}'), subtitle: Text('${job.vehicleRegistration} • ${_technicianLabel(data, job.technicianId)} • ${_readable(job.status.name)}'), trailing: Text(_money(job.actualCost)))),
    ]));
  }

  Widget _metric(String label, String value) => SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), Text(label)]));
  Widget _dropdown<T>(String label, T value, List<T> values, ValueChanged<T?> changed, String Function(T) display) => SizedBox(width: 210, child: DropdownButtonFormField<T>(initialValue: value, isExpanded: true, decoration: InputDecoration(labelText: label), items: values.map((item) => DropdownMenuItem(value: item, child: Text(display(item), overflow: TextOverflow.ellipsis))).toList(), onChanged: changed));
  Widget _nullableDropdown<T>(String label, T? value, List<_Option<T>> options, ValueChanged<T?> changed) => SizedBox(width: 210, child: DropdownButtonFormField<T?>(initialValue: value, isExpanded: true, decoration: InputDecoration(labelText: label), items: [DropdownMenuItem<T?>(value: null, child: const Text('All')), ...options.map((option) => DropdownMenuItem<T?>(value: option.value, child: Text(option.label, overflow: TextOverflow.ellipsis)))], onChanged: changed));
  String get _title => _typeLabel(_type);
  static String _typeLabel(_WorkshopReportType value) => switch (value) { _WorkshopReportType.repairJobs => 'Repair Job Report', _WorkshopReportType.vehicleHistory => 'Vehicle Workshop History', _WorkshopReportType.technicianWork => 'Technician Work Report', _WorkshopReportType.costs => 'Workshop Cost Report', _WorkshopReportType.inspection => 'Inspection Report' };
  static String _readable(String value) => value.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])|_'), (_) => ' ').split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  static String _money(double value) => '£${value.toStringAsFixed(2)}';
  static String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _ReportPageData { const _ReportPageData({required this.source, required this.technicians}); final WorkshopReportSource source; final List<User> technicians; }
class _Option<T> { const _Option(this.value, this.label); final T value; final String label; }
enum _ReportPeriod { today, last7Days, last30Days, custom }
extension on _ReportPeriod {
  String label(DateTimeRange? range) => switch (this) {
        _ReportPeriod.today => 'Today',
        _ReportPeriod.last7Days => 'Last 7 days',
        _ReportPeriod.last30Days => 'Last 30 days',
        _ReportPeriod.custom => range == null
            ? 'Choose custom range'
            : '${_reportDate(range.start)} – ${_reportDate(range.end)}',
      };
}
String _reportDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
class _WorkshopReportsAccessDenied extends StatelessWidget { const _WorkshopReportsAccessDenied(); @override Widget build(BuildContext context) => const Scaffold(body: AppEmptyState(title: 'Access denied', message: 'Workshop reports are available to Workshop management only.')); }
