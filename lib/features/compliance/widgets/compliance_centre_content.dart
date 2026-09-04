import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/constants.dart';
import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/fleet_compliance_summary.dart';

class ComplianceCentreContent extends StatelessWidget {
  const ComplianceCentreContent({super.key, required this.summary});

  final FleetComplianceSummary summary;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 32),
    children: [
      _OverviewCard(summary: summary),
      const SizedBox(height: 20),
      _StatusMetrics(summary: summary),
      const SizedBox(height: 24),
      _AttentionSection(items: summary.attentionItems),
      const SizedBox(height: 24),
      _BreakdownSection(summary: summary),
    ],
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.summary});

  final FleetComplianceSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final double progress = summary.totalChecks == 0
        ? 0.0
        : (summary.compliancePercentage / 100).clamp(0.0, 1.0).toDouble();

    return SectionCard(
      variant: SectionCardVariant.dashboardPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fleet Compliance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.compliancePercentage}%',
            key: const Key('fleet-compliance-percentage'),
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Percentage of required checks currently compliant'),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('fleet-compliance-progress'),
              value: progress,
              minHeight: 6,
              color: scheme.primary,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.compliantChecks} of ${summary.totalChecks} required checks compliant',
            key: const Key('fleet-compliance-context'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusMetrics extends StatelessWidget {
  const _StatusMetrics({required this.summary});

  final FleetComplianceSummary summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 960 ? 4 : 2;
      const gap = 12.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          _StatusMetricCard(
            width: width,
            label: 'Valid',
            value: summary.validCount,
            icon: Icons.check_circle_outline,
            tone: StatusBadgeTone.success,
          ),
          _StatusMetricCard(
            width: width,
            label: 'Due Soon',
            value: summary.dueSoonCount,
            icon: Icons.schedule_outlined,
            tone: StatusBadgeTone.warning,
          ),
          _StatusMetricCard(
            width: width,
            label: 'Expired',
            value: summary.expiredCount,
            icon: Icons.error_outline,
            tone: StatusBadgeTone.critical,
          ),
          _StatusMetricCard(
            width: width,
            label: 'Not Recorded',
            value: summary.notRecordedCount,
            icon: Icons.assignment_late_outlined,
            tone: StatusBadgeTone.neutral,
          ),
        ],
      );
    },
  );
}

class _StatusMetricCard extends StatelessWidget {
  const _StatusMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final double width;
  final String label;
  final int value;
  final IconData icon;
  final StatusBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    return SizedBox(
      width: width,
      child: SectionCard(
        variant: SectionCardVariant.kpi,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 14),
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  key: Key('compliance-status-$label'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({required this.items});

  final List<FleetComplianceAttentionItem> items;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Needs Attention',
    subtitle: 'Required checks that need operational follow-up.',
    child: items.isEmpty
        ? const _AttentionEmptyState()
        : Column(
            children: [
              for (final item in items) ...[
                _AttentionRow(item: item),
                if (item != items.last) const Divider(height: 24),
              ],
            ],
          ),
  );
}

class _AttentionEmptyState extends StatelessWidget {
  const _AttentionEmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Icon(Icons.verified_outlined),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'All required compliance checks are currently up to date.',
          ),
        ),
      ],
    ),
  );
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final FleetComplianceAttentionItem item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _toneColor(
            _toneForStatus(item.status),
          ).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.subjectType == FleetComplianceSubjectType.vehicle
              ? Icons.local_shipping_outlined
              : Icons.person_outline,
          color: _toneColor(_toneForStatus(item.status)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.subjectDisplay,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${_checkLabel(item.checkType)} • ${_dateLabel(item.date)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _badgeForStatus(item.status),
    ],
  );
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.summary});

  final FleetComplianceSummary summary;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Fleet Compliance Breakdown',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 600;
        final vehicle = _BreakdownItem(
          label: 'Vehicle Checks',
          count: summary.vehicleCheckCount,
        );
        final driver = _BreakdownItem(
          label: 'Driver Checks',
          count: summary.driverCheckCount,
        );
        return stacked
            ? Column(children: [vehicle, const Divider(height: 24), driver])
            : Row(
                children: [
                  Expanded(child: vehicle),
                  const VerticalDivider(),
                  Expanded(child: driver),
                ],
              );
      },
    ),
  );
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 2),
      Text('$count required checks', key: Key('compliance-breakdown-$label')),
    ],
  );
}

StatusBadge _badgeForStatus(FleetComplianceStatus status) => switch (status) {
  FleetComplianceStatus.valid => StatusBadge.success('Valid'),
  FleetComplianceStatus.dueSoon => StatusBadge.warning('Due Soon'),
  FleetComplianceStatus.expired => StatusBadge.critical('Expired'),
  FleetComplianceStatus.notRecorded => StatusBadge.neutral('Not Recorded'),
};

StatusBadgeTone _toneForStatus(FleetComplianceStatus status) =>
    switch (status) {
      FleetComplianceStatus.valid => StatusBadgeTone.success,
      FleetComplianceStatus.dueSoon => StatusBadgeTone.warning,
      FleetComplianceStatus.expired => StatusBadgeTone.critical,
      FleetComplianceStatus.notRecorded => StatusBadgeTone.neutral,
    };

Color _toneColor(StatusBadgeTone tone) => switch (tone) {
  StatusBadgeTone.success => AppConstants.successColor,
  StatusBadgeTone.warning => AppConstants.warningColor,
  StatusBadgeTone.critical || StatusBadgeTone.error => AppConstants.dangerColor,
  StatusBadgeTone.info => AppConstants.infoColor,
  StatusBadgeTone.neutral => AppConstants.neutralColor,
};

String _checkLabel(FleetComplianceCheckType type) => switch (type) {
  FleetComplianceCheckType.mot => 'MOT',
  FleetComplianceCheckType.service => 'Service',
  FleetComplianceCheckType.licence => 'Licence',
  FleetComplianceCheckType.cpc => 'CPC',
  FleetComplianceCheckType.medical => 'Medical',
  FleetComplianceCheckType.dbs => 'DBS',
};

String _dateLabel(DateTime? date) =>
    date == null ? 'No date recorded' : DateFormat('d MMM y').format(date);
