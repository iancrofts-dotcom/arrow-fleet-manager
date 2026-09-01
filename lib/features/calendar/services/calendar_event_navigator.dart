import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/screens/vehicle_details_screen.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/calendar_event.dart';

class CalendarEventNavigator {
  CalendarEventNavigator({
    VehicleService? vehicleService,
    Widget Function(Vehicle vehicle)? vehicleDetailsBuilder,
  }) : _vehicleService = vehicleService ?? VehicleService(),
       _vehicleDetailsBuilder =
           vehicleDetailsBuilder ??
           ((vehicle) => VehicleDetailsScreen(vehicle: vehicle));

  final VehicleService _vehicleService;
  final Widget Function(Vehicle vehicle) _vehicleDetailsBuilder;

  /// Opens the current persisted Vehicle for an actionable calendar event.
  /// Returns true only when a details route was opened.
  Future<bool> openVehicleDetails(
    BuildContext context,
    CalendarEvent event,
  ) async {
    final vehicleId = event.vehicleId;
    if (vehicleId == null) return false;

    final vehicle = await _vehicleService.getVehicleById(vehicleId);
    if (!context.mounted) return false;

    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This vehicle is no longer available.')),
      );
      return false;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _vehicleDetailsBuilder(vehicle)));
    return true;
  }
}
