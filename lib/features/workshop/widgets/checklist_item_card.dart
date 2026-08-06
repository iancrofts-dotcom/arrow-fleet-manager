import 'package:flutter/material.dart';

import '../models/inspection_checklist_item.dart';

class ChecklistItemCard extends StatefulWidget {
  final InspectionChecklistItem item;
  final ValueChanged<InspectionChecklistItem>? onChanged;

  const ChecklistItemCard({
    super.key,
    required this.item,
    this.onChanged,
  });

  @override
  State<ChecklistItemCard> createState() =>
      _ChecklistItemCardState();
}

class _ChecklistItemCardState
    extends State<ChecklistItemCard> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.item.notes,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _setStatus(ChecklistStatus status) {
    setState(() {
      widget.item.status = status;

      widget.item.repairRequired =
          status == ChecklistStatus.fail;

      widget.item.notes = _notesController.text;
    });

    widget.onChanged?.call(widget.item);
  }

  Color _priorityColor() {
    switch (widget.item.priority) {
      case ChecklistPriority.low:
        return Colors.green;

      case ChecklistPriority.medium:
        return Colors.orange;

      case ChecklistPriority.high:
        return Colors.deepOrange;

      case ChecklistPriority.critical:
        return Colors.red;
    }
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
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Chip(
                  backgroundColor: _priorityColor()
                      .withValues(alpha: 0.15),
                  label: Text(
                    widget.item.priority.name
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

            const SizedBox(height: 4),

            Text(
              widget.item.category,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('PASS'),
                  selected:
                      widget.item.status ==
                          ChecklistStatus.pass,
                  onSelected: (_) => _setStatus(
                    ChecklistStatus.pass,
                  ),
                ),
                ChoiceChip(
                  label:
                      const Text('ADVISORY'),
                  selected:
                      widget.item.status ==
                          ChecklistStatus.advisory,
                  onSelected: (_) => _setStatus(
                    ChecklistStatus.advisory,
                  ),
                ),
                ChoiceChip(
                  label: const Text('FAIL'),
                  selected:
                      widget.item.status ==
                          ChecklistStatus.fail,
                  onSelected: (_) => _setStatus(
                    ChecklistStatus.fail,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration:
                  const InputDecoration(
                labelText: 'Notes',
                border:
                    OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.item.notes = value;
                widget.onChanged?.call(
                  widget.item,
                );
              },
            ),

            if (widget.item.repairRequired) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                  border: Border.all(
                    color: Colors.red,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.build,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Repair job will be created automatically.',
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