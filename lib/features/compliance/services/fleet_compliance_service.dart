import '../../drivers/models/driver.dart';
import '../../drivers/models/driver_compliance.dart';
import '../../drivers/services/driver_compliance_service.dart';
import '../../drivers/services/driver_service.dart';
import '../../vehicles/models/vehicle.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/fleet_compliance_summary.dart';

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
      final secondary = vehicle.fleetNumber.isEmpty
          ? null
          : vehicle.fleetNumber;
      builder.add(
        subjectType: FleetComplianceSubjectType.vehicle,
        subjectId: vehicleId,
        subjectDisplay: vehicle.registration,
        secondaryDisplay: secondary,
        checkType: vehicle.motType == 'psv'
            ? FleetComplianceCheckType.psvMot
            : FleetComplianceCheckType.mot,
        date: vehicle.motExpiry,
      );
      builder.add(
        subjectType: FleetComplianceSubjectType.vehicle,
        subjectId: vehicleId,
        subjectDisplay: vehicle.registration,
        secondaryDisplay: secondary,
        checkType: FleetComplianceCheckType.service,
        date: vehicle.serviceDue,
      );
      if (vehicle.taxiPlateNumber != null || vehicle.taxiPlateExpiry != null) {
        builder.addOptional(
          subjectType: FleetComplianceSubjectType.vehicle,
          subjectId: vehicleId,
          subjectDisplay: vehicle.registration,
          secondaryDisplay: vehicle.taxiPlateNumber ?? secondary,
          checkType: FleetComplianceCheckType.taxiPlate,
          date: vehicle.taxiPlateExpiry,
        );
      }
      if (vehicle.psvGarageCheckEnabled) {
        builder.add(
          subjectType: FleetComplianceSubjectType.vehicle,
          subjectId: vehicleId,
          subjectDisplay: vehicle.registration,
          secondaryDisplay:
              '${vehicle.psvGarageCheckIntervalWeeks}-week schedule',
          checkType: FleetComplianceCheckType.psvGarageCheck,
          date: vehicle.psvGarageCheckDue,
        );
      }
      if (vehicle.taxiSafetyCheckEnabled) {
        builder.add(
          subjectType: FleetComplianceSubjectType.vehicle,
          subjectId: vehicleId,
          subjectDisplay: vehicle.registration,
          secondaryDisplay:
              '${vehicle.taxiSafetyCheckIntervalWeeks}-week schedule',
          checkType: FleetComplianceCheckType.taxiSafetyCheck,
          date: vehicle.taxiSafetyCheckDue,
        );
      }
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
      if (compliance?.taxiLicenceExpiry != null) {
        builder.addOptional(
          subjectType: FleetComplianceSubjectType.driver,
          subjectId: driverId,
          subjectDisplay: driver.fullName,
          checkType: FleetComplianceCheckType.taxiLicence,
          date: compliance?.taxiLicenceExpiry,
        );
      }
    }

    return builder.build();
  }
}

class _SummaryBuilder {
  _SummaryBuilder(DateTime now) : now = DateTime(now.year, now.month, now.day);

  final DateTime now;
  final List<FleetComplianceAttentionItem> allItems = [];
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
    final item = FleetComplianceAttentionItem(
      subjectType: subjectType,
      subjectId: subjectId,
      checkType: checkType,
      status: status,
      date: date,
      subjectDisplay: subjectDisplay,
      secondaryDisplay: secondaryDisplay,
    );
    allItems.add(item);
    if (status != FleetComplianceStatus.valid) attentionItems.add(item);
  }

  void addOptional({
    required FleetComplianceSubjectType subjectType,
    required int subjectId,
    required String subjectDisplay,
    String? secondaryDisplay,
    required FleetComplianceCheckType checkType,
    required DateTime? date,
  }) {
    final status = _classify(date, now);
    final item = FleetComplianceAttentionItem(
      subjectType: subjectType,
      subjectId: subjectId,
      checkType: checkType,
      status: status,
      date: date,
      subjectDisplay: subjectDisplay,
      secondaryDisplay: secondaryDisplay,
    );
    allItems.add(item);
    if (status == FleetComplianceStatus.dueSoon ||
        status == FleetComplianceStatus.expired) {
      attentionItems.add(item);
    }
  }

  FleetComplianceSummary build() {
    attentionItems.sort(_compareItems);
    allItems.sort(_compareItems);
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
      allItems: allItems,
    );
  }
}

FleetComplianceStatus _classify(DateTime? date, DateTime now) {
  if (date == null) return FleetComplianceStatus.notRecorded;
  final day = DateTime(date.year, date.month, date.day);
  if (day.isBefore(now)) return FleetComplianceStatus.expired;
  if (day.difference(now).inDays <= FleetComplianceService.dueSoonDays) {
    return FleetComplianceStatus.dueSoon;
  }
  return FleetComplianceStatus.valid;
}

int _compareItems(
  FleetComplianceAttentionItem left,
  FleetComplianceAttentionItem right,
) {
  final severity = _priority(left.status).compareTo(_priority(right.status));
  if (severity != 0) return severity;
  final leftDate = left.date;
  final rightDate = right.date;
  if (leftDate != null && rightDate != null) {
    final date = leftDate.compareTo(rightDate);
    if (date != 0) return date;
  }
  final subject = left.subjectDisplay.compareTo(right.subjectDisplay);
  if (subject != 0) return subject;
  return left.checkType.index.compareTo(right.checkType.index);
}

int _priority(FleetComplianceStatus status) => switch (status) {
  FleetComplianceStatus.expired => 0,
  FleetComplianceStatus.notRecorded => 1,
  FleetComplianceStatus.dueSoon => 2,
  FleetComplianceStatus.valid => 3,
};
