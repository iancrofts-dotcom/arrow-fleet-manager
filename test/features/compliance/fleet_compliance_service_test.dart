import 'package:arrow_fleet_manager/features/compliance/models/fleet_compliance_summary.dart';
import 'package:arrow_fleet_manager/features/compliance/services/fleet_compliance_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_compliance.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 1, 15, 12);

void main() {
  test(
    'no active subjects produces the Dashboard-compatible 100% score',
    () async {
      final summary = await _summary();

      expect(summary.compliancePercentage, 100);
      expect(summary.totalChecks, 0);
      expect(summary.attentionItems, isEmpty);
    },
  );

  test(
    'an active vehicle with valid MOT and service is fully compliant',
    () async {
      final summary = await _summary(vehicles: [_vehicle()]);

      expect(summary.compliancePercentage, 100);
      expect(summary.vehicleCheckCount, 2);
      expect(summary.validCount, 2);
    },
  );

  test(
    'a missing vehicle MOT is not recorded and fails the numerator',
    () async {
      final summary = await _summary(vehicles: [_vehicle(missingMot: true)]);

      expect(summary.compliancePercentage, 50);
      expect(summary.notRecordedCount, 1);
      expect(
        summary.attentionItems.single.status,
        FleetComplianceStatus.notRecorded,
      );
      expect(
        summary.attentionItems.single.checkType,
        FleetComplianceCheckType.mot,
      );
    },
  );

  test('an expired vehicle MOT is expired and fails the numerator', () async {
    final summary = await _summary(
      vehicles: [_vehicle(motExpiry: _now.subtract(const Duration(days: 1)))],
    );

    expect(summary.compliancePercentage, 50);
    expect(summary.expiredCount, 1);
    expect(summary.attentionItems.single.status, FleetComplianceStatus.expired);
  });

  test('a due-soon vehicle MOT remains Dashboard-compliant', () async {
    final summary = await _summary(
      vehicles: [_vehicle(motExpiry: _now.add(const Duration(days: 30)))],
    );

    expect(summary.compliancePercentage, 100);
    expect(summary.dueSoonCount, 1);
  });

  test('inactive vehicles are excluded completely', () async {
    final summary = await _summary(vehicles: [_vehicle(active: false)]);

    expect(summary.totalChecks, 0);
    expect(summary.compliancePercentage, 100);
  });

  test('an active driver with four valid checks is fully compliant', () async {
    final summary = await _summary(
      drivers: [_driver()],
      compliance: [_compliance()],
    );

    expect(summary.driverCheckCount, 4);
    expect(summary.validCount, 4);
    expect(summary.compliancePercentage, 100);
  });

  test(
    'a missing DriverCompliance record produces four not-recorded checks',
    () async {
      final summary = await _summary(drivers: [_driver()]);

      expect(summary.totalChecks, 4);
      expect(summary.notRecordedCount, 4);
      expect(summary.compliancePercentage, 0);
    },
  );

  test('an expired driver check is expired', () async {
    final summary = await _summary(
      drivers: [_driver()],
      compliance: [
        _compliance(licenceExpiry: _now.subtract(const Duration(days: 1))),
      ],
    );

    expect(summary.expiredCount, 1);
    expect(summary.compliancePercentage, 75);
  });

  test('a due-soon driver check remains Dashboard-compliant', () async {
    final summary = await _summary(
      drivers: [_driver()],
      compliance: [_compliance(cpcExpiry: _now.add(const Duration(days: 7)))],
    );

    expect(summary.dueSoonCount, 1);
    expect(summary.compliancePercentage, 100);
  });

  test('inactive drivers are excluded completely', () async {
    final summary = await _summary(
      drivers: [_driver(active: false)],
      compliance: [_compliance()],
    );

    expect(summary.totalChecks, 0);
    expect(summary.compliancePercentage, 100);
  });

  test('an absent DBS is required, not recorded, and non-compliant', () async {
    final summary = await _summary(
      drivers: [_driver()],
      compliance: [_compliance(missingDbs: true)],
    );

    expect(summary.notRecordedCount, 1);
    expect(summary.compliancePercentage, 75);
    expect(
      summary.attentionItems.single.checkType,
      FleetComplianceCheckType.dbs,
    );
  });

  test(
    'DriverCompliance licence date is authoritative over Driver licence date',
    () async {
      final summary = await _summary(
        drivers: [
          _driver(licenceExpiry: _now.subtract(const Duration(days: 1))),
        ],
        compliance: [_compliance()],
      );

      expect(summary.compliancePercentage, 100);
      expect(summary.expiredCount, 0);
    },
  );

  test('mixed checks round exactly like the Dashboard percentage', () async {
    final summary = await _summary(
      vehicles: [_vehicle(missingMot: true)],
      drivers: [_driver()],
      compliance: [_compliance(missingDbs: true)],
    );

    // 4 compliant checks out of 6 required checks rounds to 67%.
    expect(summary.compliantChecks, 4);
    expect(summary.totalChecks, 6);
    expect(summary.compliancePercentage, 67);
  });

  test('status and subject counts partition the total checks', () async {
    final summary = await _summary(
      vehicles: [
        _vehicle(
          motExpiry: _now.subtract(const Duration(days: 1)),
          missingService: true,
        ),
      ],
      drivers: [_driver()],
      compliance: [
        _compliance(
          cpcExpiry: _now.add(const Duration(days: 1)),
          dbsExpiry: null,
        ),
      ],
    );

    expect(
      summary.validCount +
          summary.dueSoonCount +
          summary.expiredCount +
          summary.notRecordedCount,
      summary.totalChecks,
    );
    expect(
      summary.vehicleCheckCount + summary.driverCheckCount,
      summary.totalChecks,
    );
  });

  test(
    'attention excludes valid checks and retains stable subject IDs',
    () async {
      final summary = await _summary(
        vehicles: [_vehicle(id: 11, missingMot: true)],
        drivers: [_driver(id: 22)],
      );

      expect(summary.attentionItems, hasLength(5));
      expect(
        summary.attentionItems.where(
          (item) => item.status == FleetComplianceStatus.valid,
        ),
        isEmpty,
      );
      expect(
        summary.attentionItems.any(
          (item) =>
              item.subjectType == FleetComplianceSubjectType.vehicle &&
              item.subjectId == 11,
        ),
        isTrue,
      );
      expect(
        summary.attentionItems.any(
          (item) =>
              item.subjectType == FleetComplianceSubjectType.driver &&
              item.subjectId == 22,
        ),
        isTrue,
      );
    },
  );

  test(
    'attention ordering is severity, then date, then deterministic ties',
    () async {
      final summary = await _summary(
        vehicles: [
          _vehicle(
            id: 2,
            registration: 'BRAVO',
            motExpiry: _now.subtract(const Duration(days: 1)),
            missingService: true,
          ),
          _vehicle(
            id: 1,
            registration: 'ALPHA',
            motExpiry: _now.subtract(const Duration(days: 2)),
            serviceDue: _now.add(const Duration(days: 3)),
          ),
        ],
      );

      expect(summary.attentionItems.map((item) => item.status), [
        FleetComplianceStatus.expired,
        FleetComplianceStatus.expired,
        FleetComplianceStatus.notRecorded,
        FleetComplianceStatus.dueSoon,
      ]);
      expect(summary.attentionItems.first.subjectId, 1);
      expect(summary.attentionItems[1].subjectId, 2);
    },
  );
}

Future<FleetComplianceSummary> _summary({
  List<Vehicle> vehicles = const [],
  List<Driver> drivers = const [],
  List<DriverCompliance> compliance = const [],
}) {
  return FleetComplianceService(
    loadVehicles: () async => vehicles,
    loadDrivers: () async => drivers,
    loadDriverCompliance: () async => compliance,
    now: () => _now,
  ).loadSummary();
}

Vehicle _vehicle({
  int id = 1,
  String registration = 'VEH001',
  DateTime? motExpiry,
  DateTime? serviceDue,
  bool missingMot = false,
  bool missingService = false,
  bool active = true,
}) => Vehicle(
  id: id,
  registration: registration,
  fleetNumber: 'F$id',
  make: 'Arrow',
  model: 'Fleet',
  year: 2026,
  vin: 'VIN$id',
  motExpiry: missingMot
      ? null
      : motExpiry ?? _now.add(const Duration(days: 31)),
  serviceDue: missingService
      ? null
      : serviceDue ?? _now.add(const Duration(days: 31)),
  active: active,
);

Driver _driver({int id = 1, DateTime? licenceExpiry, bool active = true}) =>
    Driver(
      id: id,
      firstName: 'Driver',
      lastName: '$id',
      licenceNumber: 'LIC$id',
      licenceExpiry: licenceExpiry,
      isActive: active,
    );

DriverCompliance _compliance({
  DateTime? licenceExpiry,
  DateTime? cpcExpiry,
  DateTime? medicalExpiry,
  DateTime? dbsExpiry,
  bool missingDbs = false,
}) => DriverCompliance(
  driverId: 1,
  licenceExpiry: licenceExpiry ?? _now.add(const Duration(days: 31)),
  cpcExpiry: cpcExpiry ?? _now.add(const Duration(days: 31)),
  medicalExpiry: medicalExpiry ?? _now.add(const Duration(days: 31)),
  dbsExpiry: missingDbs
      ? null
      : dbsExpiry ?? _now.add(const Duration(days: 31)),
  lastUpdated: _now,
);
