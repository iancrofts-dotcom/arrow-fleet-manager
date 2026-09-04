import '../../workshop/models/workshop_inspection.dart';
import '../models/dashboard_activity.dart';

class DriverDailyCheckActivityMapper {
  const DriverDailyCheckActivityMapper();

  DashboardActivity toActivity(WorkshopInspection inspection) {
    final driverName = inspection.driverName?.trim();
    final subject = driverName == null || driverName.isEmpty
        ? inspection.registration
        : '$driverName - ${inspection.registration}';
    final defectsReported =
        inspection.overallResult == InspectionResult.fail ||
        inspection.repairsRequired > 0;

    return DashboardActivity(
      title: 'Daily check completed',
      subtitle: '$subject - ${defectsReported ? 'Defects reported' : 'Passed'}',
      date: inspection.dateCompleted!,
      type: DashboardActivityType.dailyCheck,
      entityId: inspection.id?.toString(),
      driverId: inspection.driverId,
      vehicleId: inspection.vehicleId,
    );
  }
}
