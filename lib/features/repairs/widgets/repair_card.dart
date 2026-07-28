import 'package:flutter/material.dart';

import '../models/repair.dart';

class RepairCard extends StatelessWidget {
  final Repair repair;
  final VoidCallback? onTap;

  const RepairCard({
    super.key,
    required this.repair,
    this.onTap,
  });

  Color _priorityColour() {
    switch (repair.priority.toLowerCase()) {
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

  Color _statusColour() {
    switch (repair.status.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      repair.registration,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    backgroundColor:
                        _priorityColour(),
                    label: Text(
                      repair.priority,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                repair.repairNumber,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                repair.defect,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),
                            Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repair.mechanic.isEmpty
                          ? 'Unassigned'
                          : repair.mechanic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (repair.dueDate != null)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Due: ${repair.dueDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Chip(
                    backgroundColor: _statusColour(),
                    label: Text(
                      repair.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}