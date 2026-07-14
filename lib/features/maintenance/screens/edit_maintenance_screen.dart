import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';
import '../services/maintenance_service.dart';

class EditMaintenanceScreen extends StatefulWidget {
  const EditMaintenanceScreen({
    super.key,
    required this.record,
  });

  final MaintenanceRecord record;

  @override
  State<EditMaintenanceScreen> createState() =>
      _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState
    extends State<EditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  final MaintenanceService _service =
      MaintenanceService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _actualCostController;

  late DateTime _dueDate;
  DateTime? _completedDate;
  late bool _completed;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.record.title,
    );

    _descriptionController =
        TextEditingController(
      text: widget.record.description,
    );

    _estimatedCostController =
        TextEditingController(
      text: widget.record.estimatedCost
          .toStringAsFixed(2),
    );

    _actualCostController =
        TextEditingController(
      text: widget.record.actualCost
              ?.toStringAsFixed(2) ??
          '',
    );

    _dueDate = widget.record.dueDate;
    _completedDate = widget.record.completedDate;
    _completed = widget.record.completed;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    _actualCostController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      _dueDate = selected;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = widget.record.copyWith(
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim(),
      dueDate: _dueDate,
      estimatedCost: double.parse(
        _estimatedCostController.text,
      ),
      actualCost:
          _actualCostController.text.trim().isEmpty
              ? null
              : double.parse(
                  _actualCostController.text,
                ),
      completed: _completed,
      completedDate:
          _completed ? (_completedDate ?? DateTime.now()) : null,
    );

    await _service.save(updated);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (widget.record.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Maintenance'),
        content: const Text(
          'Delete this maintenance record?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.delete(widget.record.id!);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Maintenance'),
        actions: [
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Maintenance Title',
                border:
                    OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null ||
                          value.trim().isEmpty
                      ? 'Enter a title'
                      : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  _descriptionController,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  _estimatedCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText:
                    'Estimated Cost',
                prefixText: '£ ',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  _actualCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText:
                    'Actual Cost',
                prefixText: '£ ',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.event),
                title:
                    const Text('Due Date'),
                subtitle:
                    Text(_formatDate(_dueDate)),
                trailing: const Icon(
                  Icons.calendar_month,
                ),
                onTap: _pickDueDate,
              ),
            ),

            SwitchListTile(
              value: _completed,
              title: const Text(
                'Maintenance Completed',
              ),
              onChanged: (value) {
                setState(() {
                  _completed = value;
                  if (value) {
                    _completedDate =
                        DateTime.now();
                  } else {
                    _completedDate = null;
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              icon:
                  const Icon(Icons.save),
              label:
                  const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}