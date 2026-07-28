import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({
    super.key,
  });

  @override
  State<AddVehicleScreen> createState() =>
      _AddVehicleScreenState();
}

class _AddVehicleScreenState
    extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final PermissionService _permissions =
      PermissionService.instance;

  final VehicleService _vehicleService =
      VehicleService();

  bool _saving = false;

  final fleetNumberController =
      TextEditingController();

  final registrationController =
      TextEditingController();

  final makeController =
      TextEditingController();

  final modelController =
      TextEditingController();

  final yearController =
      TextEditingController();

  final vinController =
      TextEditingController();

  DateTime? motExpiry;
  DateTime? serviceDue;

  @override
  void dispose() {
    fleetNumberController.dispose();
    registrationController.dispose();
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    vinController.dispose();
    super.dispose();
  }

  Future<void> selectDate({
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  Future<void> saveVehicle() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final vehicle = Vehicle(
        fleetNumber:
            fleetNumberController.text.trim(),
        registration:
            registrationController.text
                .trim()
                .toUpperCase(),
        make: makeController.text.trim(),
        model: modelController.text.trim(),
        year:
            int.tryParse(
                  yearController.text,
                ) ??
                DateTime.now().year,
        vin: vinController.text.trim(),
        motExpiry: motExpiry,
        serviceDue: serviceDue,
      );

      final savedVehicle =
          await _vehicleService.addVehicle(
        vehicle,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        savedVehicle,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save vehicle.\n$e',
          ),
        ),
      );

      setState(() {
        _saving = false;
      });
    }
  }

  InputDecoration decoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      border:
          const OutlineInputBorder(),
    );
  }

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not Selected';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canManageVehicles) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Access Denied',
          ),
        ),
        body: const Center(
          child: Text(
            'You do not have permission to add vehicles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Vehicle',
        ),
      ),
      body: IgnorePointer(
        ignoring: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller:
                    fleetNumberController,
                decoration:
                    decoration(
                  'Fleet Number',
                ),
                validator: (value) =>
                    value == null ||
                            value.isEmpty
                        ? 'Required'
                        : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    registrationController,
                decoration:
                    decoration(
                  'Registration',
                ),
                validator: (value) =>
                    value == null ||
                            value.isEmpty
                        ? 'Required'
                        : null,
              ),

              const SizedBox(height: 16),              TextFormField(
                controller: makeController,
                decoration: decoration(
                  'Make',
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: modelController,
                decoration: decoration(
                  'Model',
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: yearController,
                keyboardType:
                    TextInputType.number,
                decoration: decoration(
                  'Year',
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: vinController,
                decoration: decoration(
                  'VIN',
                ),
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        selectDate(
                          currentDate:
                              motExpiry,
                          onSelected:
                              (date) {
                            motExpiry =
                                date;
                          },
                        );
                      },
                icon: const Icon(
                  Icons.event,
                ),
                label: Text(
                  'MOT Expiry: ${formatDate(motExpiry)}',
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        selectDate(
                          currentDate:
                              serviceDue,
                          onSelected:
                              (date) {
                            serviceDue =
                                date;
                          },
                        );
                      },
                icon: const Icon(
                  Icons.build,
                ),
                label: Text(
                  'Service Due: ${formatDate(serviceDue)}',
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed:
                    _saving
                        ? null
                        : saveVehicle,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : 'Save Vehicle',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}