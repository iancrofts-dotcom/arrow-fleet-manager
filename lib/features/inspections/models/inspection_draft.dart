import '../../vehicles/models/vehicle.dart';


class InspectionDraft {
  Vehicle? vehicle;

  String driver;
  int mileage;
  String inspector;
  String comments;

  InspectionDraft({
    this.vehicle,
    this.driver = '',
    this.mileage = 0,
    this.inspector = '',
    this.comments = '',
  });

  bool get hasVehicle => vehicle != null;

  bool get isValid {
    return vehicle != null &&
        inspector.trim().isNotEmpty;
  }

  void clear() {
    vehicle = null;
    driver = '';
    mileage = 0;
    inspector = '';
    comments = '';
  }
}