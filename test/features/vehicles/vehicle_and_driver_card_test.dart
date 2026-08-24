import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/widgets/driver_card.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vehicle and driver cards retain visible active status labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              VehicleCard(
                vehicle: Vehicle(
                  registration: 'AB12 CDE',
                  fleetNumber: 'F-1',
                  make: 'Arrow',
                  model: 'Van',
                  year: 2025,
                  vin: 'vehicle-vin',
                ),
              ),
              const DriverCard(
                driver: Driver(
                  firstName: 'Jamie',
                  lastName: 'Driver',
                  licenceNumber: 'LIC-1',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('AB12 CDE'), findsOneWidget);
    expect(find.text('Jamie Driver'), findsOneWidget);
  });
}
