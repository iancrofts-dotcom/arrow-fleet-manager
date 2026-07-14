import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';

class MaintenanceRecordCard extends StatelessWidget {
  const MaintenanceRecordCard({
    super.key,
    required this.record,
    this.onTap,
  });

  final MaintenanceRecord record;
  final VoidCallback? onTap;

  Color _statusColor() {
    if (record.completed) {
      return Colors.green;
    }

    if (record.isOverdue) {
      return Colors.red;
    }

    if (record.daysRemaining <= 30) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  String _statusText() {
    if (record.completed) {
      return 'Completed';
    }

    if (record.isOverdue) {
      return 'Overdue';
    }

    if (record.daysRemaining <= 30) {
      return 'Due Soon';
    }

    return 'Scheduled';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor(),
          child: Icon(
            record.completed
                ? Icons.check
                : Icons.build,
            color: Colors.white,
          ),
        ),
        title: Text(record.title),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(record.description),

            const SizedBox(height: 4),

            Text(
              'Due: ${record.dueDate.day}/${record.dueDate.month}/${record.dueDate.year}',
            ),

            Text(
              'Estimated: £${record.estimatedCost.toStringAsFixed(2)}',
            ),
          ],
        ),
        trailing: Chip(
          label: Text(_statusText()),
          backgroundColor:
              _statusColor().withValues(alpha: 0.15),
        ),
      ),
    );
  }
}