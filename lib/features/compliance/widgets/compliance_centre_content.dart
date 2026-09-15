import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/constants.dart';
import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/fleet_compliance_summary.dart';

class ComplianceCentreContent extends StatelessWidget {
  const ComplianceCentreContent({
    super.key,
    required this.summary,
    this.onAttentionTap,
  });

  final FleetComplianceSummary summary;
  final ValueChanged<FleetComplianceAttentionItem>? onAttentionTap;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('compliance-centre-scroll'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 32),
    children: [
      _OverviewCard(summary: summary),
      const SizedBox(height: 20),
      _StatusMetrics(summary: summary),
      const SizedBox(height: 24),
      _AttentionSection(
        items: summary.attentionItems,
        onAttentionTap: onAttentionTap,
      ),
      const SizedBox(height: 24),
      _ComplianceRegisterSection(
        items: summary.allItems,
        onItemTap: onAttentionTap,
      ),
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

class _AttentionSection extends StatefulWidget {
  const _AttentionSection({required this.items, this.onAttentionTap});

  final List<FleetComplianceAttentionItem> items;
  final ValueChanged<FleetComplianceAttentionItem>? onAttentionTap;

  @override
  State<_AttentionSection> createState() => _AttentionSectionState();
}

class _AttentionSectionState extends State<_AttentionSection> {
  final _searchController = TextEditingController();
  FleetComplianceStatus? _status;
  FleetComplianceSubjectType? _subjectType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty ||
      _status != null ||
      _subjectType != null;

  List<FleetComplianceAttentionItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return widget.items
        .where((item) {
          final matchesStatus = _status == null || item.status == _status;
          final matchesSubject =
              _subjectType == null || item.subjectType == _subjectType;
          final matchesSearch =
              query.isEmpty ||
              [
                item.subjectDisplay,
                item.secondaryDisplay,
                _checkLabel(item.checkType),
              ].whereType<String>().any(
                (value) => value.toLowerCase().contains(query),
              );
          return matchesStatus && matchesSubject && matchesSearch;
        })
        .toList(growable: false);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _status = null;
      _subjectType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Needs Attention',
      subtitle: 'Required checks that need operational follow-up.',
      child: widget.items.isEmpty
          ? const _AttentionEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('compliance-attention-search'),
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search needs attention',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                _FilterGroup<FleetComplianceStatus>(
                  label: 'Status',
                  selected: _status,
                  options: const [
                    (null, 'All'),
                    (FleetComplianceStatus.dueSoon, 'Due Soon'),
                    (FleetComplianceStatus.expired, 'Expired'),
                    (FleetComplianceStatus.notRecorded, 'Not Recorded'),
                  ],
                  onSelected: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 12),
                _FilterGroup<FleetComplianceSubjectType>(
                  label: 'Subject',
                  selected: _subjectType,
                  options: const [
                    (null, 'All subjects'),
                    (FleetComplianceSubjectType.vehicle, 'Vehicles'),
                    (FleetComplianceSubjectType.driver, 'Drivers'),
                  ],
                  onSelected: (value) => setState(() => _subjectType = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing ${items.length} of ${widget.items.length} attention items',
                        key: const Key('compliance-attention-result-count'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (_hasFilters)
                      TextButton(
                        key: const Key('compliance-attention-clear-filters'),
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
                const Divider(height: 24),
                if (items.isEmpty)
                  _FilteredAttentionEmptyState(onClearFilters: _clearFilters)
                else
                  for (final item in items) ...[
                    _AttentionRow(
                      key: Key(
                        'compliance-attention-${item.subjectType.name}-${item.subjectId}-${item.checkType.name}',
                      ),
                      item: item,
                      onTap: widget.onAttentionTap,
                    ),
                    if (item != items.last) const Divider(height: 24),
                  ],
              ],
            ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  const _FilterGroup({
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final T? selected;
  final List<(T?, String)> options;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            ChoiceChip(
              label: Text(option.$2),
              selected: selected == option.$1,
              onSelected: (_) => onSelected(option.$1),
            ),
        ],
      ),
    ],
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

class _FilteredAttentionEmptyState extends StatelessWidget {
  const _FilteredAttentionEmptyState({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        const Icon(Icons.search_off_outlined),
        const SizedBox(height: 8),
        Text(
          'No attention items match the current filters.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClearFilters,
          child: const Text('Clear filters'),
        ),
      ],
    ),
  );
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({super.key, required this.item, this.onTap});

  final FleetComplianceAttentionItem item;
  final ValueChanged<FleetComplianceAttentionItem>? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: 'View ${item.subjectDisplay} compliance',
    child: InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ComplianceRegisterSection extends StatefulWidget {
  const _ComplianceRegisterSection({required this.items, this.onItemTap});

  final List<FleetComplianceAttentionItem> items;
  final ValueChanged<FleetComplianceAttentionItem>? onItemTap;

  @override
  State<_ComplianceRegisterSection> createState() =>
      _ComplianceRegisterSectionState();
}

class _ComplianceRegisterSectionState
    extends State<_ComplianceRegisterSection> {
  final _searchController = TextEditingController();
  FleetComplianceStatus? _status;
  FleetComplianceSubjectType? _subjectType;
  FleetComplianceCheckType? _checkType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FleetComplianceAttentionItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return widget.items
        .where((item) {
          if (_status != null && item.status != _status) {
            return false;
          }
          if (_subjectType != null && item.subjectType != _subjectType) {
            return false;
          }
          if (_checkType != null && item.checkType != _checkType) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return [
            item.subjectDisplay,
            item.secondaryDisplay,
            _checkLabel(item.checkType),
            _dateLabel(item.date),
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }

  void _clear() {
    setState(() {
      _searchController.clear();
      _status = null;
      _subjectType = null;
      _checkType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final hasFilters =
        _searchController.text.trim().isNotEmpty ||
        _status != null ||
        _subjectType != null ||
        _checkType != null;
    return SectionCard(
      title: 'All Compliance Records',
      subtitle:
          'Complete Driver and Vehicle register, including valid, due, expired and missing records.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('compliance-register-search'),
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search compliance register',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          _FilterGroup<FleetComplianceStatus>(
            label: 'Status',
            selected: _status,
            options: const [
              (null, 'All'),
              (FleetComplianceStatus.valid, 'Valid'),
              (FleetComplianceStatus.dueSoon, 'Due Soon'),
              (FleetComplianceStatus.expired, 'Expired'),
              (FleetComplianceStatus.notRecorded, 'Not Recorded'),
            ],
            onSelected: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 12),
          _FilterGroup<FleetComplianceSubjectType>(
            label: 'Subject',
            selected: _subjectType,
            options: const [
              (null, 'All subjects'),
              (FleetComplianceSubjectType.vehicle, 'Vehicles'),
              (FleetComplianceSubjectType.driver, 'Drivers'),
            ],
            onSelected: (value) => setState(() => _subjectType = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _checkType?.name ?? 'all',
            decoration: const InputDecoration(
              labelText: 'Compliance type',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: 'all',
                child: Text('All compliance types'),
              ),
              for (final type in FleetComplianceCheckType.values)
                DropdownMenuItem<String>(
                  value: type.name,
                  child: Text(_checkLabel(type)),
                ),
            ],
            onChanged: (value) => setState(() {
              _checkType = value == null || value == 'all'
                  ? null
                  : FleetComplianceCheckType.values.firstWhere(
                      (type) => type.name == value,
                    );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing ${items.length} of ${widget.items.length} records',
                  key: const Key('compliance-register-result-count'),
                ),
              ),
              if (hasFilters)
                TextButton(
                  onPressed: _clear,
                  child: const Text('Clear filters'),
                ),
            ],
          ),
          const Divider(height: 24),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No compliance records match the current filters.'),
            )
          else
            for (final item in items) ...[
              _AttentionRow(
                key: Key(
                  'compliance-register-${item.subjectType.name}-${item.subjectId}-${item.checkType.name}',
                ),
                item: item,
                onTap: widget.onItemTap,
              ),
              if (item != items.last) const Divider(height: 24),
            ],
        ],
      ),
    );
  }
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
  FleetComplianceCheckType.psvMot => 'PSV MOT',
  FleetComplianceCheckType.service => 'Service',
  FleetComplianceCheckType.psvGarageCheck => 'PSV Garage Check',
  FleetComplianceCheckType.taxiSafetyCheck => 'Taxi Safety Check',
  FleetComplianceCheckType.licence => 'Driving Licence',
  FleetComplianceCheckType.cpc => 'CPC',
  FleetComplianceCheckType.medical => 'Medical',
  FleetComplianceCheckType.dbs => 'DBS',
  FleetComplianceCheckType.taxiLicence => 'Taxi / Private Hire Licence',
  FleetComplianceCheckType.taxiPlate => 'Vehicle Licence (Taxi)',
};

String _dateLabel(DateTime? date) =>
    date == null ? 'No date recorded' : DateFormat('d MMM y').format(date);
