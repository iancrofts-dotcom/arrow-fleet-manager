import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repair job uses staged Technician to Manager workflow', () {
    final screen = File(
      'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Repair progress'));
    expect(screen, contains('Start Repair'));
    expect(screen, contains('Complete Repair'));
    expect(screen, contains('Submit for sign-off'));
    expect(screen, contains('Return to Technician'));
    expect(screen, contains('Approve & Sign Off'));
    expect(screen, contains("targetStatus: 'awaitingInspection'"));
    expect(screen, contains("_updateStatus('inProgress')"));
    expect(screen, isNot(contains("labelText: 'Job status'")));
  });

  test('job cards and central documents open inside FleetIQ', () {
    final repair = File(
      'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
    ).readAsStringSync();
    final documents = File(
      'lib/features/documents/screens/central_document_list_screen.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/shared/widgets/fleetiq_document_viewer.dart',
    ).readAsStringSync();

    expect(repair, contains('CentralWorkshopJobCardViewerScreen'));
    expect(repair, contains('Open Job Card'));
    expect(documents, contains('downloadDocument'));
    expect(documents, contains('FleetIqDocumentViewer'));
    expect(viewer, contains("Key('document-viewer-close')"));
    expect(viewer, contains('PdfPreview'));
    expect(viewer, contains("tooltip: 'Print'"));
  });

  test(
    'mobile navigation exposes small role menus without More and resets roots',
    () {
      final shell = File(
        'lib/shared/widgets/app_shell.dart',
      ).readAsStringSync();

      expect(shell, contains('visible.length <= 5'));
      expect(shell, contains('secondary.isEmpty ? null'));
      expect(shell, contains('if (onMore != null)'));
      expect(shell, contains('pushNamedAndRemoveUntil(route, (_) => false)'));
      expect(
        shell,
        contains('pushNamedAndRemoveUntil(route, (route) => false)'),
      );
    },
  );
}
