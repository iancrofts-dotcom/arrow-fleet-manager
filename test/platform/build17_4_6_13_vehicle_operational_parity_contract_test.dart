import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'central Vehicle history exposes operational summary and Workshop route',
    () {
      final source = File(
        'lib/features/vehicles/screens/central_vehicle_history_screen.dart',
      ).readAsStringSync();

      expect(source, contains("title: 'History summary'"));
      expect(source, contains('openRepairs'));
      expect(source, contains('failedInspections'));
      expect(source, contains("label: const Text('Open Workshop')"));
      expect(source, contains('DashboardNavigation.openWorkshop(context)'));
      expect(source, contains('PermissionService.instance.canAccessWorkshop'));
      expect(source, contains('CentralWorkshopInspectionDetailsScreen'));
      expect(source, contains('CentralWorkshopRepairJobDetailsScreen'));
      expect(source, isNot(contains('AppDatabase')));
      expect(source, isNot(contains('sqflite')));
    },
  );

  test(
    'vehicle-scoped Documents stay locked to the selected Vehicle owner',
    () {
      final source = File(
        'lib/features/documents/screens/central_document_list_screen.dart',
      ).readAsStringSync();

      expect(source, contains('final isOwnerLocked ='));
      expect(source, contains('lockedOwnerLabel: widget.ownerLabel'));
      expect(
        source,
        contains('if (widget.entityType == null || widget.entityId == null)'),
      );
      expect(source, contains('document.entityId != widget.entityId'));
      expect(source, contains('downloadDocument(document.storagePath)'));
      expect(source, contains('FleetIqDocumentViewer'));
    },
  );

  test(
    'Vehicle Details treats Fleet Number as optional on shared and Web screens',
    () {
      final shared = File(
        'lib/features/vehicles/screens/vehicle_details_screen.dart',
      ).readAsStringSync();
      final web = File(
        'lib/features/vehicles/screens/vehicle_details_web_screen.dart',
      ).readAsStringSync();

      expect(shared, contains("? 'Fleet number not recorded'"));
      expect(web, contains("? 'Not recorded'"));
      expect(shared, contains('CentralDocumentListScreen'));
      expect(shared, contains('CentralVehicleHistoryScreen'));
      expect(web, contains('CentralDocumentListScreen'));
      expect(web, contains('CentralVehicleHistoryScreen'));
    },
  );
}
