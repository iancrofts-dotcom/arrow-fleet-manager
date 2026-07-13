import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/fleet_report.dart';
import '../services/fleet_report_service.dart';
import '../services/pdf_report_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
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
              child: Text('No report available.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: FleetReportCard(
                report: snapshot.data!,
              ),
            ),
          );
        },
      ),
    );
  }
}