import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.local_shipping),
        ),
        title: Text(
          vehicle.registration,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${vehicle.make} ${vehicle.model}\nFleet No: ${vehicle.fleetNumber}',
        ),
        isThreeLine: true,
        trailing: Icon(
          vehicle.active
              ? Icons.check_circle
              : Icons.cancel,
          color: vehicle.active
              ? Colors.green
              : Colors.red,
        ),
        onTap: onTap,
      ),
    );
  }
}