import '../../../database/vehicle_repository.dart';
import '../../../database/database_service.dart'; 
import '../../drivers/repositories/driver_repository.dart';
import '../../maintenance/repositories/maintenance_repository.dart';
import '../../drivers/repositories/driver_compliance_repository.dart';
import '../models/dashboard_kpi.dart';

class DashboardKpiService {
  DashboardKpiService({
    DriverRepository? driverRepository,
    MaintenanceRepository? maintenanceRepository,
    VehicleRepository? vehicleRepository,
    DriverComplianceRepository? complianceRepository,
  })  : _driverRepository =
            driverRepository ?? DriverRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? MaintenanceRepository(),
            _vehicleRepository =
          vehicleRepository ??
              VehicleRepository(
                databaseService: DatabaseService(),
              ),
        _complianceRepository =
            complianceRepository ?? DriverComplianceRepository();

  final DriverRepository _driverRepository;
  final MaintenanceRepository _maintenanceRepository;
  final VehicleRepository _vehicleRepository;
  final DriverComplianceRepository _complianceRepository;
  Future<List<DashboardKpi>> getKpis() async {
    final drivers = await _driverRepository.getAllDrivers();
    final maintenance = await _maintenanceRepository.getAll();

    final vehicles = await _vehicleRepository.getVehicles();
    final complianceRecords = await _complianceRepository.getAll();
    final complianceByDriver = {
      for (final record in complianceRecords) record.driverId: record,
    };
    final now = DateTime.now();
    var requiredChecks = 0;
    var compliantChecks = 0;

    for (final vehicle in vehicles.where((vehicle) => vehicle.active)) {
      for (final date in [vehicle.motExpiry, vehicle.serviceDue]) {
        requiredChecks++;
        if (date != null && !date.isBefore(now)) {
          compliantChecks++;
        }
      }
    }

    for (final driver in drivers.where((driver) => driver.isActive)) {
      final record = driver.id == null ? null : complianceByDriver[driver.id!];
      for (final date in [
        record?.licenceExpiry,
        record?.cpcExpiry,
        record?.medicalExpiry,
        record?.dbsExpiry,
      ]) {
        requiredChecks++;
        if (date != null && !date.isBefore(now)) {
          compliantChecks++;
        }
      }
    }

    // No active assets or drivers have compliance checks to score.
    final compliancePercentage = requiredChecks == 0
        ? 100
        : ((compliantChecks / requiredChecks) * 100).round();
    final fleetCount = vehicles.length;

    return [
      DashboardKpi(
        title: 'Fleet',
        value: fleetCount.toString(),
        subtitle: 'Registered vehicles',
        icon: 'fleet',
        trend: DashboardKpiTrend.stable,
      ),
      DashboardKpi(
        title: 'Drivers',
        value: drivers.length.toString(),
        subtitle: 'Active drivers',
        icon: 'drivers',
        trend: DashboardKpiTrend.up,
      ),
      DashboardKpi(
        title: 'Compliance',
        value: '$compliancePercentage%',
        subtitle: 'Fleet compliance',
        icon: 'compliance',
        trend: DashboardKpiTrend.stable,
      ),
      DashboardKpi(
        title: 'Maintenance',
        value: maintenance.length.toString(),
        subtitle: 'Maintenance records',
        icon: 'maintenance',
        trend: DashboardKpiTrend.stable,
      ),
    ];
  }
}
