import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/fleet_report.dart';
import '../services/fleet_report_service.dart';
import '../services/pdf_report_service.dart';
import '../services/pdf_export_service.dart';
import '../services/pdf_share_service.dart';
import '../widgets/fleet_report_card.dart';
import '../widgets/report_preview_screen.dart';
import '../services/report_operation_gate.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FleetReportService _reportService = FleetReportService();

  final PdfReportService _pdfReportService = const PdfReportService();

  final PdfExportService _pdfExportService = const PdfExportService();

  final PdfShareService _pdfShareService = const PdfShareService();
  final ReportOperationGate _operationGate = ReportOperationGate();

  late Future<FleetReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _reportService.generateReport();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportFuture = _reportService.generateReport();
    });

    await _reportFuture;
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
    failureMessage: 'Unable to generate report.',
    operation: () async {
      final report = await _reportService.generateReport();
      final pdfBytes = await _pdfReportService.generatePdf(report);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(
            title: 'Fleet Report Preview',
            child: PdfPreview(build: (_) async => pdfBytes),
          ),
        ),
      );
    },
  );

  Future<void> _savePdf() => _runReportOperation(
    failureMessage: 'Unable to save report.',
    operation: () async {
      final report = await _reportService.generateReport();
      final pdfBytes = await _pdfReportService.generatePdf(report);
      final file = await _pdfExportService.savePdf(
        pdfBytes,
        'fleet_report_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) _showMessage('PDF saved to:\n${file.path}');
    },
  );

  Future<void> _sharePdf() => _runReportOperation(
    failureMessage: 'Unable to share report.',
    operation: () async {
      final report = await _reportService.generateReport();
      final pdfBytes = await _pdfReportService.generatePdf(report);
      final file = await _pdfExportService.savePdf(
        pdfBytes,
        'fleet_report_share',
      );
      await _pdfShareService.sharePdf(file);
      if (mounted) _showMessage('Report shared.');
    },
  );

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canViewReports) {
      return const _ReportsAccessDenied();
    }

    return AppPageScaffold(
      title: 'Fleet Reports',
      subtitle: 'Current fleet compliance and operational metrics.',
      actions: [
        OutlinedButton.icon(
          onPressed: _operationGate.isRunning ? null : _previewPdf,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Preview'),
        ),
        OutlinedButton.icon(
          onPressed: _operationGate.isRunning ? null : _savePdf,
          icon: const Icon(Icons.save_alt),
          label: const Text('Save'),
        ),
        FilledButton.icon(
          onPressed: _operationGate.isRunning ? null : _sharePdf,
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
      ],
      child: FutureBuilder<FleetReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading fleet report...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load the fleet report.',
              onRetry: _refresh,
            );
          }

          if (!snapshot.hasData) {
            return const AppEmptyState(
              title: 'No report available',
              message: 'Refresh to generate the current fleet report.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fleet Summary'),
                  const SizedBox(height: 12),
                  FleetReportCard(report: snapshot.data!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportsAccessDenied extends StatelessWidget {
  const _ReportsAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: const Center(
        child: Text('You do not have permission to view fleet reports.'),
      ),
    );
  }
}
