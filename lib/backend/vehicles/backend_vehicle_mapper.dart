import '../../features/vehicles/models/vehicle.dart';
import '../../features/vehicles/models/vehicle_identity.dart';
import 'backend_vehicle.dart';

extension BackendVehicleMapper on BackendVehicle {
  Vehicle toAppVehicle() => Vehicle(
    identity: VehicleIdentity.central(id),
    registration: registration,
    fleetNumber: fleetNumber,
    make: make ?? '',
    model: model ?? '',
    year: manufactureYear ?? 0,
    vin: vin ?? '',
    motExpiry: motExpiry,
    serviceDue: serviceDue,
    taxiPlateNumber: taxiPlateNumber,
    taxiLicensingAuthority: taxiLicensingAuthority,
    taxiPlateIssueDate: taxiPlateIssueDate,
    taxiPlateExpiry: taxiPlateExpiry,
    active: isActive,
  );
}
