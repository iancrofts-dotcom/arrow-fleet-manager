import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle.dart';
import 'package:arrow_fleet_manager/backend/vehicles/central_vehicle_compliance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 8);

  test('classifies calendar dates without time-of-day drift', () {
    expect(
      centralComplianceState(DateTime(2026, 9, 7), now: now),
      CentralComplianceState.overdue,
    );
    expect(
      centralComplianceState(DateTime(2026, 9, 8), now: now),
      CentralComplianceState.dueSoon,
    );
    expect(
      centralComplianceState(DateTime(2026, 10, 8), now: now),
      CentralComplianceState.dueSoon,
    );
    expect(
      centralComplianceState(DateTime(2026, 10, 9), now: now),
      CentralComplianceState.valid,
    );
    expect(
      centralComplianceState(null, now: now),
      CentralComplianceState.missing,
    );
  });

  test('summarises only active central vehicles', () {
    final vehicles = [
      _vehicle('1', mot: DateTime(2026, 9, 1), service: DateTime(2026, 9, 20)),
      _vehicle('2', mot: DateTime(2026, 10, 20), service: null),
      _vehicle(
        '3',
        active: false,
        mot: DateTime(2020),
        service: DateTime(2020),
      ),
    ];
    final summary = CentralVehicleComplianceSummary.fromVehicles(
      vehicles,
      now: now,
    );
    expect(summary.motOverdue, 1);
    expect(summary.motDueSoon, 0);
    expect(summary.serviceDueSoon, 1);
    expect(summary.serviceMissing, 1);
  });
}

BackendVehicle _vehicle(
  String suffix, {
  bool active = true,
  DateTime? mot,
  DateTime? service,
}) => BackendVehicle(
  id: '00000000-0000-4000-8000-00000000000$suffix',
  registration: 'TEST$suffix',
  fleetNumber: suffix,
  isActive: active,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  motExpiry: mot,
  serviceDue: service,
);
