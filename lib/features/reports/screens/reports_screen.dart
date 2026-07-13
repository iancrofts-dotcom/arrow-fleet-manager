import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/fleet_report.dart';
import '../services/fleet_report_service.dart';
import '../services/pdf_report_service.dart';
import '../services/pdf_export_service.dart';
import '../services/pdf_share_service.dart';
import '../widgets/fleet_report_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FleetReportService _reportService = FleetReportService();

  final PdfReportService _pdfReportService =
      const PdfReportService();

  final PdfExportService _pdfExportService =
      const PdfExportService();

  final PdfShareService _pdfShareService =
      const PdfShareService();

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

  Future<void> _previewPdf() async {
    final report = await _reportService.generateReport();

    final pdfBytes =
        await _pdfReportService.generatePdf(report);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreview(
          build: (_) async => pdfBytes,
        ),
      ),
    );
  }

  Future<void> _savePdf() async {
    final report = await _reportService.generateReport();

    final pdfBytes =
        await _pdfReportService.generatePdf(report);

    final file = await _pdfExportService.savePdf(
      pdfBytes,
      'fleet_report_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF saved to:\n${file.path}',
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    final report = await _reportService.generateReport();

    final pdfBytes =
        await _pdfReportService.generatePdf(report);

    final file = await _pdfExportService.savePdf(
      pdfBytes,
      'fleet_report_share',
    );

    await _pdfShareService.sharePdf(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save PDF',
            onPressed: _savePdf,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: FutureBuilder<FleetReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading report:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No report available.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet Summary',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  FleetReportCard(
                    report: snapshot.data!,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}