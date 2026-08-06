import 'package:arrow_fleet_manager/database/database_service.dart';
import 'package:arrow_fleet_manager/database/vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_wizard_data.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';

class InspectionWizardService {
  final DatabaseService _databaseService = DatabaseService();

  late final VehicleRepository _vehicleRepository =
      VehicleRepository(
    databaseService: _databaseService,
  );

  /// Initialise repositories.
  Future<void> initialize() async {
    await _databaseService.initialize();
  }

  /// Returns all active vehicles ordered by fleet number.
  Future<List<Vehicle>> getVehicles() async {
    final vehicles =
        await _vehicleRepository.getVehicles();

    return vehicles.where((v) => v.active).toList();
  }

  /// Copies vehicle information into the wizard.
  void applyVehicle(
    InspectionWizardData data,
    Vehicle vehicle,
  ) {
    data.vehicleId = vehicle.id;
    data.registration = vehicle.registration;
    data.fleetNumber = vehicle.fleetNumber;
  }

  /// Creates a unique inspection number.
  String generateInspectionNumber() {
    final now = DateTime.now();

    return 'WI'
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-${now.millisecondsSinceEpoch}';
  }

  /// Calculates the inspection score.
  int calculateInspectionScore({
    required int totalItems,
    required int failedItems,
  }) {
    if (totalItems == 0) {
      return 0;
    }

    final passed = totalItems - failedItems;

    return ((passed / totalItems) * 100).round();
  }

  /// Determines the inspection result.
  InspectionResult determineResult({
    required int criticalFailures,
    required int repairsRequired,
  }) {
    if (criticalFailures > 0) {
      return InspectionResult.fail;
    }

    if (repairsRequired > 0) {
      return InspectionResult.advisory;
    }

    return InspectionResult.pass;
  }

  /// Determines vehicle roadworthiness.
  VehicleWorkshopStatus determineVehicleStatus({
    required int criticalFailures,
  }) {
    if (criticalFailures > 0) {
      return VehicleWorkshopStatus.notRoadworthy;
    }

    return VehicleWorkshopStatus.roadworthy;
  }
}