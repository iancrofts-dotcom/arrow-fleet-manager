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
      date: _activityDate(compliance),
      type: DashboardActivityType.compliance,
    );
  }

  DateTime _activityDate(
    DriverCompliance compliance,
  ) {
    final dates = <DateTime?>[
      compliance.licenceExpiry,
      compliance.cpcExpiry,
      compliance.medicalExpiry,
    ];

    return dates
            .whereType<DateTime>()
            .fold<DateTime?>(
              null,
              (latest, current) =>
                  latest == null || current.isAfter(latest)
                      ? current
                      : latest,
            ) ??
        DateTime.now();
  }
}