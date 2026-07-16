import '../../dashboard/mappers/compliance_activity_mapper.dart';
import '../../dashboard/models/dashboard_activity.dart';

import '../models/driver_compliance.dart';
import '../repositories/driver_compliance_repository.dart';
import 'driver_service.dart';

class DriverComplianceService {
  DriverComplianceService({
    DriverComplianceRepository? repository,
    DriverService? driverService,
  })  : _repository =
            repository ?? DriverComplianceRepository(),
        _driverService =
            driverService ?? DriverService();

  final DriverComplianceRepository _repository;
  final DriverService _driverService;

  final ComplianceActivityMapper _activityMapper =
      const ComplianceActivityMapper();

  Future<List<DriverCompliance>> getAll() async {
    return _repository.getAll();
  }

  Future<DriverCompliance?> getByDriverId(
    int driverId,
  ) async {
    return _repository.getByDriverId(driverId);
  }

  Future<void> save(
    DriverCompliance compliance,
  ) async {
    await _repository.save(compliance);
  }

  Future<void> delete(
    int driverId,
  ) async {
    await _repository.delete(driverId);
  }

  Future<List<DashboardActivity>>
      getRecentActivities({
    int limit = 5,
  }) async {
    final records = await getAll();

    final drivers =
        await _driverService.getDriverMap();

    final activities = <DashboardActivity>[];

    for (final record in records) {
      final driver =
          drivers[record.driverId];

      if (driver == null) {
        continue;
      }

      activities.add(
        _activityMapper.toActivity(
          compliance: record,
          driver: driver,
        ),
      );
    }

    activities.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return activities.take(limit).toList();
  }
    bool isExpired(DateTime expiryDate) {
    return expiryDate.isBefore(DateTime.now());
  }

  bool isDueSoon(
    DateTime expiryDate, {
    int warningDays = 30,
  }) {
    final today = DateTime.now();

    if (expiryDate.isBefore(today)) {
      return false;
    }

    return expiryDate
            .difference(today)
            .inDays <=
        warningDays;
  }

  int daysRemaining(
    DateTime expiryDate,
  ) {
    return expiryDate
        .difference(DateTime.now())
        .inDays;
  }

  String status(
    DateTime expiryDate,
  ) {
    if (isExpired(expiryDate)) {
      return 'Expired';
    }

    if (isDueSoon(expiryDate)) {
      return 'Due Soon';
    }

    return 'Valid';
  }

  List<DriverCompliance> expiringSoon(
    List<DriverCompliance> records,
  ) {
    return records.where((record) {
      return isDueSoon(record.licenceExpiry) ||
          isDueSoon(record.cpcExpiry) ||
          isDueSoon(record.medicalExpiry);
    }).toList();
  }

  List<DriverCompliance> expired(
    List<DriverCompliance> records,
  ) {
    return records.where((record) {
      return isExpired(record.licenceExpiry) ||
          isExpired(record.cpcExpiry) ||
          isExpired(record.medicalExpiry);
    }).toList();
  }
}