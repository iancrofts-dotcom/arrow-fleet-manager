import 'package:flutter/material.dart';

import '../../models/inspection_wizard_data.dart';
import '../../models/workshop_inspection.dart';

class Step1VehicleDetails extends StatefulWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;

  const Step1VehicleDetails({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<Step1VehicleDetails> createState() =>
      _Step1VehicleDetailsState();
}

class _Step1VehicleDetailsState
    extends State<Step1VehicleDetails> {
  final _formKey = GlobalKey<FormState>();

  final _registrationController =
      TextEditingController();

  final _fleetNumberController =
      TextEditingController();

  final _mileageController =
      TextEditingController();

  WorkshopInspectionType? _inspectionType;

  @override
  void initState() {
    super.initState();

    _registrationController.text =
        widget.data.registration ?? '';

    _fleetNumberController.text =
        widget.data.fleetNumber ?? '';

    if (widget.data.mileage != null) {
      _mileageController.text =
          widget.data.mileage.toString();
    }

    _inspectionType =
        widget.data.inspectionType;
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _fleetNumberController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.data.mileage =
        int.parse(_mileageController.text);

    widget.data.inspectionType =
        _inspectionType;

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding:
            const EdgeInsets.all(24),
        children: [
          Text(
            'Vehicle Details',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ListTile(
                    leading:
                        Icon(Icons.directions_bus),
                    title: Text(
                      'Vehicle Selection',
                    ),
                    subtitle: Text(
                      'Vehicle search will be connected in the next step.',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                        _registrationController,
                    readOnly: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Registration',
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller:
                        _fleetNumberController,
                    readOnly: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Fleet Number',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller:
                _mileageController,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'Current Mileage',
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Enter the mileage';
              }

              if (int.tryParse(value) ==
                  null) {
                return 'Mileage must be a number';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<
              WorkshopInspectionType>(
            value: _inspectionType,
            decoration:
                const InputDecoration(
              labelText:
                  'Inspection Type',
            ),
            items:
                WorkshopInspectionType.values
                    .map(
                      (type) =>
                          DropdownMenuItem(
                        value: type,
                        child: Text(type.name),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                _inspectionType =
                    value;
              });
            },
            validator: (value) =>
                value == null
                    ? 'Select an inspection type'
                    : null,
          ),

          const SizedBox(height: 40),

          Align(
            alignment:
                Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _continue,
              icon:
                  const Icon(Icons.arrow_forward),
              label:
                  const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}