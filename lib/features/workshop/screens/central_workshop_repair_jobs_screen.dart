import 'dart:async';

import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/supabase_workshop_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import 'central_workshop_repair_job_details_screen.dart';

class CentralWorkshopRepairJobsScreen extends StatefulWidget {
  const CentralWorkshopRepairJobsScreen({super.key});

  @override
  State<CentralWorkshopRepairJobsScreen> createState() =>
      _CentralWorkshopRepairJobsScreenState();
}

class _CentralWorkshopRepairJobsScreenState
    extends State<CentralWorkshopRepairJobsScreen> {
  final _repository = const BackendWorkshopRepository(
    SupabaseWorkshopGateway(),
  );
  late Future<List<BackendWorkshopRepairJob>> _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _future = _repository.listRepairJobs();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!mounted) return;
    final next = _repository.listRepairJobs();
    setState(() => _future = next);
    if (!silent) await next;
  }

  Future<void> _openJob(BackendWorkshopRepairJob job) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CentralWorkshopRepairJobDetailsScreen(
          job: job,
          repository: _repository,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Repair Jobs',
    subtitle: 'Live Workshop queue. Updates refresh automatically.',
    child: FutureBuilder<List<BackendWorkshopRepairJob>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppLoadingState(label: 'Loading repair jobs...');
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return AppErrorState(
            title: 'Unable to load repair jobs',
            message: '${snapshot.error}',
            onRetry: _refresh,
          );
        }
        final rows = snapshot.data ?? const <BackendWorkshopRepairJob>[];
        if (rows.isEmpty) {
          return const AppEmptyState(
            icon: Icons.build_circle_outlined,
            title: 'No repair jobs',
            message:
                'Defects raised by Drivers and Technicians will appear here.',
          );
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              leading: CircleAvatar(
                child: Icon(
                  row.partsRequired
                      ? Icons.inventory_2_outlined
                      : Icons.build_outlined,
                ),
              ),
              title: Text('${row.jobNumber} · ${row.vehicleRegistration}'),
              subtitle: Text(
                '${row.title}\n${_label(row.priority)} · ${_label(row.status)}'
                '${row.technicianName.isEmpty ? '' : ' · ${row.technicianName}'}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (row.status == 'awaitingInspection')
                    const Icon(Icons.verified_outlined),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _openJob(row),
            );
          },
        );
      },
    ),
  );

  static String _label(String value) => value
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      );
}
