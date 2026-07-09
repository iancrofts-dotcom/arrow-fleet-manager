import 'package:flutter/foundation.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/inspection.dart';
import '../models/inspection_draft.dart';
import '../services/inspection_service.dart';

class InspectionViewModel extends ChangeNotifier {
  final InspectionService inspectionService;
  final VehicleService vehicleService;

  late Inspection inspection;

  final InspectionDraft draft = InspectionDraft();

  List<Vehicle> vehicles = [];

  bool loading = false;

  InspectionViewModel({
    required this.inspectionService,
    required this.vehicleService,
  }) {
    inspection = inspectionService.createInspection();
  }

  Future<void> initialise() async {
    loading = true;
    notifyListeners();

    vehicles = await vehicleService.getVehicles();

    loading = false;
    notifyListeners();
  }

  /// Currently selected fleet vehicle
  Vehicle? get selectedVehicle => draft.vehicle;

  /// Convenience getter for the UI
  bool get hasSelectedVehicle => draft.vehicle != null;

  /// Called when the user selects a vehicle
  void selectVehicle(Vehicle? vehicle) {
    draft.vehicle = vehicle;

    inspection = inspection.copyWith(
      vehicleId: vehicle?.id,
      registration: vehicle?.registration ?? '',
    );

    notifyListeners();
  }

  Future<void> save({
    required String inspector,
    required String driver,
    required int mileage,
    required String comments,
  }) async {
    inspection = inspection.copyWith(
      driver: driver,
      inspector: inspector,
      mileage: mileage,
      comments: comments,
      registration:
          draft.vehicle?.registration ?? inspection.registration,
    );

    await inspectionService.saveInspection(inspection);
  }

  bool validate({
    required String inspector,
    required String driver,
  }) {
    inspection = inspection.copyWith(
      inspector: inspector,
      driver: driver,
    );

    return inspectionService.validateInspection(inspection);
  }

  void clearDraft() {
    draft.clear();

    inspection = inspectionService.createInspection();

    notifyListeners();
  }
}