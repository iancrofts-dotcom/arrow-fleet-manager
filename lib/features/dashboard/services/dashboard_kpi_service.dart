import '../../../database/vehicle_repository.dart';
import '../../../database/database_service.dart'; 
import '../../drivers/repositories/driver_repository.dart';
import '../../maintenance/repositories/maintenance_repository.dart';
import '../models/dashboard_kpi.dart';

class DashboardKpiService {
  DashboardKpiService({
    DriverRepository? driverRepository,
    MaintenanceRepository? maintenanceRepository,
    VehicleRepository? vehicleRepository,
  })  : _driverRepository =
            driverRepository ?? DriverRepository(),
        _maintenanceRepository =
            maintenanceRepository ?? MaintenanceRepository(),
            _vehicleRepository =
          vehicleRepository ??
              VehicleRepository(
                databaseService: DatabaseService(),
              );

  final DriverRepository _driverRepository;
  final MaintenanceRepository _maintenanceRepository;
  final VehicleRepository _vehicleRepository;
  Future<List<DashboardKpi>> getKpis() async {
    final drivers = await _driverRepository.getAllDrivers();
    final maintenance = await _maintenanceRepository.getAll();

    // Temporary values until the remaining repositories are connected.
   final fleetCount =
    await _vehicleRepository.getVehicleCount();
    const int compliancePercentage = 100;

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