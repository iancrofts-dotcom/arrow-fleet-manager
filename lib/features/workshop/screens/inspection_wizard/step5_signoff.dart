import 'package:flutter/material.dart';

import '../../models/inspection_wizard_data.dart';
import '../../../auth/services/auth_service.dart';

class Step5Signoff extends StatefulWidget {
  final InspectionWizardData data;
  final VoidCallback onPrevious;
  final Future<void> Function() onFinish;

  const Step5Signoff({
    super.key,
    required this.data,
    required this.onPrevious,
    required this.onFinish,
  });

  @override
  State<Step5Signoff> createState() =>
      _Step5SignoffState();
}

class _Step5SignoffState
    extends State<Step5Signoff> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController
      _technicianController;

  late final TextEditingController
      _managerController;

  late final TextEditingController
      _notesController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _technicianController =
        TextEditingController(
      text: widget.data.technicianName ??
          widget.data.technician ??
          '',
    );

    final currentUser =
        AuthService.instance.currentUser;

    final managerUsername =
        currentUser?.username ??
        widget.data.workshopManager ??
        '';

    widget.data.workshopManager =
        managerUsername;

    _managerController =
        TextEditingController(
      text: managerUsername,
    );

    _notesController =
        TextEditingController(
      text: widget.data.finalNotes ?? '',
    );
  }

  @override
  void dispose() {
    _technicianController.dispose();
    _managerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _finishInspection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.data.technician =
        _technicianController.text.trim();

    widget.data.technicianName =
        _technicianController.text.trim();

    widget.data.workshopManager =
        _managerController.text.trim();

    widget.data.finalNotes =
        _notesController.text.trim();

    setState(() {
      _saving = true;
    });

    try {
      await widget.onFinish();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Inspection Sign-off',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall,
                        ),

                        const SizedBox(height: 24),

                        TextFormField(
                          controller:
                              _technicianController,
                          decoration:
                              const InputDecoration(
                            labelText: 'Technician',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter technician name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller:
                              _managerController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Workshop Manager',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller:
                              _notesController,
                          maxLines: 5,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Final Notes',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : widget.onPrevious,
                    icon:
                        const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : _finishInspection,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : 'Finish Inspection',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}