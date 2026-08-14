import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';
import '../models/workshop_dashboard_data.dart';
import '../repositories/workshop_repository.dart';
import '../services/workshop_dashboard_service.dart';
import 'inspection_wizard/inspection_wizard_screen.dart';
import 'workshop_inspection_screen.dart';
import '../models/workshop_inspection.dart';
import 'repair_jobs_screen.dart';

class WorkshopDashboardScreen extends StatefulWidget {
  const WorkshopDashboardScreen({super.key});

  @override
  State<WorkshopDashboardScreen> createState() =>
      _WorkshopDashboardScreenState();
}

class _WorkshopDashboardScreenState
    extends State<WorkshopDashboardScreen> {
  late final WorkshopDashboardService _dashboardService;
  late Future<WorkshopDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();

    _dashboardService = WorkshopDashboardService(
      WorkshopRepository(),
    );

    _dashboardFuture = _dashboardService.loadDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _dashboardService.loadDashboard();
    });

    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;

    if (!permissions.canAccessWorkshop) {
      return const _WorkshopAccessDenied();
    }

    if (!permissions.canViewKpis) {
      return const _TechnicianWorkshopLanding();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop'),
        leading: IconButton(
          tooltip: 'Back to main screen',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: FutureBuilder<WorkshopDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load dashboard.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final dashboard =
              snapshot.data ?? WorkshopDashboardData.empty();

          final hasCriticalIssues = dashboard.criticalFailures > 0;
          final hasRepairs = dashboard.repairsRequired > 0;
          final hasOutstandingRepairs =
              dashboard.repairsOutstanding > 0;
          final hasAwaitingParts =
              dashboard.awaitingParts > 0;
          final hasAwaitingSignOff =
              dashboard.awaitingSignOff > 0;

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkshopHeader(),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quick Actions',
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh dashboard',
                        onPressed: _refreshDashboard,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 1050
                          ? 3
                          : width >= 680
                              ? 2
                              : 1;

                      final spacing = 12.0;
                      final itemWidth = columns == 1
                          ? width
                          : (width -
                                  (spacing * (columns - 1))) /
                              columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _ActionCard(
                              icon: Icons.add_circle_outline,
                              title: 'New Inspection',
                              subtitle:
                                  'Start a new vehicle inspection',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const InspectionWizardScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _ActionCard(
                              icon: Icons.assignment_outlined,
                              title: 'Inspection List',
                              subtitle:
                                  'View and manage saved inspections',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const WorkshopInspectionScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _ActionCard(
                              icon: Icons.build_circle_outlined,
                              title: 'Repair Jobs',
                              subtitle:
                                  'View and manage workshop repair jobs',
                              onTap: () async {
                                final inspections =
                                    await WorkshopRepository().getAllInspections();

                                if (!context.mounted) return;

                                if (inspections.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No workshop inspections are available.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                WorkshopInspection? selectedInspection;

                                if (inspections.length == 1) {
                                  selectedInspection = inspections.first;
                                } else {
                                  selectedInspection =
                                      await showDialog<WorkshopInspection>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return SimpleDialog(
                                        title: const Text('Select Inspection'),
                                        children: inspections.map((inspection) {
                                          return SimpleDialogOption(
                                            onPressed: () {
                                              Navigator.of(dialogContext)
                                                  .pop(inspection);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    inspection.registration,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${inspection.inspectionNumber} • '
                                                    '${inspection.inspectionType.name}',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  );
                                }

                                if (!context.mounted ||
                                    selectedInspection == null ||
                                    selectedInspection.id == null) {
                                  return;
                                }

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RepairJobsScreen(
                                      inspectionId: selectedInspection!.id!,
                                    ),
                                  ),
                                );

                                if (context.mounted) {
                                  _refreshDashboard();
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "Today's Overview",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 760 ? 2 : 1;
                      final spacing = 12.0;
                      final itemWidth = columns == 1
                          ? width
                          : (width - spacing) / 2;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Open Inspections',
                              value:
                                  dashboard.openInspections.toString(),
                              icon: Icons.assignment_outlined,
                              description:
                                  'Currently open in the workshop',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Completed Today',
                              value:
                                  dashboard.completedToday.toString(),
                              icon: Icons.check_circle_outline,
                              description:
                                  'Inspections completed today',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Critical Failures',
                              value:
                                  dashboard.criticalFailures.toString(),
                              icon:
                                  Icons.warning_amber_outlined,
                              description:
                                  hasCriticalIssues
                                      ? 'Requires attention'
                                      : 'No critical failures',
                              alert: hasCriticalIssues,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Repairs Required',
                              value:
                                  dashboard.repairsRequired.toString(),
                              icon: Icons.build_outlined,
                              description:
                                  hasRepairs
                                      ? 'Jobs require workshop action'
                                      : 'No outstanding repairs',
                              alert: hasRepairs,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Workshop Operations',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 760 ? 2 : 1;
                      final spacing = 12.0;
                      final itemWidth = columns == 1
                          ? width
                          : (width - spacing) / 2;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Repairs Outstanding',
                              value:
                                  dashboard.repairsOutstanding.toString(),
                              icon: Icons.build_circle_outlined,
                              description: hasOutstandingRepairs
                                  ? 'Repair jobs require action'
                                  : 'No outstanding repair jobs',
                              alert: hasOutstandingRepairs,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Awaiting Parts',
                              value: dashboard.awaitingParts.toString(),
                              icon: Icons.inventory_2_outlined,
                              description: hasAwaitingParts
                                  ? 'Jobs waiting for parts'
                                  : 'No jobs awaiting parts',
                              alert: hasAwaitingParts,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _KpiCard(
                              title: 'Awaiting Sign-off',
                              value:
                                  dashboard.awaitingSignOff.toString(),
                              icon: Icons.fact_check_outlined,
                              description: hasAwaitingSignOff
                                  ? 'Completed inspections need approval'
                                  : 'No inspections awaiting sign-off',
                              alert: hasAwaitingSignOff,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Workshop Status',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: scheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: hasCriticalIssues
                                  ? scheme.errorContainer
                                  : scheme.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Icon(
                              hasCriticalIssues
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              color: hasCriticalIssues
                                  ? scheme.onErrorContainer
                                  : scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasCriticalIssues
                                      ? 'Attention Required'
                                      : 'Workshop Operational',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hasCriticalIssues
                                      ? 'There are critical inspection failures requiring attention.'
                                      : hasRepairs
                                          ? 'The workshop is operational with repair work currently outstanding.'
                                          : 'No critical issues are currently reported.',
                                  style:
                                      theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Recent Activity',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: scheme.outlineVariant,
                      ),
                    ),
                    child: const ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      leading: Icon(
                        Icons.info_outline,
                      ),
                      title: Text(
                        'Workshop Ready',
                      ),
                      subtitle: Text(
                        'Live dashboard connected',
                      ),
                    ),
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

class _WorkshopAccessDenied extends StatelessWidget {
  const _WorkshopAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You do not have permission to access Workshop.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TechnicianWorkshopLanding extends StatelessWidget {
  const _TechnicianWorkshopLanding();

  @override
  Widget build(BuildContext context) {
    final technicianId = int.tryParse(
      AuthService.instance.currentUserId ?? '',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Workshop')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handyman_outlined, size: 64),
              SizedBox(height: 16),
              Text(
                'Technician Workshop',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(
                technicianId == null
                    ? 'Your technician account does not have a valid numeric ID. '
                        'Please contact an administrator.'
                    : 'View and update repair jobs assigned to you.',
                textAlign: TextAlign.center,
              ),
              if (technicianId != null) ...[
                SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RepairJobsScreen(
                          technicianId: technicianId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.assignment_turned_in_outlined),
                  label: Text('My Repair Jobs'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 90,
            ),
            child: Image.asset(
              'assets/images/arrow_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arrow Fleet Manager',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Workshop',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 18),
          Text(
            'Workshop Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Inspections, repairs and workshop activity',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String description;
  final bool alert;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.description,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: alert
              ? scheme.error.withValues(alpha: 0.45)
              : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: alert
                    ? scheme.errorContainer
                    : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: alert
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style:
                        theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
