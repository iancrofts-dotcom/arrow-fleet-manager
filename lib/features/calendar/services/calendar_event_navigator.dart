import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/screens/vehicle_details_screen.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../../drivers/models/driver.dart';
import '../../drivers/screens/driver_details_screen.dart';
import '../../drivers/services/driver_service.dart';
import '../models/calendar_event.dart';

class CalendarEventNavigator {
  CalendarEventNavigator({
    VehicleService? vehicleService,
    Widget Function(Vehicle vehicle)? vehicleDetailsBuilder,
    DriverService? driverService,
    Widget Function(Driver driver)? driverDetailsBuilder,
  }) : _vehicleService = vehicleService ?? VehicleService(),
       _vehicleDetailsBuilder =
           vehicleDetailsBuilder ??
           ((vehicle) => VehicleDetailsScreen(vehicle: vehicle)),
       _driverService = driverService ?? DriverService(),
       _driverDetailsBuilder =
           driverDetailsBuilder ??
           ((driver) => DriverDetailsScreen(driver: driver));

  final VehicleService _vehicleService;
  final Widget Function(Vehicle vehicle) _vehicleDetailsBuilder;
  final DriverService _driverService;
  final Widget Function(Driver driver) _driverDetailsBuilder;

  Future<bool> openDetails(BuildContext context, CalendarEvent event) {
    if (event.vehicleId != null) return openVehicleDetails(context, event);
    if (event.driverId != null) return openDriverDetails(context, event);
    return Future.value(false);
  }

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

  Future<bool> openDriverDetails(
    BuildContext context,
    CalendarEvent event,
  ) async {
    final driverId = event.driverId;
    if (driverId == null) return false;

    final driver = await _driverService.getDriverById(driverId);
    if (!context.mounted) return false;
    if (driver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This driver is no longer available.')),
      );
      return false;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _driverDetailsBuilder(driver)));
    return true;
  }
}
