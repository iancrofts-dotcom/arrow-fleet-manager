import '../features/compliance/models/fleet_compliance_summary.dart';
import 'drivers/backend_driver_repository.dart';
import 'drivers/central_driver_compliance_repository.dart';
import 'drivers/supabase_driver_gateway.dart';
import 'drivers/supabase_driver_compliance_gateway.dart';
import 'vehicles/backend_vehicle_repository.dart';
import 'vehicles/supabase_vehicle_gateway.dart';

class CentralComplianceParityService {
  CentralComplianceParityService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  static const dueSoonDays = 30;

  Future<FleetComplianceSummary> loadSummary() async {
    final vehicles = await BackendVehicleRepository(
      SupabaseVehicleGateway(),
    ).listVehicles();
    final drivers = await BackendDriverRepository(
      SupabaseDriverGateway(),
    ).listDrivers();
    final complianceRecords = await const CentralDriverComplianceRepository(
      SupabaseDriverComplianceGateway(),
    ).listCompliance();
    final complianceByDriver = {
      for (final compliance in complianceRecords)
        compliance.driverId: compliance,
    };
    final builder = _CentralComplianceBuilder(_now());
    var syntheticId = 1;

    for (final vehicle in vehicles.where((item) => item.isActive)) {
      final secondary = vehicle.fleetNumber.isEmpty
          ? null
          : vehicle.fleetNumber;
      builder.add(
        subjectType: FleetComplianceSubjectType.vehicle,
        subjectId: syntheticId++,
        centralSubjectId: vehicle.id,
        subjectDisplay: vehicle.registration,
        secondaryDisplay: secondary,
        checkType: vehicle.motType == 'psv'
            ? FleetComplianceCheckType.psvMot
            : FleetComplianceCheckType.mot,
        date: vehicle.motExpiry,
      );
      builder.add(
        subjectType: FleetComplianceSubjectType.vehicle,
        subjectId: syntheticId++,
        centralSubjectId: vehicle.id,
        subjectDisplay: vehicle.registration,
        secondaryDisplay: secondary,
        checkType: FleetComplianceCheckType.service,
        date: vehicle.serviceDue,
      );
      if (vehicle.taxiPlateNumber != null || vehicle.taxiPlateExpiry != null) {
        builder.addOptional(
          subjectType: FleetComplianceSubjectType.vehicle,
          subjectId: syntheticId++,
          centralSubjectId: vehicle.id,
          subjectDisplay: vehicle.registration,
          secondaryDisplay: vehicle.taxiPlateNumber ?? secondary,
          checkType: FleetComplianceCheckType.taxiPlate,
          date: vehicle.taxiPlateExpiry,
        );
      }
      if (vehicle.psvGarageCheckEnabled) {
        builder.add(
          subjectType: FleetComplianceSubjectType.vehicle,
          subjectId: syntheticId++,
          centralSubjectId: vehicle.id,
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
          subjectId: syntheticId++,
          centralSubjectId: vehicle.id,
          subjectDisplay: vehicle.registration,
          secondaryDisplay:
              '${vehicle.taxiSafetyCheckIntervalWeeks}-week schedule',
          checkType: FleetComplianceCheckType.taxiSafetyCheck,
          date: vehicle.taxiSafetyCheckDue,
        );
      }
    }

    for (final driver in drivers.where((item) => item.isActive)) {
      final compliance = complianceByDriver[driver.id];
      final driverName = '${driver.firstName} ${driver.lastName}'.trim();
      for (final check in <(FleetComplianceCheckType, DateTime?, String?)>[
        (
          FleetComplianceCheckType.licence,
          compliance?.licenceExpiry ?? driver.licenceExpiry,
          driver.licenceNumber,
        ),
        (FleetComplianceCheckType.cpc, compliance?.cpcExpiry, null),
        (FleetComplianceCheckType.medical, compliance?.medicalExpiry, null),
        (FleetComplianceCheckType.dbs, compliance?.dbsExpiry, null),
      ]) {
        builder.add(
          subjectType: FleetComplianceSubjectType.driver,
          subjectId: syntheticId++,
          centralSubjectId: driver.id,
          subjectDisplay: driverName,
          secondaryDisplay: check.$3,
          checkType: check.$1,
          date: check.$2,
        );
      }
      if (compliance?.taxiLicenceNumber != null ||
          compliance?.taxiLicenceExpiry != null) {
        builder.addOptional(
          subjectType: FleetComplianceSubjectType.driver,
          subjectId: syntheticId++,
          centralSubjectId: driver.id,
          subjectDisplay: driverName,
          secondaryDisplay: compliance?.taxiLicenceNumber,
          checkType: FleetComplianceCheckType.taxiLicence,
          date: compliance?.taxiLicenceExpiry,
        );
      }
    }

    return builder.build();
  }
}

class _CentralComplianceBuilder {
  _CentralComplianceBuilder(DateTime now)
    : today = DateTime(now.year, now.month, now.day);

  final DateTime today;
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
    required String centralSubjectId,
    required String subjectDisplay,
    String? secondaryDisplay,
    required FleetComplianceCheckType checkType,
    required DateTime? date,
  }) {
    final status = _classify(date);
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
      centralSubjectId: centralSubjectId,
      checkType: checkType,
      status: status,
      date: date,
      subjectDisplay: subjectDisplay,
      secondaryDisplay: secondaryDisplay,
    );
    allItems.add(item);
    if (status != FleetComplianceStatus.valid) attentionItems.add(item);
  }

  FleetComplianceStatus _classify(DateTime? date) {
    if (date == null) return FleetComplianceStatus.notRecorded;
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(today)) return FleetComplianceStatus.expired;
    if (day.difference(today).inDays <=
        CentralComplianceParityService.dueSoonDays) {
      return FleetComplianceStatus.dueSoon;
    }
    return FleetComplianceStatus.valid;
  }

  void addOptional({
    required FleetComplianceSubjectType subjectType,
    required int subjectId,
    required String centralSubjectId,
    required String subjectDisplay,
    String? secondaryDisplay,
    required FleetComplianceCheckType checkType,
    required DateTime? date,
  }) {
    final status = _classify(date);
    final item = FleetComplianceAttentionItem(
      subjectType: subjectType,
      subjectId: subjectId,
      centralSubjectId: centralSubjectId,
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
    int compare(
      FleetComplianceAttentionItem left,
      FleetComplianceAttentionItem right,
    ) {
      final severity = _priority(
        left.status,
      ).compareTo(_priority(right.status));
      if (severity != 0) return severity;
      final leftDate = left.date;
      final rightDate = right.date;
      if (leftDate != null && rightDate != null) {
        final byDate = leftDate.compareTo(rightDate);
        if (byDate != 0) return byDate;
      }
      final bySubject = left.subjectDisplay.compareTo(right.subjectDisplay);
      if (bySubject != 0) return bySubject;
      return left.checkType.index.compareTo(right.checkType.index);
    }

    attentionItems.sort(compare);
    allItems.sort(compare);
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

int _priority(FleetComplianceStatus status) => switch (status) {
  FleetComplianceStatus.expired => 0,
  FleetComplianceStatus.notRecorded => 1,
  FleetComplianceStatus.dueSoon => 2,
  FleetComplianceStatus.valid => 3,
};
