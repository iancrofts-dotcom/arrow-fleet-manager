import 'package:flutter/material.dart';

import '../models/vehicle.dart';

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
        TextEditingController(text: widget.vehicle.fleetNumber);

    registrationController =
        TextEditingController(text: widget.vehicle.registration);

    makeController =
        TextEditingController(text: widget.vehicle.make);

    modelController =
        TextEditingController(text: widget.vehicle.model);

    yearController =
        TextEditingController(text: widget.vehicle.year.toString());

    vinController =
        TextEditingController(text: widget.vehicle.vin);
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

  void save() {
    Navigator.pop(
      context,
      Vehicle(
        id: widget.vehicle.id,
        fleetNumber: fleetController.text.trim(),
        registration:
            registrationController.text.trim().toUpperCase(),
        make: makeController.text.trim(),
        model: modelController.text.trim(),
        year:
            int.tryParse(yearController.text.trim()) ??
                widget.vehicle.year,
        vin: vinController.text.trim(),
        motExpiry: widget.vehicle.motExpiry,
        serviceDue: widget.vehicle.serviceDue,
        active: widget.vehicle.active,
      ),
    );
  }

  InputDecoration input(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Vehicle"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
            onPressed: save,
            icon: const Icon(Icons.save),
            label: const Text("Update Vehicle"),
          ),
        ],
      ),
    );
  }
}