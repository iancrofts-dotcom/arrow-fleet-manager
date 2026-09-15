import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../../auth/services/permission_service.dart';
import '../models/dashboard_activity.dart';
import '../models/dashboard_alert.dart';
import '../models/dashboard_context.dart';
import '../models/dashboard_summary.dart';
import '../models/fleet_health.dart';

/// High-information FleetIQ dashboard that uses the existing dashboard load only.
///
/// No secondary repository calls are made here. This keeps the dashboard fast,
/// avoids duplicated data loading and means Web/Windows/Android all render the
/// same central/local dashboard summary supplied by DashboardScreen.
class ExecutiveDashboardContent extends StatelessWidget {
  const ExecutiveDashboardContent({
    super.key,
    required this.dashboardContext,
    this.children = const [],
  });

  final DashboardContext dashboardContext;
  final List<Widget> children;

  DashboardSummary get summary => dashboardContext.summary;
  FleetHealth get fleetHealth => dashboardContext.fleetHealth;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: dashboardContext.onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;
          final tablet = constraints.maxWidth < 1080;
          final horizontalPadding = mobile ? 14.0 : 24.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    mobile ? 12 : 20,
                    horizontalPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KpiGrid(summary: summary),
                      SizedBox(height: mobile ? 14 : 18),
                      if (tablet)
                        Column(
                          children: [
                            _FleetHealthPanel(fleetHealth: fleetHealth),
                            const SizedBox(height: 14),
                            _AssignmentPanel(summary: summary),
                            const SizedBox(height: 14),
                            _PriorityPanel(summary: summary),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _FleetHealthPanel(
                                fleetHealth: fleetHealth,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: _AssignmentPanel(summary: summary),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 4,
                              child: _PriorityPanel(summary: summary),
                            ),
                          ],
                        ),
                      if (summary.workshopDashboard != null) ...[
                        SizedBox(height: mobile ? 14 : 18),
                        _WorkshopPanel(summary: summary),
                      ],
                      SizedBox(height: mobile ? 14 : 18),
                      if (mobile)
                        Column(
                          children: [
                            _RecentActivityPanel(summary: summary),
                            const SizedBox(height: 14),
                            _OperationalDetailPanel(summary: summary),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _RecentActivityPanel(summary: summary),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: _OperationalDetailPanel(summary: summary),
                            ),
                          ],
                        ),
                      if (children.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        ...children,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;
    final overdue = summary.maintenanceOverdue + summary.complianceExpired;
    final defects = summary.workshopDashboard?.defectTotal;
    final tiles = <_KpiData>[
      _KpiData(
        title: 'Vehicles',
        value: '${summary.vehicleCount}',
        subtitle: '${summary.activeVehicles} active',
        icon: Icons.local_shipping_outlined,
        tone: _KpiTone.primary,
        onTap: permissions.canViewVehicles
            ? () => Navigator.of(context).pushNamed(AppRouter.vehicles)
            : null,
      ),
      _KpiData(
        title: 'Drivers',
        value: '${summary.driverCount}',
        subtitle: '${summary.activeDrivers} active',
        icon: Icons.people_alt_outlined,
        tone: _KpiTone.success,
        onTap: permissions.canViewDrivers
            ? () => Navigator.of(context).pushNamed(AppRouter.drivers)
            : null,
      ),
      _KpiData(
        title: 'MOT Due',
        value: '${summary.vehicleMotDue}',
        subtitle: 'Within 30 days',
        icon: Icons.fact_check_outlined,
        tone: _KpiTone.warning,
        onTap: permissions.canViewCompliance
            ? () => DashboardNavigation.openCompliance(context)
            : null,
      ),
      _KpiData(
        title: 'Service Due',
        value: '${summary.maintenanceDue}',
        subtitle: 'Within 30 days',
        icon: Icons.build_outlined,
        tone: _KpiTone.warning,
        onTap: permissions.canAccessWorkshop
            ? () => DashboardNavigation.openWorkshop(context)
            : null,
      ),
      _KpiData(
        title: 'Overdue',
        value: '$overdue',
        subtitle: overdue == 0 ? 'No action required' : 'Action required',
        icon: Icons.warning_amber_rounded,
        tone: overdue == 0 ? _KpiTone.success : _KpiTone.danger,
        onTap: permissions.canViewCompliance
            ? () => DashboardNavigation.openCompliance(context)
            : null,
      ),
      _KpiData(
        title: 'Open Defects',
        value: defects == null ? '—' : '$defects',
        subtitle: defects == null ? 'Workshop restricted' : 'Workshop defects',
        icon: Icons.assignment_late_outlined,
        tone: defects == null || defects == 0
            ? _KpiTone.neutral
            : _KpiTone.danger,
        onTap: permissions.canAccessWorkshop
            ? () => DashboardNavigation.openWorkshop(context)
            : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 6
            : constraints.maxWidth >= 760
            ? 3
            : 2;
        final spacing = constraints.maxWidth < 700 ? 10.0 : 14.0;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          key: const Key('dashboard-primary-kpi-grid'),
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: _KpiTile(data: tile),
              ),
          ],
        );
      },
    );
  }
}

enum _KpiTone { primary, success, warning, danger, neutral }

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final _KpiTone tone;
  final VoidCallback? onTap;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.data});

  final _KpiData data;

  Color _accent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (data.tone) {
      _KpiTone.primary => scheme.primary,
      _KpiTone.success => Colors.green.shade700,
      _KpiTone.warning => Colors.orange.shade800,
      _KpiTone.danger => scheme.error,
      _KpiTone.neutral => scheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  if (data.onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetHealthPanel extends StatelessWidget {
  const _FleetHealthPanel({required this.fleetHealth});

  final FleetHealth fleetHealth;

  @override
  Widget build(BuildContext context) {
    final total =
        fleetHealth.healthyVehicles +
        fleetHealth.warningVehicles +
        fleetHealth.criticalVehicles;

    return _Panel(
      title: 'Fleet Health',
      subtitle: 'Current vehicle health distribution',
      icon: Icons.donut_large_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final chart = SizedBox(
            width: compact ? 130 : 150,
            height: compact ? 130 : 150,
            child: CustomPaint(
              painter: _DonutPainter(
                values: [
                  fleetHealth.healthyVehicles.toDouble(),
                  fleetHealth.warningVehicles.toDouble(),
                  fleetHealth.criticalVehicles.toDouble(),
                ],
                colors: [
                  Colors.green.shade600,
                  Colors.orange.shade600,
                  Theme.of(context).colorScheme.error,
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fleetHealth.formattedScore,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      fleetHealth.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
          final legend = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(
                color: Colors.green.shade600,
                label: 'Healthy',
                value: '${fleetHealth.healthyVehicles}',
              ),
              const SizedBox(height: 12),
              _LegendRow(
                color: Colors.orange.shade600,
                label: 'Needs attention',
                value: '${fleetHealth.warningVehicles}',
              ),
              const SizedBox(height: 12),
              _LegendRow(
                color: Theme.of(context).colorScheme.error,
                label: 'Critical',
                value: '${fleetHealth.criticalVehicles}',
              ),
              const SizedBox(height: 12),
              Text(
                total == 0
                    ? 'No active vehicle health data.'
                    : '$total vehicles assessed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          return compact
              ? Column(children: [chart, const SizedBox(height: 14), legend])
              : Row(
                  children: [
                    chart,
                    const SizedBox(width: 24),
                    Expanded(child: legend),
                  ],
                );
        },
      ),
    );
  }
}

class _AssignmentPanel extends StatelessWidget {
  const _AssignmentPanel({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Fleet Allocation',
      subtitle: 'Current vehicle and driver assignment coverage',
      icon: Icons.route_outlined,
      child: Column(
        children: [
          _ProgressMetric(
            label: 'Vehicles assigned',
            value: summary.assignedVehicles,
            total: summary.activeVehicles,
            trailing: '${summary.unassignedVehicles} unassigned',
          ),
          const SizedBox(height: 22),
          _ProgressMetric(
            label: 'Drivers assigned',
            value: summary.assignedDrivers,
            total: summary.activeDrivers,
            trailing: '${summary.unassignedDrivers} unassigned',
          ),
          const SizedBox(height: 22),
          _ProgressMetric(
            label: 'Fleet compliance',
            value: summary.compliancePercentage,
            total: 100,
            trailing: '${summary.compliancePercentage}%',
          ),
        ],
      ),
    );
  }
}

class _PriorityPanel extends StatelessWidget {
  const _PriorityPanel({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final alerts = summary.alerts.take(5).toList(growable: false);
    return _Panel(
      title: 'Upcoming & Attention',
      subtitle: 'Highest priority fleet items',
      icon: Icons.notifications_active_outlined,
      child: alerts.isEmpty
          ? const _GoodState(
              icon: Icons.check_circle_outline,
              title: 'Nothing needs attention',
              message: 'No current priority alerts were found.',
            )
          : Column(
              children: [
                for (var index = 0; index < alerts.length; index++) ...[
                  _AlertRow(alert: alerts[index]),
                  if (index != alerts.length - 1) const Divider(height: 22),
                ],
              ],
            ),
    );
  }
}

class _WorkshopPanel extends StatelessWidget {
  const _WorkshopPanel({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final data = summary.workshopDashboard!;
    return _Panel(
      title: 'Workshop Operations',
      subtitle: 'Live maintenance and inspection workload',
      icon: Icons.handyman_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 6
              : constraints.maxWidth >= 560
              ? 3
              : 2;
          final spacing = 12.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          final metrics = [
            (
              'Open inspections',
              data.openInspections,
              Icons.fact_check_outlined,
            ),
            ('Completed today', data.completedToday, Icons.task_alt_outlined),
            (
              'Repairs outstanding',
              data.repairsOutstanding,
              Icons.build_circle_outlined,
            ),
            ('Awaiting parts', data.awaitingParts, Icons.inventory_2_outlined),
            (
              'Awaiting sign-off',
              data.awaitingSignOff,
              Icons.approval_outlined,
            ),
            (
              'Critical failures',
              data.criticalFailures,
              Icons.report_problem_outlined,
            ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _CompactMetric(
                        label: metric.$1,
                        value: metric.$2,
                        icon: metric.$3,
                      ),
                    ),
                ],
              ),
              if (PermissionService.instance.canAccessWorkshop) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('dashboard-open-workshop'),
                    onPressed: () => DashboardNavigation.openWorkshop(context),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Open Workshop'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final activity = summary.recentActivity.take(6).toList(growable: false);
    return _Panel(
      title: 'Recent Activity',
      subtitle: 'Latest recorded fleet events',
      icon: Icons.history_outlined,
      child: activity.isEmpty
          ? const _GoodState(
              icon: Icons.history_toggle_off_outlined,
              title: 'No recent activity to show',
              message: 'New fleet activity will appear here as it is recorded.',
            )
          : Column(
              children: [
                for (var index = 0; index < activity.length; index++) ...[
                  _ActivityRow(activity: activity[index]),
                  if (index != activity.length - 1) const Divider(height: 22),
                ],
              ],
            ),
    );
  }
}

class _OperationalDetailPanel extends StatelessWidget {
  const _OperationalDetailPanel({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Active vehicles', summary.activeVehicles, summary.vehicleCount),
      ('Active drivers', summary.activeDrivers, summary.driverCount),
      (
        'Maintenance records',
        summary.maintenanceRecordCount,
        summary.vehicleCount,
      ),
      ('Compliance due', summary.complianceDue, summary.vehicleCount),
    ];
    return _Panel(
      title: 'Operational Snapshot',
      subtitle: 'Useful current-state ratios without duplicate cards',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _RatioRow(
              label: rows[index].$1,
              value: rows[index].$2,
              total: rows[index].$3,
            ),
            if (index != rows.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.total,
    required this.trailing,
  });

  final String label;
  final int value;
  final int total;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Text(
              trailing,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 9),
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      DashboardAlertSeverity.critical => Theme.of(context).colorScheme.error,
      DashboardAlertSeverity.warning => Colors.orange.shade800,
      DashboardAlertSeverity.info => Theme.of(context).colorScheme.primary,
    };
    final canOpen = DashboardNavigation.canOpenRoute(alert.route);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: canOpen
          ? () => DashboardNavigation.openRoute(context, alert.route)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert.icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final DashboardActivity activity;

  IconData get icon => switch (activity.type) {
    DashboardActivityType.vehicle => Icons.local_shipping_outlined,
    DashboardActivityType.driver => Icons.person_outline,
    DashboardActivityType.assignment => Icons.route_outlined,
    DashboardActivityType.maintenance => Icons.build_outlined,
    DashboardActivityType.compliance => Icons.verified_user_outlined,
    DashboardActivityType.dailyCheck => Icons.fact_check_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final canOpen = DashboardNavigation.canOpenRoute(activity.route);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: canOpen
          ? () => DashboardNavigation.openRoute(context, activity.route)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            activity.relativeDate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RatioRow extends StatelessWidget {
  const _RatioRow({
    required this.label,
    required this.value,
    required this.total,
  });

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Text(
              '$value / $total  •  $percent%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: ratio, minHeight: 8),
        ),
      ],
    );
  }
}

class _GoodState extends StatelessWidget {
  const _GoodState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;
    final stroke = math.min(size.width, size.height) * 0.15;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = Colors.grey.withValues(alpha: 0.18);
    canvas.drawArc(
      rect.deflate(stroke / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      background,
    );
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      if (values[index] <= 0) continue;
      final sweep = math.pi * 2 * (values[index] / total);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[index];
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}
