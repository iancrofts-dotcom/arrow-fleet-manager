import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web Vehicle Details exposes central Documents and history', () {
    final source = File(
      'lib/features/vehicles/screens/vehicle_details_web_screen.dart',
    ).readAsStringSync();

    expect(source, contains('CentralDocumentListScreen'));
    expect(source, contains('CentralVehicleHistoryScreen'));
    expect(source, contains("entityType: 'vehicle'"));
    expect(
      source,
      isNot(
        contains(
          'Documents, maintenance and workshop history are still being migrated',
        ),
      ),
    );
  });

  test('central Vehicle history remains Supabase-only', () {
    final source = File(
      'lib/features/vehicles/screens/central_vehicle_history_screen.dart',
    ).readAsStringSync();

    expect(source, contains('BackendWorkshopRepository'));
    expect(source, contains('SupabaseWorkshopGateway'));
    expect(source, contains('row.vehicleId == widget.vehicleId'));
    expect(source, contains('CentralWorkshopInspectionDetailsScreen'));
    expect(source, contains('CentralWorkshopRepairJobDetailsScreen'));
    expect(source, isNot(contains('AppDatabase')));
    expect(source, isNot(contains('sqflite')));
    expect(source, isNot(contains('MaintenanceRepository')));
  });
}
