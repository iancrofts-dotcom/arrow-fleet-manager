import 'package:arrow_fleet_manager/database/database_service.dart';
import 'package:arrow_fleet_manager/database/vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';

import '../models/inspection_wizard_data.dart';

class InspectionWizardController {
  final InspectionWizardData data;

  final DatabaseService _databaseService = DatabaseService();

  late final VehicleRepository _vehicleRepository =
      VehicleRepository(
    databaseService: _databaseService,
  );

  InspectionWizardController({
    required this.data,
  });

  /// Load all active vehicles.
  Future<List<Vehicle>> loadVehicles() async {
    await _databaseService.initialize();

    final vehicles =
        await _vehicleRepository.getVehicles();

    return vehicles.where((v) => v.active).toList();
  }

  /// Store the selected vehicle in the wizard.
  void selectVehicle(Vehicle vehicle) {
    data.vehicleId = vehicle.id;
    data.registration = vehicle.registration;
    data.fleetNumber = vehicle.fleetNumber;
  }

  /// Update mileage.
  void updateMileage(int mileage) {
    data.mileage = mileage;
  }

  /// Returns true when Step 1 is complete.
  bool validateStep1() {
    return data.canContinueFromStep1;
  }

  /// Reset the wizard.
  void reset() {
    data.reset();
  }
}