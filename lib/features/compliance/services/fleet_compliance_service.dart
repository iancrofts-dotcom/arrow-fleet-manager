import '../../drivers/models/driver.dart';
import '../../drivers/models/driver_compliance.dart';
import '../../drivers/services/driver_compliance_service.dart';
import '../../drivers/services/driver_service.dart';
import '../../vehicles/models/vehicle.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/fleet_compliance_summary.dart';

/// Builds one authoritative, Dashboard-compatible fleet compliance summary.
class FleetComplianceService {
  FleetComplianceService({
    VehicleService? vehicleService,
    DriverService? driverService,
    DriverComplianceService? driverComplianceService,
    Future<List<Vehicle>> Function()? loadVehicles,
    Future<List<Driver>> Function()? loadDrivers,
    Future<List<DriverCompliance>> Function()? loadDriverCompliance,
    DateTime Function()? now,
  }) : _loadVehicles =
           loadVehicles ?? (vehicleService ?? VehicleService()).getVehicles,
       _loadDrivers =
           loadDrivers ?? (driverService ?? DriverService()).getDrivers,
       _loadDriverCompliance =
           loadDriverCompliance ??
           (driverComplianceService ?? DriverComplianceService()).getAll,
       _now = now ?? DateTime.now;

  static const int dueSoonDays = 30;

  final Future<List<Vehicle>> Function() _loadVehicles;
  final Future<List<Driver>> Function() _loadDrivers;
  final Future<List<DriverCompliance>> Function() _loadDriverCompliance;
  final DateTime Function() _now;

  Future<FleetComplianceSummary> loadSummary() async {
    final sources = await Future.wait([
      _loadVehicles(),
      _loadDrivers(),
      _loadDriverCompliance(),
    ]);
    return summarize(
      vehicles: sources[0] as List<Vehicle>,
      drivers: sources[1] as List<Driver>,
      complianceRecords: sources[2] as List<DriverCompliance>,
      now: _now(),
    );
  }

  FleetComplianceSummary summarize({
    required List<Vehicle> vehicles,
    required List<Driver> drivers,
    required List<DriverCompliance> complianceRecords,
    required DateTime now,
  }) {
    final builder = _SummaryBuilder(now);
    final complianceByDriver = {
      for (final compliance in complianceRecords)
        compliance.driverId: compliance,
    };

    for (final vehicle in vehicles.where((vehicle) => vehicle.active)) {
      final vehicleId = vehicle.id;
      if (vehicleId == null) {
        throw StateError('Active vehicle is missing a persisted ID.');
      }
      builder.add(
        subjectType: FleetComplianceSubjectType.vehicle,
        subjectId: vehicleId,
        subjectDisplay: vehicle.registration,
        secondaryDisplay: vehicle.fleetNumber.isEmpty
            ? null
            : vehicle.fleetNumber,
        checkType: FleetComplianceCheckType.mot,
        date: vehicle.motExpiry,
      );
      builder.add(
        subjectType: FleetComplianceSubjectType.vehicle,
        subjectId: vehicleId,
        subjectDisplay: vehicle.registration,
        secondaryDisplay: vehicle.fleetNumber.isEmpty
            ? null
            : vehicle.fleetNumber,
        checkType: FleetComplianceCheckType.service,
        date: vehicle.serviceDue,
      );
    }

    for (final driver in drivers.where((driver) => driver.isActive)) {
      final driverId = driver.id;
      if (driverId == null) {
        throw StateError('Active driver is missing a persisted ID.');
      }
      final compliance = complianceByDriver[driverId];
      for (final check in <(FleetComplianceCheckType, DateTime?)>[
        (FleetComplianceCheckType.licence, compliance?.licenceExpiry),
        (FleetComplianceCheckType.cpc, compliance?.cpcExpiry),
        (FleetComplianceCheckType.medical, compliance?.medicalExpiry),
        (FleetComplianceCheckType.dbs, compliance?.dbsExpiry),
      ]) {
        builder.add(
          subjectType: FleetComplianceSubjectType.driver,
          subjectId: driverId,
          subjectDisplay: driver.fullName,
          checkType: check.$1,
          date: check.$2,
        );
      }
    }

    return builder.build();
  }
}

class _SummaryBuilder {
  _SummaryBuilder(this.now);

  final DateTime now;
  final List<FleetComplianceAttentionItem> attentionItems = [];
  var totalChecks = 0;
  var compliantChecks = 0;
  var validCount = 0;
  var dueSoonCount = 0;
  var expiredCount = 0;
  var notRecordedCount = 0;
  var vehicleCheckCount = 0;
  var driverCheckCount = 0;

  void add({
    required FleetComplianceSubjectType subjectType,
    required int subjectId,
    required String subjectDisplay,
    String? secondaryDisplay,
    required FleetComplianceCheckType checkType,
    required DateTime? date,
  }) {
    final status = _classify(date, now);
    totalChecks++;
    if (subjectType == FleetComplianceSubjectType.vehicle) {
      vehicleCheckCount++;
    } else {
      driverCheckCount++;
    }

    switch (status) {
      case FleetComplianceStatus.valid:
        validCount++;
        compliantChecks++;
        break;
      case FleetComplianceStatus.dueSoon:
        dueSoonCount++;
        compliantChecks++;
        break;
      case FleetComplianceStatus.expired:
        expiredCount++;
        break;
      case FleetComplianceStatus.notRecorded:
        notRecordedCount++;
        break;
    }

    if (status != FleetComplianceStatus.valid) {
      attentionItems.add(
        FleetComplianceAttentionItem(
          subjectType: subjectType,
          subjectId: subjectId,
          checkType: checkType,
          status: status,
          date: date,
          subjectDisplay: subjectDisplay,
          secondaryDisplay: secondaryDisplay,
        ),
      );
    }
  }

  FleetComplianceSummary build() {
    attentionItems.sort(_compareAttentionItems);
    return FleetComplianceSummary(
      compliancePercentage: totalChecks == 0
          ? 100
          : ((compliantChecks / totalChecks) * 100).round(),
      totalChecks: totalChecks,
      compliantChecks: compliantChecks,
      validCount: validCount,
      dueSoonCount: dueSoonCount,
      expiredCount: expiredCount,
      notRecordedCount: notRecordedCount,
      vehicleCheckCount: vehicleCheckCount,
      driverCheckCount: driverCheckCount,
      attentionItems: attentionItems,
    );
  }
}

FleetComplianceStatus _classify(DateTime? date, DateTime now) {
  if (date == null) {
    return FleetComplianceStatus.notRecorded;
  }
  if (date.isBefore(now)) {
    return FleetComplianceStatus.expired;
  }
  if (date.difference(now).inDays <= FleetComplianceService.dueSoonDays) {
    return FleetComplianceStatus.dueSoon;
  }
  return FleetComplianceStatus.valid;
}

int _compareAttentionItems(
  FleetComplianceAttentionItem left,
  FleetComplianceAttentionItem right,
) {
  final severity = _attentionPriority(
    left.status,
  ).compareTo(_attentionPriority(right.status));
  if (severity != 0) {
    return severity;
  }
  if (left.date != null && right.date != null) {
    final date = left.date!.compareTo(right.date!);
    if (date != 0) {
      return date;
    }
  }
  final subject = left.subjectDisplay.compareTo(right.subjectDisplay);
  if (subject != 0) {
    return subject;
  }
  final check = left.checkType.index.compareTo(right.checkType.index);
  if (check != 0) {
    return check;
  }
  return left.subjectId.compareTo(right.subjectId);
}

int _attentionPriority(FleetComplianceStatus status) {
  switch (status) {
    case FleetComplianceStatus.expired:
      return 0;
    case FleetComplianceStatus.notRecorded:
      return 1;
    case FleetComplianceStatus.dueSoon:
      return 2;
    case FleetComplianceStatus.valid:
      return 3;
  }
}
