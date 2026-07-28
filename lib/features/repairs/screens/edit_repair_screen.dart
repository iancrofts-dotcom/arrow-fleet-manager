import 'package:flutter/material.dart';

import '../models/repair.dart';
import '../repositories/repair_repository.dart';

class EditRepairScreen extends StatefulWidget {
  final Repair repair;

  const EditRepairScreen({
    super.key,
    required this.repair,
  });

  @override
  State<EditRepairScreen> createState() =>
      _EditRepairScreenState();
}

class _EditRepairScreenState
    extends State<EditRepairScreen> {
  final RepairRepository _repository =
      RepairRepository();

  late TextEditingController
      _mechanicController;

  late TextEditingController
      _notesController;

  late String _status;

  late String _priority;

  @override
  void initState() {
    super.initState();

    _mechanicController =
        TextEditingController(
      text: widget.repair.mechanic,
    );

    _notesController =
        TextEditingController(
      text: widget.repair.repairNotes,
    );

    _status = widget.repair.status;
    _priority = widget.repair.priority;
  }

  @override
  void dispose() {
    _mechanicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRepair() async {
    final updatedRepair =
        widget.repair.copyWith(
      mechanic:
          _mechanicController.text.trim(),
      repairNotes:
          _notesController.text.trim(),
      status: _status,
      priority: _priority,
      completedDate:
          _status == 'Completed'
              ? DateTime.now()
              : null,
    );

    await _repository.updateRepair(
      updatedRepair,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Repair updated successfully.',
        ),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Repair'),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.repair.repairNumber,
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller:
                  _mechanicController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Assigned Mechanic',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
  initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Open',
                  child: Text('Open'),
                ),
                DropdownMenuItem(
                  value: 'In Progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _status = value;
                });
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
  initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Low',
                  child: Text('Low'),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: 'High',
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: 'Critical',
                  child: Text('Critical'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _priority = value;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _notesController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Repair Notes',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
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
                    icon: const Icon(
                      Icons.close,
                    ),
                    label: const Text(
                      'Cancel',
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveRepair,
                    icon: const Icon(
                      Icons.save,
                    ),
                    label: const Text(
                      'Save',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}