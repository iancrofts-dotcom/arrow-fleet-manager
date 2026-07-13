import 'package:flutter/material.dart';

import '../models/fleet_report.dart';
import '../services/fleet_report_service.dart';
import '../widgets/fleet_report_card.dart';




class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FleetReportService _reportService =
      FleetReportService();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Reports'),
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