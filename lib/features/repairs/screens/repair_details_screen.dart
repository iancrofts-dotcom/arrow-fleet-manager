import 'package:flutter/material.dart';

import '../models/repair.dart';
import 'edit_repair_screen.dart';

class RepairDetailsScreen extends StatefulWidget {
  final Repair repair;

  const RepairDetailsScreen({
    super.key,
    required this.repair,
  });

  @override
  State<RepairDetailsScreen> createState() =>
      _RepairDetailsScreenState();
}

class _RepairDetailsScreenState
    extends State<RepairDetailsScreen> {

  Color _statusColour() {
    switch (widget.repair.status.toLowerCase()) {
      case 'open':
        return Colors.red;

      case 'in progress':
        return Colors.orange;

      case 'completed':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Color _priorityColour() {
    switch (widget.repair.priority.toLowerCase()) {
      case 'critical':
        return Colors.red;

      case 'high':
        return Colors.orange;

      case 'medium':
        return Colors.amber;

      case 'low':
        return Colors.green;

      default:
        return Colors.blueGrey;
    }
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return date
        .toLocal()
        .toString()
        .split(' ')[0];
  }

Future<void> _editRepair() async {
  final updated = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => EditRepairScreen(
        repair: widget.repair,
      ),
    ),
  );

  if (!mounted) return;

  if (updated == true) {
    Navigator.pop(context, true);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.repair.repairNumber,
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.repair.registration,
                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Chip(
                      backgroundColor:
                          _priorityColour(),
                      label: Text(
                        widget.repair.priority,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Chip(
                      backgroundColor:
                          _statusColour(),
                      label: Text(
                        widget.repair.status,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _detailRow(
                  'Driver',
                  widget.repair.driver,
                ),

                _detailRow(
                  'Defect',
                  widget.repair.defect,
                ),

                _detailRow(
                  'Mechanic',
                  widget.repair.mechanic.isEmpty
                      ? 'Unassigned'
                      : widget.repair.mechanic,
                ),

                _detailRow(
                  'Raised',
                  _formatDate(
                    widget.repair.dateRaised,
                  ),
                ),

                _detailRow(
                  'Due',
                  _formatDate(
                    widget.repair.dueDate,
                  ),
                ),

                _detailRow(
                  'Completed',
                  _formatDate(
                    widget.repair.completedDate,
                  ),
                ),

                const SizedBox(height: 24),
                                Text(
                  'Defect Notes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.repair.defectNotes.trim().isEmpty
                        ? 'No defect notes recorded.'
                        : widget.repair.defectNotes,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Repair Notes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.repair.repairNotes.trim().isEmpty
                        ? 'No repair notes available.'
                        : widget.repair.repairNotes,
                  ),
                ),

                const SizedBox(height: 30),

                Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text(
          'Back',
        ),
      ),
    ),

    const SizedBox(width: 16),

    Expanded(
      child: ElevatedButton.icon(
        onPressed: _editRepair,
        icon: const Icon(Icons.edit),
        label: const Text(
          'Edit Repair',
        ),
      ),
    ),
  ],
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}