import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class VehicleSelector extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final ValueChanged<Vehicle?> onChanged;
  final String label;
  final bool enabled;

  const VehicleSelector({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onChanged,
    this.label = 'Vehicle',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<Vehicle>(
      enabled: enabled,
      width: 450,
      initialSelection: selectedVehicle,
      label: Text(label),
      hintText: 'Select a vehicle',
      onSelected: onChanged,
      dropdownMenuEntries: vehicles
          .map(
            (vehicle) => DropdownMenuEntry<Vehicle>(
              value: vehicle,
              label:
                  '${vehicle.fleetNumber} - ${vehicle.registration}',
              leadingIcon: const Icon(
                Icons.directions_bus,
              ),
            ),
          )
          .toList(),
    );
  }
}