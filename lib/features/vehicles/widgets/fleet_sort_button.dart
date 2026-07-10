import 'package:flutter/material.dart';

import '../models/vehicle_sort.dart';

class FleetSortButton extends StatelessWidget {
  final VehicleSort selectedSort;
  final ValueChanged<VehicleSort> onChanged;

  const FleetSortButton({
    super.key,
    required this.selectedSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VehicleSort>(
      tooltip: 'Sort Vehicles',
      icon: const Icon(Icons.sort),
      initialValue: selectedSort,
      onSelected: onChanged,
      itemBuilder: (context) {
        return VehicleSort.values.map((sort) {
          return PopupMenuItem(
            value: sort,
            child: Text(_label(sort)),
          );
        }).toList();
      },
    );
  }

  String _label(VehicleSort sort) {
    switch (sort) {
      case VehicleSort.registration:
        return 'Registration';

      case VehicleSort.fleetNumber:
        return 'Fleet Number';

      case VehicleSort.make:
        return 'Make';

      case VehicleSort.model:
        return 'Model';

      case VehicleSort.motExpiry:
        return 'MOT Expiry';

      case VehicleSort.serviceDue:
        return 'Service Due';
    }
  }
}