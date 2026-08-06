import 'package:flutter/material.dart';

import '../models/repair_job.dart';

class RepairJobFormScreen extends StatefulWidget {
  final RepairJob? repairJob;

  const RepairJobFormScreen({
    super.key,
    this.repairJob,
  });

  @override
  State<RepairJobFormScreen> createState() =>
      _RepairJobFormScreenState();
}

class _RepairJobFormScreenState
    extends State<RepairJobFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hoursController;
  late final TextEditingController _costController;

  @override
  void initState() {
    super.initState();

    final job = widget.repairJob;

    _titleController = TextEditingController(
      text: job?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: job?.description ?? '',
    );

    _hoursController = TextEditingController(
      text: job?.estimatedHours.toString() ?? '1',
    );

    _costController = TextEditingController(
      text: job?.estimatedCost.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      {
        'title': _titleController.text.trim(),
        'description':
            _descriptionController.text.trim(),
        'hours':
            double.parse(_hoursController.text),
        'cost':
            double.parse(_costController.text),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing =
        widget.repairJob != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit Repair Job'
              : 'New Repair Job',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
              ),
              validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Enter a title'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:
                  _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hoursController,
              keyboardType:
                  TextInputType.number,
              decoration: const InputDecoration(
                labelText:
                    'Estimated Hours',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              keyboardType:
                  TextInputType.number,
              decoration: const InputDecoration(
                labelText:
                    'Estimated Cost (£)',
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text(
                  'Save Repair Job'),
            ),
          ],
        ),
      ),
    );
  }
}