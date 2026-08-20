import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class EditVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() =>
      _EditVehicleScreenState();
}

class _EditVehicleScreenState
    extends State<EditVehicleScreen> {

  final PermissionService _permissions =
      PermissionService.instance;

  final VehicleService _vehicleService = VehicleService();

  bool _saving = false;

  late final TextEditingController fleetController;
  late final TextEditingController registrationController;
  late final TextEditingController makeController;
  late final TextEditingController modelController;
  late final TextEditingController yearController;
  late final TextEditingController vinController;

  @override
  void initState() {
    super.initState();

    fleetController =
        TextEditingController(
      text: widget.vehicle.fleetNumber,
    );

    registrationController =
        TextEditingController(
      text: widget.vehicle.registration,
    );

    makeController =
        TextEditingController(
      text: widget.vehicle.make,
    );

    modelController =
        TextEditingController(
      text: widget.vehicle.model,
    );

    yearController =
        TextEditingController(
      text: widget.vehicle.year.toString(),
    );

    vinController =
        TextEditingController(
      text: widget.vehicle.vin,
    );
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
        registration:
            registrationController.text
                .trim()
                .toUpperCase(),
        make: makeController.text.trim(),
        model: modelController.text.trim(),
        year:
            int.tryParse(
                  yearController.text.trim(),
                ) ??
                widget.vehicle.year,
        vin: vinController.text.trim(),
        motExpiry: widget.vehicle.motExpiry,
        serviceDue: widget.vehicle.serviceDue,
        active: widget.vehicle.active,
      );

    try {
      await _vehicleService.updateVehicle(vehicle);

      if (!mounted) return;

      Navigator.pop(context, vehicle);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update vehicle.\n$error'),
        ),
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

  @override
  Widget build(BuildContext context) {

    if (!_permissions.canManageVehicles) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
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

          TextField(
            controller: vinController,
            decoration: input("VIN"),
          ),

          const SizedBox(height: 30),

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
