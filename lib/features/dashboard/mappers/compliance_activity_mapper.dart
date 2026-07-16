import '../../drivers/models/driver.dart';
import '../../drivers/models/driver_compliance.dart';
import '../models/dashboard_activity.dart';

class ComplianceActivityMapper {
  const ComplianceActivityMapper();

  DashboardActivity toActivity({
    required DriverCompliance compliance,
    required Driver driver,
  }) {
    return DashboardActivity(
      title: 'Driver Compliance',
      subtitle:
          'Compliance updated for ${driver.fullName}',
      date: compliance.lastUpdated,
      type: DashboardActivityType.compliance,
    );
  }
}