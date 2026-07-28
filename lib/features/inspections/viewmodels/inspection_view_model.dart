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

  /// Currently selected vehicle
  Vehicle? get selectedVehicle => draft.vehicle;

  bool get hasSelectedVehicle =>
      draft.vehicle != null;

  void selectVehicle(
    Vehicle? vehicle,
  ) {
    draft.vehicle = vehicle;

    inspection = inspection.copyWith(
      vehicleId: vehicle?.id,
      registration:
          vehicle?.registration ?? '',
    );

    notifyListeners();
  }

  Future<void> save({
    required String driver,
    required int mileage,
    required String comments,
  }) async {
    inspection = inspection.copyWith(
      driver: driver,
      mileage: mileage,
      comments: comments,
      registration:
          draft.vehicle?.registration ??
          inspection.registration,
    );

    await inspectionService.saveInspection(
      inspection,
    );
  }  bool validate({
    required String driver,
  }) {
    inspection = inspection.copyWith(
      driver: driver,
      registration:
          draft.vehicle?.registration ??
          inspection.registration,
      vehicleId: draft.vehicle?.id,
    );

    return inspectionService.validateInspection(
      inspection,
    );
  }

  void clearDraft() {
    draft.clear();

    inspection =
        inspectionService.createInspection();

    notifyListeners();
  }
}