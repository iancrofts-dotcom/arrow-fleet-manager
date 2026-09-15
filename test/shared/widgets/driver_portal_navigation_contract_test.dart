import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Driver portal routes are first-class AppRouter destinations', () {
    final router = File('lib/app/router.dart').readAsStringSync();
    expect(router, contains("driverVehicle = '/driver/vehicle'"));
    expect(router, contains("driverInspection = '/driver/inspection'"));
    expect(router, contains("driverCompliance = '/driver/compliance'"));
    expect(router, contains("driverDocuments = '/driver/documents'"));
    expect(router, contains("driverProfile = '/driver/profile'"));
    expect(router, contains('DriverPortalDestinationScreen'));
  });

  test(
    'Driver shell exposes self-service destinations without fleet authority',
    () {
      final shell = File(
        'lib/shared/widgets/app_shell.dart',
      ).readAsStringSync();
      expect(shell, contains('AppRouter.driverVehicle'));
      expect(shell, contains('AppRouter.driverInspection'));
      expect(shell, contains('AppRouter.driverCompliance'));
      expect(shell, contains('AppRouter.driverDocuments'));
      expect(shell, contains('AppRouter.driverProfile'));
      expect(shell, contains('isVisible: _isDriver'));
    },
  );

  test('walkaround checklist no longer nests elevated Cards', () {
    final section = File(
      'lib/features/inspections/widgets/checklist_section.dart',
    ).readAsStringSync();
    final tile = File(
      'lib/features/inspections/widgets/checklist_tile.dart',
    ).readAsStringSync();
    expect(section, isNot(contains('return Card(')));
    expect(tile, isNot(contains('return Card(')));
    expect(tile, contains('SegmentedButton<InspectionStatus>'));
    expect(tile, contains("label: Text('PASS')"));
    expect(tile, contains("label: Text('FAIL')"));
    expect(tile, contains("label: Text('N/A')"));
  });
}
