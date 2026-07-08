import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final fleetNumberController = TextEditingController();
  final registrationController = TextEditingController();
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final vinController = TextEditingController();

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

  void saveVehicle() {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = Vehicle(
      fleetNumber: fleetNumberController.text.trim(),
      registration: registrationController.text.trim().toUpperCase(),
      make: makeController.text.trim(),
      model: modelController.text.trim(),
      year: int.tryParse(yearController.text) ?? DateTime.now().year,
      vin: vinController.text.trim(),
    );

    Navigator.pop(context, vehicle);
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Vehicle"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: fleetNumberController,
              decoration: decoration("Fleet Number"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: registrationController,
              decoration: decoration("Registration"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: makeController,
              decoration: decoration("Make"),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: modelController,
              decoration: decoration("Model"),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: decoration("Year"),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: vinController,
              decoration: decoration("VIN"),
            ),

            const SizedBox(height: 30),

            FilledButton.icon(
              onPressed: saveVehicle,
              icon: const Icon(Icons.save),
              label: const Text("Save Vehicle"),
            ),
          ],
        ),
      ),
    );
  }
}