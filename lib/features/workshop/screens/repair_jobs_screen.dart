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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Jobs'),
      ),
      body: FutureBuilder<List<RepairJob>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
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
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                            0.28,
                  ),
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'No repair jobs recorded',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Inspection ID: ${widget.inspectionId}',
                    ),
                  ),
                ],
              ),
            );
          }

          final totalHours = jobs.fold<double>(
            0,
            (sum, job) => sum + job.estimatedHours,
          );

          final totalCost = jobs.fold<double>(
            0,
            (sum, job) => sum + job.estimatedCost,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _summaryCard(
                  context,
                  jobs.length,
                  totalHours,
                  totalCost,
                ),
                const SizedBox(height: 16),
                ...jobs.map(
                  (job) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: _repairCard(
                      context,
                      job,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    int count,
    double hours,
    double cost,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _summaryValue(
                    'Jobs',
                    '$count',
                    Icons.build_outlined,
                  ),
                ),
                Expanded(
                  child: _summaryValue(
                    'Hours',
                    hours.toStringAsFixed(1),
                    Icons.schedule_outlined,
                  ),
                ),
                Expanded(
                  child: _summaryValue(
                    'Estimated',
                    '£${cost.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryValue(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _repairCard(
    BuildContext context,
    RepairJob job,
  ) {
    final statusColor = _statusColor(job.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(Icons.build_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    job.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    _statusText(job.status),
                  ),
                  backgroundColor:
                      statusColor.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (job.jobNumber.trim().isNotEmpty)
              _detailRow(
                'Job Number',
                job.jobNumber,
              ),
            _detailRow(
              'Description',
              job.description,
            ),
            _detailRow(
              'Priority',
              _priorityText(job.priority),
            ),
            _detailRow(
              'Technician',
              job.technicianName.trim().isEmpty
                  ? 'Not assigned'
                  : job.technicianName,
            ),
            _detailRow(
              'Parts Required',
              job.partsRequired ? 'Yes' : 'No',
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _costValue(
                    'Estimated Hours',
                    '${job.estimatedHours.toStringAsFixed(1)} hrs',
                  ),
                ),
                Expanded(
                  child: _costValue(
                    'Estimated Cost',
                    '£${job.estimatedCost.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            if (job.actualHours > 0 ||
                job.actualCost > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _costValue(
                      'Actual Hours',
                      '${job.actualHours.toStringAsFixed(1)} hrs',
                    ),
                  ),
                  Expanded(
                    child: _costValue(
                      'Actual Cost',
                      '£${job.actualCost.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editJob(job),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Job'),
                  ),
                ),
                if (job.status != RepairJobStatus.completed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _completeJob(job),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _costValue(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
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
