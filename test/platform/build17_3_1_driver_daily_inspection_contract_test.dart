import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Driver inspection bypasses SQLite vehicle-id validation', () {
    final source = File(
      'lib/features/inspections/inspection_screen.dart',
    ).readAsStringSync();
    expect(source, contains('isDriverDailyInspection && isCentral'));
    expect(source, contains('Please enter the current odometer reading.'));
    expect(source, contains('_prefillCentralMileage'));
  });

  test('inspection photos use bytes and central evidence upload', () {
    final tile = File(
      'lib/features/inspections/widgets/checklist_tile.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/inspections/services/central_driver_daily_inspection_service.dart',
    ).readAsStringSync();
    expect(tile, contains('Image.memory'));
    expect(tile, isNot(contains('Image.file')));
    expect(service, contains("storage.from('fleet-documents')"));
    expect(service, contains("'workshop_register_evidence'"));
  });
}
