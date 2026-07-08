import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class VehiclePicker extends StatelessWidget {
  const VehiclePicker({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onChanged,
  });

  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final ValueChanged<Vehicle?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Vehicle>(
      initialValue: selectedVehicle,
      decoration: const InputDecoration(
        labelText: 'Vehicle',
        border: OutlineInputBorder(),
      ),
      items: vehicles.map((vehicle) {
        return DropdownMenuItem<Vehicle>(
          value: vehicle,
          child: Text(
            '${vehicle.fleetNumber} • ${vehicle.registration}',
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a vehicle';
        }
        return null;
      },
    );
  }
}