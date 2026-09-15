import 'dart:async';

import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/central_workshop_summary.dart';
import '../../../backend/resilience/central_resilience_runtime.dart';
import '../../../backend/workshop/supabase_workshop_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/central_connection_banner.dart';
import '../../auth/services/permission_service.dart';
import 'central_workshop_inspection_details_screen.dart';
import 'central_workshop_inspection_list_screen.dart';
import 'central_workshop_new_inspection_launcher_web.dart'
    if (dart.library.io) 'central_workshop_new_inspection_launcher_native.dart';
import 'central_workshop_repair_jobs_screen.dart';
import 'central_workshop_reports_screen.dart';
import 'central_workshop_templates_screen.dart';

class CentralWorkshopDashboardData {
  const CentralWorkshopDashboardData({
    required this.inspections,
    required this.repairJobs,
    required this.summary,
  });
  final List<BackendWorkshopInspection> inspections;
  final List<BackendWorkshopRepairJob> repairJobs;
  final CentralWorkshopSummary summary;
}

class CentralWorkshopDashboardScreen extends StatefulWidget {
  const CentralWorkshopDashboardScreen({
    super.key,
    this.loadData,
    this.repository,
  });
  final Future<CentralWorkshopDashboardData> Function()? loadData;
  final BackendWorkshopRepository? repository;
  @override
  State<CentralWorkshopDashboardScreen> createState() =>
      _CentralWorkshopDashboardScreenState();
}

class _CentralWorkshopDashboardScreenState
    extends State<CentralWorkshopDashboardScreen> {
  late final BackendWorkshopRepository _repository;
  late Future<CentralWorkshopDashboardData> _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const BackendWorkshopRepository(SupabaseWorkshopGateway());
    _reload();
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

  void _reload() {
    _future = (widget.loadData ?? _load)();
  }

  Future<CentralWorkshopDashboardData> _load() async {
    final inspections = await _repository.listInspections();
    final repairs = await _repository.listRepairJobs();
    return CentralWorkshopDashboardData(
      inspections: inspections,
      repairJobs: repairs,
      summary: CentralWorkshopSummary.fromData(
        inspections: inspections,
        repairJobs: repairs,
      ),
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!mounted) return;
    setState(_reload);
    if (!silent) {
      await _future;
    }
  }

  Future<void> _newInspection() async {
    final id = await openCentralWorkshopNewInspection(context, _repository);
    if (id == null || !mounted) {
      return;
    }
    await _refresh();
    if (!mounted) {
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralWorkshopInspectionDetailsScreen(
          inspectionId: id,
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
    final permissions = PermissionService.instance;
    if (!permissions.canAccessWorkshop) {
      return const Scaffold(
        body: Center(child: Text('Workshop access is not available.')),
      );
    }
    return CentralConnectionBoundary(
      child: AppPageScaffold(
        title: 'Workshop',
        subtitle: 'Inspections, repairs and workshop activity.',
        child: FutureBuilder<CentralWorkshopDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState(
                label: 'Loading Workshop dashboard...',
              );
            }
            if (snapshot.hasError) {
              final offline =
                  CentralResilienceRuntime.instance.tracker.status.isOffline;
              return AppErrorState(
                title: offline
                    ? 'Workshop unavailable offline'
                    : 'Unable to load Workshop',
                message: offline
                    ? 'No saved Workshop data is available on this device yet. Reconnect to FleetIQ, open Workshop once while online, then it can use the last successfully loaded data during a connection loss.'
                    : 'Central Workshop data could not be loaded. Please try again.',
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1050
                          ? 3
                          : constraints.maxWidth >= 680
                          ? 2
                          : 1;
                      final spacing = 12.0;
                      final width = columns == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - spacing * (columns - 1)) /
                                columns;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          if (permissions.canOperateWorkshop)
                            SizedBox(
                              width: width,
                              child: _ActionCard(
                                icon: Icons.add_circle_outline,
                                title: 'New Inspection',
                                subtitle: permissions.isTechnician
                                    ? 'Create a defect or repair inspection'
                                    : 'Start a new vehicle inspection',
                                onTap: _newInspection,
                              ),
                            ),
                          if (permissions.canManageInspectionTemplates)
                            SizedBox(
                              width: width,
                              child: _ActionCard(
                                icon: Icons.article_outlined,
                                title: 'Inspection Templates',
                                subtitle:
                                    'View reusable central inspection forms',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CentralWorkshopTemplatesScreen(),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: width,
                            child: _ActionCard(
                              icon: Icons.assignment_outlined,
                              title: 'Inspection List',
                              subtitle: 'View and manage saved inspections',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CentralWorkshopInspectionListScreen(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _ActionCard(
                              icon: Icons.build_circle_outlined,
                              title: 'Repair Jobs',
                              subtitle: 'View workshop repair jobs',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CentralWorkshopRepairJobsScreen(),
                                ),
                              ),
                            ),
                          ),
                          if (permissions.canViewKpis)
                            SizedBox(
                              width: width,
                              child: _ActionCard(
                                icon: Icons.analytics_outlined,
                                title: 'Workshop Reports',
                                subtitle:
                                    'Review inspection and repair performance',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CentralWorkshopReportsScreen(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (permissions.canViewKpis) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Workshop Overview',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _metrics(context, data),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    permissions.isTechnician
                        ? 'Assigned / Recent Work'
                        : 'Recent Activity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.inspections.isEmpty && data.repairJobs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No central Workshop activity has been recorded yet.',
                        ),
                      ),
                    )
                  else ...[
                    ...data.inspections
                        .take(8)
                        .map(
                          (row) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.assignment_outlined),
                              title: Text(
                                '${row.inspectionNumber} · ${row.registration}',
                              ),
                              subtitle: Text(
                                '${_label(row.inspectionType)} · ${_label(row.status)} · ${_date(row.dateStarted)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CentralWorkshopInspectionDetailsScreen(
                                          inspectionId: row.id,
                                          repository: _repository,
                                        ),
                                  ),
                                );
                                if (mounted) {
                                  await _refresh();
                                }
                              },
                            ),
                          ),
                        ),
                    ...data.repairJobs
                        .where((row) => row.isOutstanding)
                        .take(5)
                        .map(
                          (row) => Card(
                            child: ListTile(
                              leading: Icon(
                                row.partsRequired
                                    ? Icons.inventory_2_outlined
                                    : Icons.build_outlined,
                              ),
                              title: Text(
                                '${row.jobNumber} · ${row.vehicleRegistration}',
                              ),
                              subtitle: Text(
                                '${row.title} · ${_label(row.status)}',
                              ),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metrics(BuildContext context, CentralWorkshopDashboardData data) {
    final today = DateTime.now();
    final completedToday = data.inspections
        .where(
          (row) =>
              row.dateCompleted != null &&
              _sameDay(row.dateCompleted!.toLocal(), today),
        )
        .length;
    final repairsRequired = data.inspections.fold<int>(
      0,
      (sum, row) => sum + row.repairsRequired,
    );
    final awaitingSignOff = data.inspections
        .where((row) => row.status == 'completed')
        .length;
    final metrics = <({String title, String value, IconData icon})>[
      (
        title: 'Open Inspections',
        value: data.summary.openInspections.toString(),
        icon: Icons.pending_actions_outlined,
      ),
      (
        title: 'Completed Today',
        value: completedToday.toString(),
        icon: Icons.task_alt_outlined,
      ),
      (
        title: 'Critical Failures',
        value: data.summary.criticalFailures.toString(),
        icon: Icons.warning_amber_outlined,
      ),
      (
        title: 'Repairs Required',
        value: repairsRequired.toString(),
        icon: Icons.build_outlined,
      ),
      (
        title: 'Repairs Outstanding',
        value: data.summary.outstandingRepairs.toString(),
        icon: Icons.build_circle_outlined,
      ),
      (
        title: 'Awaiting Parts',
        value: data.summary.awaitingParts.toString(),
        icon: Icons.inventory_2_outlined,
      ),
      (
        title: 'Awaiting Sign-off',
        value: awaitingSignOff.toString(),
        icon: Icons.approval_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(metric.icon, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.value,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(metric.title),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _label(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
