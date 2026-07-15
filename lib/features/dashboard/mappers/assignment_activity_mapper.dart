import '../../drivers/models/driver.dart';
import '../../drivers/models/driver_vehicle_assignment.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/dashboard_activity.dart';

class AssignmentActivityMapper {
  const AssignmentActivityMapper();

  DashboardActivity toActivity({
    required DriverVehicleAssignment assignment,
    required Driver driver,
    required Vehicle vehicle,
  }) {
    return DashboardActivity(
      title: 'Driver Assigned',
      subtitle:
          '${driver.fullName} assigned to ${vehicle.registration}',
      date: assignment.assignedFrom,
      type: DashboardActivityType.assignment,
    );
  }
}