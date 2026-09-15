import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Driver daily inspection exposes staged save diagnostics', () {
    final service = File(
      'lib/features/inspections/services/central_driver_daily_inspection_service.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/inspections/inspection_screen.dart',
    ).readAsStringSync();

    expect(service, contains('CentralDriverDailyInspectionSaveException'));
    expect(service, contains("stage: 'Inspection save RPC'"));
    expect(service, contains("stage: 'Saved checklist lookup'"));
    expect(service, contains("stage: 'Photo storage upload'"));
    expect(service, contains("stage: 'Photo evidence registration'"));
    expect(service, contains('inspectionId: inspectionId'));
    expect(screen, contains('e.diagnosticMessage'));
    expect(screen, contains('Daily inspection save error:'));
    expect(screen, contains('Duration(seconds: 15)'));
  });
}
