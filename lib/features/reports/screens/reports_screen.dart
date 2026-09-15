import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/fleet_report.dart';
import '../models/report_document.dart';
import '../models/report_module.dart';
import '../services/fleet_report_document_adapter.dart';
import '../services/fleet_report_service.dart';
import '../services/report_csv_service.dart';
import '../services/report_document_pdf_service.dart';
import '../services/report_file_exporter.dart';
import '../services/report_operation_gate.dart';
import '../widgets/report_preview_screen.dart';

typedef FleetReportLoader = Future<FleetReport> Function();
typedef ReportDocumentLoader =
    Future<ReportDocument> Function(ReportModuleQuery query);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.generateReport, this.generateDocument});

  final FleetReportLoader? generateReport;
  final ReportDocumentLoader? generateDocument;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  FleetReportService? _reportService;
  late final FleetReportLoader _generateReport;
  final ReportDocumentPdfService _pdfService = const ReportDocumentPdfService();
  final ReportCsvService _csvService = const ReportCsvService();
  final ReportFileExporter _fileExporter = const ReportFileExporter();
  final ReportOperationGate _operationGate = ReportOperationGate();
  final FleetReportDocumentAdapter _documentAdapter =
      const FleetReportDocumentAdapter();

  ReportModule _module = ReportModule.fleetSummary;
  DateTime? _from;
  DateTime? _to;
  late Future<ReportDocument> _documentFuture;

  bool get _hasModuleLoader => widget.generateDocument != null;

  @override
  void initState() {
    super.initState();
    if (widget.generateReport == null) _reportService = FleetReportService();
    _generateReport = widget.generateReport ?? _reportService!.generateReport;
    _documentFuture = _loadDocument();
  }

  ReportModuleQuery get _query => ReportModuleQuery(
    module: _module,
    from: _module.supportsDateRange ? _from : null,
    to: _module.supportsDateRange ? _to : null,
  );

  Future<ReportDocument> _loadDocument() {
    final loader = widget.generateDocument;
    if (loader != null) return loader(_query);
    return _generateReport().then(_documentAdapter.build);
  }

  Future<void> _refresh() async {
    setState(() => _documentFuture = _loadDocument());
    await _documentFuture;
  }

  Future<void> _selectModule(ReportModule module) async {
    if (module != ReportModule.fleetSummary && !_hasModuleLoader) return;
    setState(() {
      _module = module;
      _documentFuture = _loadDocument();
    });
    await _documentFuture;
  }

  Future<void> _pickFrom() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected == null) return;
    if (_to != null && selected.isAfter(_to!)) {
      _showMessage('From date cannot be after the To date.');
      return;
    }
    setState(() {
      _from = selected;
      _documentFuture = _loadDocument();
    });
  }

  Future<void> _pickTo() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected == null) return;
    if (_from != null && selected.isBefore(_from!)) {
      _showMessage('To date cannot be before the From date.');
      return;
    }
    setState(() {
      _to = selected;
      _documentFuture = _loadDocument();
    });
  }

  Future<void> _clearDates() async {
    setState(() {
      _from = null;
      _to = null;
      _documentFuture = _loadDocument();
    });
    await _documentFuture;
  }

  Future<void> _runReportOperation({
    required String failureMessage,
    required Future<void> Function() operation,
  }) async {
    if (_operationGate.isRunning) return;
    final running = _operationGate.run(operation);
    setState(() {});
    try {
      await running;
    } catch (_) {
      if (mounted) _showMessage(failureMessage);
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _previewPdf() => _runReportOperation(
    failureMessage: 'Unable to generate report preview.',
    operation: () async {
      final document = await _loadDocument();
      final pdfBytes = await _pdfService.generate(document);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(
            title: '${document.title} Preview',
            child: PdfPreview(build: (_) async => pdfBytes),
          ),
        ),
      );
    },
  );

  Future<void> _exportPdf() => _runReportOperation(
    failureMessage: 'Unable to export PDF report.',
    operation: () async {
      final document = await _loadDocument();
      final bytes = await _pdfService.generate(document);
      final result = await _fileExporter.savePdf(
        bytes,
        _exportFileName(document),
      );
      if (mounted) _showMessage(result.message);
    },
  );

  Future<void> _exportCsv() => _runReportOperation(
    failureMessage: 'Unable to export CSV report.',
    operation: () async {
      final document = await _loadDocument();
      final csv = _csvService.generate(document);
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
      final result = await _fileExporter.saveCsv(
        bytes,
        _exportFileName(document),
      );
      if (mounted) _showMessage(result.message);
    },
  );

  String _exportFileName(ReportDocument document) {
    final timestamp = document.generatedAt
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return 'fleetiq_${document.id}_$timestamp';
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canViewReports) {
      return const _ReportsAccessDenied();
    }

    return AppPageScaffold(
      title: 'Reports Centre',
      subtitle:
          'Live FleetIQ management, operational and audit-ready reports with PDF and CSV export.',
      actions: [
        OutlinedButton.icon(
          onPressed: _operationGate.isRunning ? null : _previewPdf,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Preview PDF'),
        ),
        OutlinedButton.icon(
          onPressed: _operationGate.isRunning ? null : _exportCsv,
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Export CSV'),
        ),
        FilledButton.icon(
          onPressed: _operationGate.isRunning ? null : _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Export PDF'),
        ),
      ],
      child: FutureBuilder<ReportDocument>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading reports centre...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load the selected report.',
              onRetry: _refresh,
            );
          }
          final document = snapshot.data;
          if (document == null) {
            return const AppEmptyState(
              title: 'No report available',
              message: 'Refresh to generate the selected report.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModuleSelector(
                    selected: _module,
                    centralModulesEnabled: _hasModuleLoader,
                    onSelected: _selectModule,
                  ),
                  if (_module.supportsDateRange) ...[
                    const SizedBox(height: 12),
                    _DateRangeBar(
                      from: _from,
                      to: _to,
                      onFrom: _pickFrom,
                      onTo: _pickTo,
                      onClear: _clearDates,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ReportDocumentCard(document: document),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModuleSelector extends StatelessWidget {
  const _ModuleSelector({
    required this.selected,
    required this.centralModulesEnabled,
    required this.onSelected,
  });

  final ReportModule selected;
  final bool centralModulesEnabled;
  final Future<void> Function(ReportModule module) onSelected;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Report Modules',
    subtitle: 'Choose the live dataset to view and export.',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final module in ReportModule.values)
          ChoiceChip(
            label: Text(module.label),
            selected: selected == module,
            onSelected:
                module == ReportModule.fleetSummary || centralModulesEnabled
                ? (_) => onSelected(module)
                : null,
          ),
      ],
    ),
  );
}

class _DateRangeBar extends StatelessWidget {
  const _DateRangeBar({
    required this.from,
    required this.to,
    required this.onFrom,
    required this.onTo,
    required this.onClear,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Date Range',
    subtitle:
        'Filter the selected operational report before PDF or CSV export.',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onFrom,
          icon: const Icon(Icons.event_outlined),
          label: Text('From: ${from == null ? 'Any' : _dateLabel(from!)}'),
        ),
        OutlinedButton.icon(
          onPressed: onTo,
          icon: const Icon(Icons.event_available_outlined),
          label: Text('To: ${to == null ? 'Any' : _dateLabel(to!)}'),
        ),
        if (from != null || to != null)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
      ],
    ),
  );
}

class _ReportDocumentCard extends StatelessWidget {
  const _ReportDocumentCard({required this.document});

  final ReportDocument document;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: document.title,
    subtitle: document.subtitle,
    child: Column(
      children: [
        for (
          var sectionIndex = 0;
          sectionIndex < document.sections.length;
          sectionIndex++
        ) ...[
          _ReportSectionView(section: document.sections[sectionIndex]),
          if (sectionIndex != document.sections.length - 1)
            const Divider(height: 28),
        ],
      ],
    ),
  );
}

class _ReportSectionView extends StatelessWidget {
  const _ReportSectionView({required this.section});

  final ReportSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(section.title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (section.rows.isEmpty)
        const Text('No records in this report section.')
      else
        ...section.rows.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(row.label)),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _ReportsAccessDenied extends StatelessWidget {
  const _ReportsAccessDenied();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Access Denied')),
    body: const Center(
      child: Text('You do not have permission to view fleet reports.'),
    ),
  );
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
