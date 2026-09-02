import '../models/dashboard_kpi.dart';
import '../models/dashboard_summary.dart';

/// Builds dashboard KPI presentation data from the current dashboard load.
///
/// This service deliberately performs no repository work. DashboardService
/// owns the broad load so KPI rendering cannot trigger a second one.
class DashboardKpiService {
  const DashboardKpiService();

  List<DashboardKpi> fromSummary(DashboardSummary summary) {
    return [
      DashboardKpi(
        title: 'Fleet',
        value: summary.vehicleCount.toString(),
        subtitle: 'Registered vehicles',
        icon: 'fleet',
        trend: DashboardKpiTrend.stable,
      ),
      DashboardKpi(
        title: 'Drivers',
        value: summary.driverCount.toString(),
        subtitle: 'Registered drivers',
        icon: 'drivers',
        trend: DashboardKpiTrend.up,
      ),
      DashboardKpi(
        title: 'Compliance',
        value: '${summary.compliancePercentage}%',
        subtitle: 'Fleet compliance',
        icon: 'compliance',
        trend: DashboardKpiTrend.stable,
      ),
      DashboardKpi(
        title: 'Maintenance',
        value: summary.maintenanceRecordCount.toString(),
        subtitle: 'Maintenance records',
        icon: 'maintenance',
        trend: DashboardKpiTrend.stable,
      ),
    ];
  }
}
