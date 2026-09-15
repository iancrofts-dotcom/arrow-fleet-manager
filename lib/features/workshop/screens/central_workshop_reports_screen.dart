import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/central_workshop_summary.dart';
import '../../../backend/workshop/supabase_workshop_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../services/central_workshop_pdf_service.dart';

class CentralWorkshopReportsScreen extends StatefulWidget {
  const CentralWorkshopReportsScreen({super.key});

  @override
  State<CentralWorkshopReportsScreen> createState() =>
      _CentralWorkshopReportsScreenState();
}

class _CentralWorkshopReportsScreenState
    extends State<CentralWorkshopReportsScreen> {
  final _repository = const BackendWorkshopRepository(
    SupabaseWorkshopGateway(),
  );
  late Future<
    ({
      List<BackendWorkshopInspection> inspections,
      List<BackendWorkshopRepairJob> repairs,
    })
  >
  _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<
    ({
      List<BackendWorkshopInspection> inspections,
      List<BackendWorkshopRepairJob> repairs,
    })
  >
  _load() async => (
    inspections: await _repository.listInspections(),
    repairs: await _repository.listRepairJobs(),
  );

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<void> _print(
    List<BackendWorkshopInspection> inspections,
    List<BackendWorkshopRepairJob> repairs,
  ) async {
    final bytes = await const CentralWorkshopPdfService().workshopReport(
      inspections: inspections,
      repairs: repairs,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Workshop Reports',
    subtitle: 'Live Workshop performance, repair totals and printable records.',
    child:
        FutureBuilder<
          ({
            List<BackendWorkshopInspection> inspections,
            List<BackendWorkshopRepairJob> repairs,
          })
        >(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const AppLoadingState(
                label: 'Loading Workshop reports...',
              );
            }
            if (snapshot.hasError && !snapshot.hasData) {
              return AppErrorState(
                title: 'Unable to load reports',
                message: '${snapshot.error}',
                onRetry: _refresh,
              );
            }
            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();
            final summary = CentralWorkshopSummary.fromData(
              inspections: data.inspections,
              repairJobs: data.repairs,
            );
            final estimated = data.repairs.fold<double>(
              0,
              (sum, row) => sum + row.estimatedCost,
            );
            final actual = data.repairs.fold<double>(
              0,
              (sum, row) => sum + row.actualCost,
            );
            return ListView(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _print(data.inspections, data.repairs),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Preview / Print Report'),
                  ),
                ),
                const SizedBox(height: 12),
                _metric(
                  context,
                  'Total Inspections',
                  summary.totalInspections.toString(),
                  Icons.assignment_outlined,
                ),
                _metric(
                  context,
                  'Open Inspections',
                  summary.openInspections.toString(),
                  Icons.pending_actions_outlined,
                ),
                _metric(
                  context,
                  'Completed Inspections',
                  summary.completedInspections.toString(),
                  Icons.task_alt_outlined,
                ),
                _metric(
                  context,
                  'Critical Failures',
                  summary.criticalFailures.toString(),
                  Icons.warning_amber_outlined,
                ),
                _metric(
                  context,
                  'Outstanding Repairs',
                  summary.outstandingRepairs.toString(),
                  Icons.build_circle_outlined,
                ),
                _metric(
                  context,
                  'Awaiting Parts',
                  summary.awaitingParts.toString(),
                  Icons.inventory_2_outlined,
                ),
                _metric(
                  context,
                  'Estimated Repair Cost',
                  '£${estimated.toStringAsFixed(2)}',
                  Icons.request_quote_outlined,
                ),
                _metric(
                  context,
                  'Actual Repair Cost',
                  '£${actual.toStringAsFixed(2)}',
                  Icons.payments_outlined,
                ),
              ],
            );
          },
        ),
  );

  Widget _metric(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
