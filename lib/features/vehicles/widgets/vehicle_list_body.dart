import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import 'vehicle_card.dart';

class VehicleListBody extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Vehicle vehicle) onVehicleTap;

  const VehicleListBody({
    super.key,
    required this.vehicles,
    required this.onRefresh,
    required this.onVehicleTap,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return const Center(
        child: Text(
          'No vehicles found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];

          return VehicleCard(
            vehicle: vehicle,
            onTap: () => onVehicleTap(vehicle),
          );
        },
      ),
    );
  }
}