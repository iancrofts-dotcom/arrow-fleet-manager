import '../../drivers/models/driver.dart';
import 'vehicle.dart';

class EditVehicleResult {
  const EditVehicleResult({
    required this.vehicle,
    this.assignedDriver,
  });

  final Vehicle vehicle;
  final Driver? assignedDriver;

  bool get hasAssignedDriver =>
      assignedDriver != null;
}