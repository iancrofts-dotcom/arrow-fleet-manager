import '../../dashboard/mappers/maintenance_activity_mapper.dart';
import '../../dashboard/models/dashboard_activity.dart';
import '../../vehicles/services/vehicle_service.dart';

import '../models/maintenance_record.dart';
import '../repositories/maintenance_repository.dart';

class MaintenanceService {
  MaintenanceService({
    MaintenanceRepository? repository,
    VehicleService? vehicleService,
  })  : _repository =
            repository ?? MaintenanceRepository(),
        _vehicleService =
            vehicleService ?? VehicleService();

  final MaintenanceRepository _repository;
  final VehicleService _vehicleService;

  final MaintenanceActivityMapper _activityMapper =
      const MaintenanceActivityMapper();

  Future<List<MaintenanceRecord>> getAll() async {
    return _repository.getAll();
  }

  Future<List<MaintenanceRecord>> getForVehicle(
    int vehicleId,
  ) async {
    return _repository.getForVehicle(vehicleId);
  }

  Future<void> save(
    MaintenanceRecord record,
  ) async {
    await _repository.save(record);
  }

  Future<void> delete(
    int id,
  ) async {
    await _repository.delete(id);
  }

  Future<List<DashboardActivity>>
      getRecentActivities({
    int limit = 5,
  }) async {
    final records = await getAll();

    final vehicles =
        await _vehicleService.getVehicleMap();

    final activities = <DashboardActivity>[];

    for (final record in records) {
      final vehicle =
          vehicles[record.vehicleId];

      if (vehicle == null) {
        continue;
      }

      activities.add(
        _activityMapper.toActivity(
          record: record,
          vehicle: vehicle,
        ),
      );
    }

    activities.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return activities.take(limit).toList();
  }  List<MaintenanceRecord> overdue(
    List<MaintenanceRecord> records,
  ) {
    return records
        .where((record) => record.isOverdue)
        .toList();
  }

  List<MaintenanceRecord> dueSoon(
    List<MaintenanceRecord> records, {
    int warningDays = 30,
  }) {
    return records.where((record) {
      return !record.completed &&
          record.daysRemaining >= 0 &&
          record.daysRemaining <= warningDays;
    }).toList();
  }

  List<MaintenanceRecord> completed(
    List<MaintenanceRecord> records,
  ) {
    return records
        .where((record) => record.completed)
        .toList();
  }

  double totalEstimatedCost(
    List<MaintenanceRecord> records,
  ) {
    return records.fold(
      0,
      (sum, record) =>
          sum + record.estimatedCost,
    );
  }

  double totalActualCost(
    List<MaintenanceRecord> records,
  ) {
    return records.fold(
      0,
      (sum, record) =>
          sum + (record.actualCost ?? 0),
    );
  }
}