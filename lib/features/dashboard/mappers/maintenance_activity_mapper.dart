import '../../maintenance/models/maintenance_record.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/dashboard_activity.dart';

class MaintenanceActivityMapper {
  const MaintenanceActivityMapper();

 DashboardActivity toActivity({
  required MaintenanceRecord record,
  required Vehicle vehicle,
}) {
  return DashboardActivity(
    title: 'Maintenance',
    subtitle:
        '${record.title} for ${vehicle.registration}',
    date: record.completedDate ?? record.dueDate,
    type: DashboardActivityType.maintenance,
  );
}
}