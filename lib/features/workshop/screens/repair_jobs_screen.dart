import 'package:flutter/material.dart';

import '../models/repair_job.dart';
import '../repositories/workshop_repository.dart';

class RepairJobsScreen extends StatefulWidget {
  final int inspectionId;

  const RepairJobsScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  State<RepairJobsScreen> createState() =>
      _RepairJobsScreenState();
}

class _RepairJobsScreenState
    extends State<RepairJobsScreen> {
  final WorkshopRepository _repository =
      WorkshopRepository();

  late Future<List<RepairJob>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadJobs();
  }

  Future<List<RepairJob>> _loadJobs() {
    return _repository.getRepairJobs(
      widget.inspectionId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadJobs();
    });

    await _future;
  }

  String _statusText(RepairJobStatus status) {
    switch (status) {
      case RepairJobStatus.open:
        return 'OPEN';
      case RepairJobStatus.assigned:
        return 'ASSIGNED';
      case RepairJobStatus.inProgress:
        return 'IN PROGRESS';
      case RepairJobStatus.awaitingParts:
        return 'AWAITING PARTS';
      case RepairJobStatus.awaitingInspection:
        return 'AWAITING INSPECTION';
      case RepairJobStatus.completed:
        return 'COMPLETED';
      case RepairJobStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _priorityText(RepairPriority priority) {
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

  Color _statusColor(RepairJobStatus status) {
    switch (status) {
      case RepairJobStatus.open:
        return Colors.blue;
      case RepairJobStatus.assigned:
        return Colors.indigo;
      case RepairJobStatus.inProgress:
        return Colors.orange;
      case RepairJobStatus.awaitingParts:
        return Colors.deepOrange;
      case RepairJobStatus.awaitingInspection:
        return Colors.purple;
      case RepairJobStatus.completed:
        return Colors.green;
      case RepairJobStatus.cancelled:
        return Colors.grey;
    }
  }


  Future<void> _editJob(RepairJob job) async {
    if (job.id == null) {
      _showMessage('This repair job has no database ID.');
      return;
    }

    final result = await showDialog<RepairJob>(
      context: context,
      builder: (context) => _RepairJobEditDialog(job: job),
    );

    if (result == null) return;

    await _repository.updateRepairJob(result);
    _showMessage('Repair job updated.');
    await _refresh();
  }

  Future<void> _completeJob(RepairJob job) async {
    if (job.id == null) {
      _showMessage('This repair job has no database ID.');
      return;
    }

    final result = await showDialog<RepairJob>(
      context: context,
      builder: (context) => _CompleteRepairJobDialog(job: job),
    );

    if (result == null) return;

    await _repository.updateRepairJob(result);
    _showMessage('Repair job marked as completed.');
    await _refresh();
  }

  Future<void> _advanceJob(RepairJob job) async {
    if (job.id == null) {
      _showMessage('This repair job has no database ID.');
      return;
    }

    RepairJobStatus? nextStatus;
    switch (job.status) {
      case RepairJobStatus.open:
        nextStatus = RepairJobStatus.assigned;
        break;
      case RepairJobStatus.assigned:
        nextStatus = RepairJobStatus.inProgress;
        break;
      case RepairJobStatus.inProgress:
        nextStatus = RepairJobStatus.awaitingInspection;
        break;
      case RepairJobStatus.awaitingParts:
        nextStatus = RepairJobStatus.inProgress;
        break;
      case RepairJobStatus.awaitingInspection:
      case RepairJobStatus.completed:
      case RepairJobStatus.cancelled:
        nextStatus = null;
        break;
    }

    if (nextStatus == null) return;

    final now = DateTime.now();
    final updatedJob = job.copyWith(
      status: nextStatus,
      startedAt: nextStatus == RepairJobStatus.inProgress
          ? (job.startedAt ?? now)
          : job.startedAt,
    );

    await _repository.updateRepairJob(updatedJob);

    if (!mounted) return;
    _showMessage(
      'Job status changed to ${_statusText(nextStatus)}.',
    );
    await _refresh();
  }

  Future<void> _sendToParts(RepairJob job) async {
    if (job.id == null) {
      _showMessage('This repair job has no database ID.');
      return;
    }

    final updatedJob = job.copyWith(
      status: RepairJobStatus.awaitingParts,
    );

    await _repository.updateRepairJob(updatedJob);

    if (!mounted) return;
    _showMessage('Job marked as awaiting parts.');
    await _refresh();
  }

  Future<void> _cancelJob(RepairJob job) async {
    if (job.id == null) {
      _showMessage('This repair job has no database ID.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Repair Job?'),
        content: const Text(
          'This will mark the repair job as cancelled. '
          'You can still view its history afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Job'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Job'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _repository.updateRepairJob(
      job.copyWith(status: RepairJobStatus.cancelled),
    );

    if (!mounted) return;
    _showMessage('Repair job cancelled.');
    await _refresh();
  }

  String _primaryActionLabel(RepairJobStatus status) {
    switch (status) {
      case RepairJobStatus.open:
        return 'Assign Job';
      case RepairJobStatus.assigned:
        return 'Start Job';
      case RepairJobStatus.inProgress:
        return 'Send for Inspection';
      case RepairJobStatus.awaitingParts:
        return 'Resume Job';
      case RepairJobStatus.awaitingInspection:
        return 'Complete Job';
      case RepairJobStatus.completed:
      case RepairJobStatus.cancelled:
        return '';
    }
  }

  Widget _workflowActions(
    BuildContext context,
    RepairJob job,
  ) {
    if (job.status == RepairJobStatus.completed ||
        job.status == RepairJobStatus.cancelled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryLabel = _primaryActionLabel(job.status);

    String currentStage;
    String stageDescription;
    IconData stageIcon;

    switch (job.status) {
      case RepairJobStatus.open:
        currentStage = 'Ready to assign';
        stageDescription =
            'Assign this repair job to the workshop workflow to begin work.';
        stageIcon = Icons.person_add_alt_1;
        break;
      case RepairJobStatus.assigned:
        currentStage = 'Assigned';
        stageDescription =
            'The job is assigned and ready for the technician to start.';
        stageIcon = Icons.assignment_ind_outlined;
        break;
      case RepairJobStatus.inProgress:
        currentStage = 'Work in progress';
        stageDescription =
            'The repair is currently being carried out by the workshop.';
        stageIcon = Icons.build_circle_outlined;
        break;
      case RepairJobStatus.awaitingParts:
        currentStage = 'Awaiting parts';
        stageDescription =
            'Parts are required before the technician can continue.';
        stageIcon = Icons.inventory_2_outlined;
        break;
      case RepairJobStatus.awaitingInspection:
        currentStage = 'Awaiting inspection';
        stageDescription =
            'Repair work is ready for inspection before the job is closed.';
        stageIcon = Icons.fact_check_outlined;
        break;
      case RepairJobStatus.completed:
      case RepairJobStatus.cancelled:
        currentStage = _statusText(job.status);
        stageDescription = '';
        stageIcon = Icons.check_circle_outline;
        break;
    }

    final isInspectionStage =
        job.status == RepairJobStatus.awaitingInspection;

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stageIcon,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Workflow',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentStage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (stageDescription.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        stageDescription,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isInspectionStage
                  ? () => _completeJob(job)
                  : () => _advanceJob(job),
              icon: Icon(
                isInspectionStage
                    ? Icons.check_circle_outline
                    : job.status == RepairJobStatus.open
                        ? Icons.person_add_alt_1
                        : Icons.arrow_forward,
              ),
              label: Text(primaryLabel),
            ),
          ),
          if (job.status == RepairJobStatus.inProgress) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sendToParts(job),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Await Parts'),
              ),
            ),
          ],
          if (job.status == RepairJobStatus.awaitingParts) ...[
            const SizedBox(height: 8),
            Text(
              'Once the required parts arrive, resume the repair.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _cancelJob(job),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Job'),
            ),
          ),
        ],
      ),
    );
  }


  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Jobs'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<RepairJob>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 52, color: scheme.error),
                    const SizedBox(height: 14),
                    Text(
                      'Unable to load repair jobs',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _repairHeader(context, 0, 0, 0),
                  const SizedBox(height: 18),
                  _workflowProgress(context, 0, 0),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(Icons.build_circle_outlined,
                              size: 72, color: scheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'No repair jobs recorded',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Repair jobs generated from failed inspection items '
                            'will appear here.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text('Inspection ID: ${widget.inspectionId}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final totalHours =
              jobs.fold<double>(0, (sum, job) => sum + job.estimatedHours);
          final totalCost =
              jobs.fold<double>(0, (sum, job) => sum + job.estimatedCost);
          final completed = jobs
              .where((job) => job.status == RepairJobStatus.completed)
              .length;
          final outstanding = jobs.length - completed;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _repairHeader(context, jobs.length, outstanding, totalCost),
                const SizedBox(height: 18),
                _workflowProgress(context, outstanding, completed),
                const SizedBox(height: 18),
                _summaryCard(
                  context,
                  jobs.length,
                  totalHours,
                  totalCost,
                  completed,
                  outstanding,
                ),
                const SizedBox(height: 18),
                ...jobs.map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _repairCard(context, job),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _repairHeader(
    BuildContext context,
    int jobCount,
    int outstanding,
    double totalCost,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.build_circle_outlined,
                    color: scheme.onPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repair Management',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('Inspection ID: ${widget.inspectionId}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            outstanding > 0
                ? '$outstanding repair ${outstanding == 1 ? 'job' : 'jobs'} require workshop attention'
                : jobCount > 0
                    ? 'All repair jobs are completed'
                    : 'No repair jobs have been recorded',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (jobCount > 0) ...[
            const SizedBox(height: 5),
            Text('Estimated repair value: £${totalCost.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }

  Widget _workflowProgress(
    BuildContext context,
    int outstanding,
    int completed,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget step(
      IconData icon,
      String title,
      String subtitle,
      bool active,
    ) {
      return Expanded(
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: active
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 21,
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 7),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Row(
          children: [
            step(Icons.assignment_outlined, 'Inspection', 'Source', true),
            Expanded(child: Divider(color: scheme.outlineVariant)),
            step(Icons.build_outlined, 'Repairs',
                outstanding > 0 ? 'Outstanding' : 'Clear', outstanding > 0),
            Expanded(child: Divider(color: scheme.outlineVariant)),
            step(Icons.check_circle_outline, 'Complete',
                '$completed done', completed > 0),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    int count,
    double hours,
    double cost,
    int completed,
    int outstanding,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 650 ? 4 : 2;
                final spacing = 10.0;
                final itemWidth = columns == 4
                    ? (constraints.maxWidth - spacing * 3) / 4
                    : (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _summaryValue('Jobs', '$count',
                          Icons.build_outlined),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _summaryValue('Outstanding', '$outstanding',
                          Icons.pending_actions_outlined),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _summaryValue('Completed', '$completed',
                          Icons.check_circle_outline),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _summaryValue('Estimated',
                          '£${cost.toStringAsFixed(2)}', Icons.payments_outlined),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Estimated labour: ${hours.toStringAsFixed(1)} hours',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryValue(String label, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 17),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _repairCard(BuildContext context, RepairJob job) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(job.status);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: job.status == RepairJobStatus.completed
              ? scheme.outlineVariant
              : statusColor.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.build_outlined, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      if (job.jobNumber.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(job.jobNumber,
                            style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_statusText(job.status)),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  side: BorderSide(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(job.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(context, Icons.priority_high_outlined,
                    _priorityText(job.priority)),
                _infoChip(
                  context,
                  Icons.person_outline,
                  job.technicianName.trim().isEmpty
                      ? 'Not assigned'
                      : job.technicianName,
                ),
                _infoChip(
                  context,
                  Icons.inventory_2_outlined,
                  job.partsRequired
                      ? 'Parts required'
                      : 'No parts required',
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _costValue('Estimated Hours',
                          '${job.estimatedHours.toStringAsFixed(1)} hrs'),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _costValue('Estimated Cost',
                          '£${job.estimatedCost.toStringAsFixed(2)}'),
                    ),
                    if (job.actualHours > 0 || job.actualCost > 0) ...[
                      SizedBox(
                        width: itemWidth,
                        child: _costValue('Actual Hours',
                            '${job.actualHours.toStringAsFixed(1)} hrs'),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _costValue('Actual Cost',
                            '£${job.actualCost.toStringAsFixed(2)}'),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _editJob(job),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Job'),
            ),
            _workflowActions(context, job),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _costValue(String label, String value) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RepairJobEditDialog extends StatefulWidget {
  final RepairJob job;

  const _RepairJobEditDialog({
    required this.job,
  });

  @override
  State<_RepairJobEditDialog> createState() =>
      _RepairJobEditDialogState();
}

class _RepairJobEditDialogState
    extends State<_RepairJobEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _technicianController;
  late final TextEditingController _hoursController;
  late final TextEditingController _costController;

  late RepairPriority _priority;
  late RepairJobStatus _status;
  late bool _partsRequired;

  @override
  void initState() {
    super.initState();

    final job = widget.job;

    _titleController = TextEditingController(text: job.title);
    _descriptionController =
        TextEditingController(text: job.description);
    _technicianController =
        TextEditingController(text: job.technicianName);
    _hoursController = TextEditingController(
      text: job.estimatedHours.toString(),
    );
    _costController = TextEditingController(
      text: job.estimatedCost.toString(),
    );

    _priority = job.priority;
    _status = job.status;
    _partsRequired = job.partsRequired;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _technicianController.dispose();
    _hoursController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a repair job title.'),
        ),
      );
      return;
    }

    final hours = double.tryParse(
      _hoursController.text.trim(),
    );
    final cost = double.tryParse(
      _costController.text.trim(),
    );

    if (hours == null || hours < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid estimated hours value.'),
        ),
      );
      return;
    }

    if (cost == null || cost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid estimated cost.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      widget.job.copyWith(
        title: title,
        description: _descriptionController.text.trim(),
        technicianName: _technicianController.text.trim(),
        priority: _priority,
        status: _status,
        partsRequired: _partsRequired,
        estimatedHours: hours,
        estimatedCost: cost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Repair Job'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _technicianController,
                decoration: const InputDecoration(
                  labelText: 'Technician',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RepairPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
                items: RepairPriority.values
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(
                          priority.name.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RepairJobStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: RepairJobStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.name == 'inProgress'
                              ? 'IN PROGRESS'
                              : status.name.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Parts Required'),
                value: _partsRequired,
                onChanged: (value) {
                  setState(() {
                    _partsRequired = value;
                  });
                },
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Estimated Hours',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Estimated Cost (£)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _CompleteRepairJobDialog extends StatefulWidget {
  final RepairJob job;

  const _CompleteRepairJobDialog({
    required this.job,
  });

  @override
  State<_CompleteRepairJobDialog> createState() =>
      _CompleteRepairJobDialogState();
}

class _CompleteRepairJobDialogState
    extends State<_CompleteRepairJobDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _costController;

  @override
  void initState() {
    super.initState();

    _hoursController = TextEditingController(
      text: widget.job.actualHours > 0
          ? widget.job.actualHours.toString()
          : widget.job.estimatedHours.toString(),
    );

    _costController = TextEditingController(
      text: widget.job.actualCost > 0
          ? widget.job.actualCost.toString()
          : widget.job.estimatedCost.toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _complete() {
    final hours = double.tryParse(
      _hoursController.text.trim(),
    );
    final cost = double.tryParse(
      _costController.text.trim(),
    );

    if (hours == null || hours < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid actual hours.'),
        ),
      );
      return;
    }

    if (cost == null || cost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid actual cost.'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    Navigator.of(context).pop(
      widget.job.copyWith(
        status: RepairJobStatus.completed,
        actualHours: hours,
        actualCost: cost,
        completedAt: now,
        startedAt: widget.job.startedAt ?? now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Repair Job'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirm the actual work completed before closing this job.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hoursController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Actual Hours',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Actual Cost (£)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _complete,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark Complete'),
        ),
      ],
    );
  }
}
