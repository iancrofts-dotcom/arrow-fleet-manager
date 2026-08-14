import 'package:flutter/material.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_wizard_data.dart';
import '../../models/repair_job.dart';
import '../../services/repair_job_generator.dart';

class Step4Repairs extends StatefulWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step4Repairs({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step4Repairs> createState() => _Step4RepairsState();
}

class _Step4RepairsState extends State<Step4Repairs> {
  final RepairJobGenerator _generator =
      RepairJobGenerator();

  List<InspectionChecklistItem> get checklistItems =>
      widget.data.checklistItems;

  List<RepairJob> get repairJobs =>
      widget.data.repairJobs;

  @override
  void initState() {
    super.initState();

    _loadRepairJobs();
  }

  void _loadRepairJobs() {
    if (widget.data.repairJobs.isEmpty) {
      widget.data.repairJobs =
          _generator.generate(
        inspectionId: 0,
        vehicleId: widget.data.vehicleId ?? 0,
        vehicleRegistration:
            widget.data.registration ?? '',
        items: checklistItems,
        technicianId: widget.data.templateId == null
            ? widget.data.technicianId
            : null,
        technicianName: widget.data.templateId == null
            ? widget.data.technicianName ?? ''
            : '',
      );
    }
  }

  double get totalEstimatedHours {
    return repairJobs.fold(
      0,
      (sum, job) => sum + job.estimatedHours,
    );
  }

  double get totalEstimatedCost {
    return repairJobs.fold(
      0,
      (sum, job) => sum + job.estimatedCost,
    );
  }

  int get criticalCount {
    return repairJobs
        .where(
          (job) =>
              job.priority ==
              RepairPriority.critical,
        )
        .length;
  }

  int get highCount {
    return repairJobs
        .where(
          (job) =>
              job.priority ==
              RepairPriority.high,
        )
        .length;
  }

  int get partsRequiredCount {
    return repairJobs
        .where(
          (job) => job.partsRequired,
        )
        .length;
  }

  void _updateJob(
    int index,
    RepairJob job,
  ) {
    setState(() {
      widget.data.repairJobs[index] = job;
    });
  }

  void _setPriority(
    int index,
    RepairPriority priority,
  ) {
    _updateJob(
      index,
      repairJobs[index].copyWith(
        priority: priority,
      ),
    );
  }

  void _setStatus(
    int index,
    RepairJobStatus status,
  ) {
    _updateJob(
      index,
      repairJobs[index].copyWith(
        status: status,
      ),
    );
  }

  void _togglePartsRequired(int index) {
    final job = repairJobs[index];

    _updateJob(
      index,
      job.copyWith(
        partsRequired: !job.partsRequired,
      ),
    );
  }

  void _setEstimatedHours(int index, double hours) {
    _updateJob(
      index,
      repairJobs[index].copyWith(
        estimatedHours: hours,
      ),
    );
  }

  void _setEstimatedCost(int index, double cost) {
    _updateJob(
      index,
      repairJobs[index].copyWith(
        estimatedCost: cost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        // ===================================================================
        // HEADER
        // ===================================================================

        Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            18,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: scheme.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repair Review',
                      style: theme.textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      repairJobs.isEmpty
                          ? 'No repairs are required.'
                          : 'Review the work generated from the inspection.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (repairJobs.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${repairJobs.length} '
                    '${repairJobs.length == 1 ? 'repair' : 'repairs'}',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ===================================================================
        // CONTENT
        // ===================================================================

        Expanded(
          child: repairJobs.isEmpty
              ? _NoRepairs()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // =======================================================
                    // KPI SUMMARY
                    // =======================================================

                    _RepairSummaryCard(
                      repairCount:
                          repairJobs.length,
                      totalHours:
                          totalEstimatedHours,
                      totalCost:
                          totalEstimatedCost,
                      criticalCount:
                          criticalCount,
                      highCount:
                          highCount,
                      partsRequiredCount:
                          partsRequiredCount,
                    ),

                    const SizedBox(height: 20),

                    // =======================================================
                    // REPAIR JOBS
                    // =======================================================

                    Text(
                      'Repair Jobs',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    for (
                      int index = 0;
                      index < repairJobs.length;
                      index++
                    ) ...[
                      _RepairJobCard(
                        job: repairJobs[index],
                        onPriorityChanged:
                            (priority) {
                          _setPriority(
                            index,
                            priority,
                          );
                        },
                        onStatusChanged:
                            (status) {
                          _setStatus(
                            index,
                            status,
                          );
                        },
                        onPartsChanged: () {
                          _togglePartsRequired(
                            index,
                          );
                        },
                        onHoursChanged: (hours) {
                          _setEstimatedHours(
                            index,
                            hours,
                          );
                        },
                        onCostChanged: (cost) {
                          _setEstimatedCost(
                            index,
                            cost,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),

        // ===================================================================
        // FOOTER
        // ===================================================================

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant,
              ),
            ),
          ),
          child: Wrap(
            alignment:
                WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed:
                    widget.onPrevious,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text('Back'),
              ),

              FilledButton.icon(
                onPressed: widget.onNext,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                ),
                label: const Text(
                  'Continue to Sign-off',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// REPAIR SUMMARY
// =============================================================================

class _RepairSummaryCard extends StatelessWidget {
  final int repairCount;
  final double totalHours;
  final double totalCost;
  final int criticalCount;
  final int highCount;
  final int partsRequiredCount;

  const _RepairSummaryCard({
    required this.repairCount,
    required this.totalHours,
    required this.totalCost,
    required this.criticalCount,
    required this.highCount,
    required this.partsRequiredCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Repair Overview',
                style: theme.textTheme.titleLarge
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Kpi(
                icon: Icons.build_outlined,
                label: 'Repairs',
                value:
                    '$repairCount',
              ),
              _Kpi(
                icon: Icons.schedule_outlined,
                label: 'Labour',
                value:
                    '${totalHours.toStringAsFixed(1)} hrs',
              ),
              _Kpi(
                icon: Icons.payments_outlined,
                label: 'Estimated',
                value:
                    '£${totalCost.toStringAsFixed(2)}',
              ),
              _Kpi(
                icon: Icons.priority_high,
                label: 'Critical',
                value:
                    '$criticalCount',
              ),
              _Kpi(
                icon: Icons.warning_amber_outlined,
                label: 'High',
                value:
                    '$highCount',
              ),
              _Kpi(
                icon: Icons.inventory_2_outlined,
                label: 'Parts',
                value:
                    '$partsRequiredCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// KPI
// =============================================================================

class _Kpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
            scheme.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 19,
            color: scheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REPAIR JOB CARD
// =============================================================================

class _RepairJobCard extends StatefulWidget {
  final RepairJob job;
  final ValueChanged<RepairPriority> onPriorityChanged;
  final ValueChanged<RepairJobStatus> onStatusChanged;
  final VoidCallback onPartsChanged;
  final ValueChanged<double> onHoursChanged;
  final ValueChanged<double> onCostChanged;

  const _RepairJobCard({
    required this.job,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onPartsChanged,
    required this.onHoursChanged,
    required this.onCostChanged,
  });

  @override
  State<_RepairJobCard> createState() => _RepairJobCardState();
}

class _RepairJobCardState extends State<_RepairJobCard> {
  late final TextEditingController _hoursController;
  late final TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
      text: widget.job.estimatedHours.toStringAsFixed(1),
    );
    _costController = TextEditingController(
      text: widget.job.estimatedCost.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _hoursChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0) {
      widget.onHoursChanged(parsed);
    }
  }

  void _costChanged(String value) {
    final parsed = double.tryParse(value.replaceAll('£', '').trim());
    if (parsed != null && parsed >= 0) {
      widget.onCostChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final priorityIcon =
        _priorityIcon(widget.job.priority);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: widget.job.priority ==
                  RepairPriority.critical
              ? scheme.error
                  .withValues(alpha: 0.45)
              : scheme.outlineVariant,
          width:
              widget.job.priority ==
                      RepairPriority.critical
                  ? 1.5
                  : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // -----------------------------------------------------------------
          // TITLE
          // -----------------------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      scheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  priorityIcon,
                  color: scheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.title,
                      style: theme.textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.job.jobNumber,
                      style: theme.textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                            scheme.onSurfaceVariant,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------------------
          // DESCRIPTION
          // -----------------------------------------------------------------

          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  scheme.surfaceContainerLow,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Text(
              widget.job.description,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------------------
          // ESTIMATES
          // -----------------------------------------------------------------

          LayoutBuilder(
            builder: (context, constraints) {
              final hoursField = TextField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Labour hours',
                  hintText: '0.0',
                  suffixText: 'hrs',
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _hoursChanged,
              );

              final costField = TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Estimated cost',
                  hintText: '0.00',
                  prefixText: '£ ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _costChanged,
              );

              if (constraints.maxWidth >= 620) {
                return Row(
                  children: [
                    Expanded(child: hoursField),
                    const SizedBox(width: 12),
                    Expanded(child: costField),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hoursField,
                  const SizedBox(height: 12),
                  costField,
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // PRIORITY
          // -----------------------------------------------------------------

          Text(
            'Priority',
            style: theme.textTheme.labelLarge
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final priority
                  in RepairPriority.values)
                _ChoiceButton(
                  label:
                      _priorityLabel(priority),
                  selected:
                      widget.job.priority ==
                          priority,
                  onPressed: () {
                    widget.onPriorityChanged(
                      priority,
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------------------
          // STATUS
          // -----------------------------------------------------------------

          Text(
            'Status',
            style: theme.textTheme.labelLarge
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChoiceButton(
                label: 'OPEN',
                selected:
                    widget.job.status ==
                        RepairJobStatus.open,
                onPressed: () {
                  widget.onStatusChanged(
                    RepairJobStatus.open,
                  );
                },
              ),
              _ChoiceButton(
                label: 'ASSIGNED',
                selected:
                    widget.job.status ==
                        RepairJobStatus.assigned,
                onPressed: () {
                  widget.onStatusChanged(
                    RepairJobStatus.assigned,
                  );
                },
              ),
              _ChoiceButton(
                label: 'IN PROGRESS',
                selected:
                    widget.job.status ==
                        RepairJobStatus.inProgress,
                onPressed: () {
                  widget.onStatusChanged(
                    RepairJobStatus.inProgress,
                  );
                },
              ),
              _ChoiceButton(
                label: 'AWAITING PARTS',
                selected:
                    widget.job.status ==
                        RepairJobStatus.awaitingParts,
                onPressed: () {
                  widget.onStatusChanged(
                    RepairJobStatus.awaitingParts,
                  );
                },
              ),
              _ChoiceButton(
                label: 'COMPLETED',
                selected:
                    widget.job.status ==
                        RepairJobStatus.completed,
                onPressed: () {
                  widget.onStatusChanged(
                    RepairJobStatus.completed,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------------------
          // PARTS
          // -----------------------------------------------------------------

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Parts required',
            ),
            subtitle: Text(
              widget.job.partsRequired
                  ? 'Parts will need to be sourced.'
                  : 'No parts currently recorded.',
            ),
            value: widget.job.partsRequired,
            onChanged: (_) {
              widget.onPartsChanged();
            },
          ),
        ],
      ),
    );
  }

  IconData _priorityIcon(
    RepairPriority priority,
  ) {
    switch (priority) {
      case RepairPriority.low:
        return Icons.arrow_downward;

      case RepairPriority.medium:
        return Icons.remove;

      case RepairPriority.high:
        return Icons.arrow_upward;

      case RepairPriority.critical:
        return Icons.priority_high;
    }
  }

  String _priorityLabel(
    RepairPriority priority,
  ) {
    switch (priority) {
      case RepairPriority.low:
        return 'LOW';

      case RepairPriority.medium:
        return 'MEDIUM';

      case RepairPriority.high:
        return 'HIGH';

      case RepairPriority.critical:
        return 'CRITICAL';
    }
  }
}

// =============================================================================
// CHOICE BUTTON
// =============================================================================

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(
            onPressed: onPressed,
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Text(label),
          );
  }
}

// =============================================================================
// NO REPAIRS
// =============================================================================

class _NoRepairs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 600,
          ),
          padding:
              const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color:
                scheme.primaryContainer,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_outlined,
                size: 64,
                color: scheme.primary,
              ),

              const SizedBox(height: 18),

              Text(
                'No Repairs Required',
                style: theme.textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                  color:
                      scheme.onPrimaryContainer,
                ),
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'The inspection has not generated any repair jobs.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(
                  color:
                      scheme.onPrimaryContainer,
                ),
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
