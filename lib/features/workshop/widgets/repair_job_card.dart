import 'package:flutter/material.dart';

import '../models/repair_job.dart';

class RepairJobCard extends StatefulWidget {
  final RepairJob repairJob;
  final ValueChanged<RepairJob>? onChanged;

  const RepairJobCard({
    super.key,
    required this.repairJob,
    this.onChanged,
  });

  @override
  State<RepairJobCard> createState() =>
      _RepairJobCardState();
}

class _RepairJobCardState
    extends State<RepairJobCard> {
  late final TextEditingController _hoursController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();

    _hoursController = TextEditingController(
      text: widget.repairJob.estimatedHours.toString(),
    );

    _costController = TextEditingController(
      text: widget.repairJob.estimatedCost.toStringAsFixed(2),
    );

    _notesController = TextEditingController(
      text: widget.repairJob.description,
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color _priorityColor() {
    switch (widget.repairJob.priority) {
      case RepairPriority.low:
        return Colors.green;

      case RepairPriority.medium:
        return Colors.orange;

      case RepairPriority.high:
        return Colors.deepOrange;

      case RepairPriority.critical:
        return Colors.red;
    }
  }

  IconData _priorityIcon() {
    switch (widget.repairJob.priority) {
      case RepairPriority.low:
        return Icons.check_circle;

      case RepairPriority.medium:
        return Icons.info;

      case RepairPriority.high:
        return Icons.warning;

      case RepairPriority.critical:
        return Icons.error;
    }
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      widget.repairJob.copyWith(
        estimatedHours:
            double.tryParse(_hoursController.text) ??
                widget.repairJob.estimatedHours,
        estimatedCost:
            double.tryParse(_costController.text) ??
                widget.repairJob.estimatedCost,
        description: _notesController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _priorityIcon(),
                  color: _priorityColor(),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    widget.repairJob.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),

                Chip(
                  backgroundColor:
                      _priorityColor().withValues(
                    alpha: 0.15,
                  ),
                  label: Text(
                    widget.repairJob.priority.name
                        .toUpperCase(),
                    style: TextStyle(
                      color: _priorityColor(),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              widget.repairJob.vehicleRegistration,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _hoursController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Estimated Hours',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _notifyChanged(),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _costController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Estimated Cost',
                prefixText: '£',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _notifyChanged(),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Repair Notes',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _notifyChanged(),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.build,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Text(
                  widget.repairJob.partsRequired
                      ? 'Parts Required'
                      : 'No Parts Required',
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    widget.repairJob.status.name
                        .toUpperCase(),
                  ),
                ),
              ],
            ),

            if (!widget.repairJob.roadworthy) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(
                    color: Colors.red,
                  ),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.dangerous,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vehicle is not roadworthy until this repair is completed.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}