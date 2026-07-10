enum VehicleStatus {
  active,
  workshop,
 offRoad,
  sold,
  disposed,
}

extension VehicleStatusExtension on VehicleStatus {
  String get label {
    switch (this) {
      case VehicleStatus.active:
        return 'Active';
      case VehicleStatus.workshop:
        return 'Workshop';
      case VehicleStatus.offRoad:
        return 'Off Road';
      case VehicleStatus.sold:
        return 'Sold';
      case VehicleStatus.disposed:
        return 'Disposed';
    }
  }
}