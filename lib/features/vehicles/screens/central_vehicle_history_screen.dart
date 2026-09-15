import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/supabase_workshop_gateway.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../../workshop/screens/central_workshop_inspection_details_screen.dart';
import '../../workshop/screens/central_workshop_repair_job_details_screen.dart';

class CentralVehicleHistoryScreen extends StatefulWidget {
  const CentralVehicleHistoryScreen({
    super.key,
    required this.vehicleId,
    required this.registration,
  });

  final String vehicleId;
  final String registration;

  @override
  State<CentralVehicleHistoryScreen> createState() =>
      _CentralVehicleHistoryScreenState();
}

class _CentralVehicleHistoryScreenState
    extends State<CentralVehicleHistoryScreen> {
  final BackendWorkshopRepository _repository = const BackendWorkshopRepository(
    SupabaseWorkshopGateway(),
  );

  late Future<_VehicleHistoryData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_VehicleHistoryData> _load() async {
    final results = await Future.wait<Object>([
      _repository.listInspections(),
      _repository.listRepairJobs(),
    ]);

    final inspections =
        (results[0] as List<BackendWorkshopInspection>)
            .where((row) => row.vehicleId == widget.vehicleId)
            .toList(growable: false)
          ..sort((a, b) => b.dateStarted.compareTo(a.dateStarted));

    final repairs =
        (results[1] as List<BackendWorkshopRepairJob>)
            .where((row) => row.vehicleId == widget.vehicleId)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _VehicleHistoryData(inspections: inspections, repairs: repairs);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _openInspection(BackendWorkshopInspection inspection) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CentralWorkshopInspectionDetailsScreen(
          inspectionId: inspection.id,
          repository: _repository,
        ),
      ),
    );
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openRepair(BackendWorkshopRepairJob repair) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CentralWorkshopRepairJobDetailsScreen(
          job: repair,
          repository: _repository,
        ),
      ),
    );
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccessWorkshop = PermissionService.instance.canAccessWorkshop;

    return AppPageScaffold(
      title: '${widget.registration} History',
      subtitle:
          'Central Workshop inspections and repair activity for this Vehicle.',
      actions: [
        if (canAccessWorkshop)
          TextButton.icon(
            onPressed: () => DashboardNavigation.openWorkshop(context),
            icon: const Icon(Icons.handyman_outlined),
            label: const Text('Open Workshop'),
          ),
        IconButton(
          tooltip: 'Refresh history',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: FutureBuilder<_VehicleHistoryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading Vehicle history...');
          }
          if (snapshot.hasError || snapshot.data == null) {
            return AppErrorState(
              title: 'Unable to load Vehicle history',
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _HistorySummary(data: data),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Workshop inspections',
                  subtitle: 'Inspection activity recorded centrally.',
                  child: data.inspections.isEmpty
                      ? const Text(
                          'No central Workshop inspections have been recorded for this Vehicle.',
                        )
                      : Column(
                          children: [
                            for (final inspection in data.inspections)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  inspection.overallResult == 'fail'
                                      ? Icons.error_outline
                                      : inspection.overallResult == 'pass'
                                      ? Icons.check_circle_outline
                                      : Icons.assignment_outlined,
                                ),
                                title: Text(inspection.inspectionNumber),
                                subtitle: Text(
                                  '${_label(inspection.inspectionType)} · '
                                  '${_label(inspection.status)} · '
                                  '${_date(inspection.dateStarted)}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openInspection(inspection),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Repair & maintenance jobs',
                  subtitle:
                      'Repair work raised from central Workshop inspections.',
                  child: data.repairs.isEmpty
                      ? const Text(
                          'No central repair jobs have been recorded for this Vehicle.',
                        )
                      : Column(
                          children: [
                            for (final repair in data.repairs)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.handyman_outlined),
                                title: Text(
                                  '${repair.jobNumber} · ${repair.title}',
                                ),
                                subtitle: Text(
                                  '${_label(repair.status)} · '
                                  '${_label(repair.priority)} · '
                                  '${_date(repair.createdAt)}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openRepair(repair),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.data});

  final _VehicleHistoryData data;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'History summary',
    subtitle: 'A quick operational view of this Vehicle.',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        StatusBadge.info('${data.inspections.length} inspections'),
        StatusBadge.info('${data.repairs.length} repair jobs'),
        if (data.openRepairs > 0)
          StatusBadge.warning('${data.openRepairs} open repairs')
        else
          StatusBadge.success('No open repairs'),
        if (data.failedInspections > 0)
          StatusBadge.critical('${data.failedInspections} failed inspections')
        else if (data.inspections.isNotEmpty)
          StatusBadge.success('No failed inspections'),
      ],
    ),
  );
}

class _VehicleHistoryData {
  const _VehicleHistoryData({required this.inspections, required this.repairs});

  final List<BackendWorkshopInspection> inspections;
  final List<BackendWorkshopRepairJob> repairs;

  int get openRepairs => repairs.where((repair) => repair.isOutstanding).length;

  int get failedInspections => inspections
      .where((inspection) => inspection.overallResult == 'fail')
      .length;
}

String _label(String value) {
  final spaced = value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ');
  if (spaced.isEmpty) {
    return spaced;
  }
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}
