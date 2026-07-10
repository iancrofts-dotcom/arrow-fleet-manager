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
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
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
      motExpiry: motExpiry,
      serviceDue: serviceDue,
    );

    Navigator.pop(context, vehicle);
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return "Not Selected";
    }

    return "${date.day}/${date.month}/${date.year}";
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

            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () {
                selectDate(
                  currentDate: motExpiry,
                  onSelected: (date) {
                    motExpiry = date;
                  },
                );
              },
              icon: const Icon(Icons.event),
              label: Text(
                "MOT Expiry: ${formatDate(motExpiry)}",
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                selectDate(
                  currentDate: serviceDue,
                  onSelected: (date) {
                    serviceDue = date;
                  },
                );
              },
              icon: const Icon(Icons.build),
              label: Text(
                "Service Due: ${formatDate(serviceDue)}",
              ),
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