import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/form_section.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class EditVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final PermissionService _permissions = PermissionService.instance;

  final VehicleService _vehicleService = VehicleService();

  bool _saving = false;
  DateTime? _motExpiry;
  DateTime? _serviceDue;

  late final TextEditingController fleetController;
  late final TextEditingController registrationController;
  late final TextEditingController makeController;
  late final TextEditingController modelController;
  late final TextEditingController yearController;
  late final TextEditingController vinController;

  @override
  void initState() {
    super.initState();

    fleetController = TextEditingController(text: widget.vehicle.fleetNumber);

    registrationController = TextEditingController(
      text: widget.vehicle.registration,
    );

    makeController = TextEditingController(text: widget.vehicle.make);

    modelController = TextEditingController(text: widget.vehicle.model);

    yearController = TextEditingController(
      text: widget.vehicle.year.toString(),
    );

    vinController = TextEditingController(text: widget.vehicle.vin);
    _motExpiry = widget.vehicle.motExpiry;
    _serviceDue = widget.vehicle.serviceDue;
  }

  @override
  void dispose() {
    fleetController.dispose();
    registrationController.dispose();
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    vinController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    final vehicle = Vehicle(
      id: widget.vehicle.id,
      fleetNumber: fleetController.text.trim(),
      registration: registrationController.text.trim().toUpperCase(),
      make: makeController.text.trim(),
      model: modelController.text.trim(),
      year: int.tryParse(yearController.text.trim()) ?? widget.vehicle.year,
      vin: vinController.text.trim(),
      motExpiry: _motExpiry,
      serviceDue: _serviceDue,
      active: widget.vehicle.active,
    );

    try {
      await _vehicleService.updateVehicle(vehicle);

      if (!mounted) return;

      Navigator.pop(context, vehicle);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update vehicle.\n$error')),
      );
      setState(() {
        _saving = false;
      });
    }
  }

  InputDecoration input(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Future<void> _selectDate({
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not Selected';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _dateControl({
    required String label,
    required IconData icon,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () => _selectDate(currentDate: value, onSelected: onChanged),
            icon: Icon(icon),
            label: Text('$label: ${_formatDate(value)}'),
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear $label',
            onPressed: _saving
                ? null
                : () => setState(() {
                    onChanged(null);
                  }),
            icon: const Icon(Icons.clear),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canManageVehicles) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to edit vehicles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Edit Vehicle',
      subtitle: widget.vehicle.registration,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FormSection(
            title: 'Vehicle identity',
            subtitle: 'Registration and core fleet information.',
            child: Column(
              children: [
                TextField(
                  controller: fleetController,
                  decoration: input("Fleet Number"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: registrationController,
                  decoration: input("Registration"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: makeController,
                  decoration: input("Make"),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: modelController,
                  decoration: input("Model"),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: input("Year"),
                ),
                const SizedBox(height: 16),

                TextField(controller: vinController, decoration: input("VIN")),
              ],
            ),
          ),

          FormSection(
            title: 'Operational details',
            subtitle: 'Optional MOT and service dates.',
            child: Column(
              children: [
                _dateControl(
                  label: 'MOT Expiry',
                  icon: Icons.event,
                  value: _motExpiry,
                  onChanged: (date) {
                    _motExpiry = date;
                  },
                ),
                const SizedBox(height: 12),
                _dateControl(
                  label: 'Service Due',
                  icon: Icons.build,
                  value: _serviceDue,
                  onChanged: (date) {
                    _serviceDue = date;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          FilledButton.icon(
            onPressed: _saving ? null : save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Updating Vehicle...' : 'Update Vehicle'),
          ),
        ],
      ),
    );
  }
}
