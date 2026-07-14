import '../models/maintenance_record.dart';
import '../repositories/maintenance_repository.dart';

class MaintenanceService {
  MaintenanceService({
    MaintenanceRepository? repository,
  }) : _repository =
            repository ?? MaintenanceRepository();

  final MaintenanceRepository _repository;

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

  List<MaintenanceRecord> overdue(
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