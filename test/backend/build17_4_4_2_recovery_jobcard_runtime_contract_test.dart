import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Web auth uses callback-safe implicit recovery while native retains PKCE',
    () {
      final source = File('lib/backend/backend_client.dart').readAsStringSync();
      expect(
        source,
        contains('kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce'),
      );
      expect(source, contains('detectSessionInUri: true'));
    },
  );

  test('opening a job card does not generate a PDF before navigation', () {
    final details = File(
      'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/workshop/screens/central_workshop_job_card_viewer_screen.dart',
    ).readAsStringSync();

    final openStart = details.indexOf('Future<void> _openJobCard()');
    final runStart = details.indexOf('Future<bool> _run(', openStart);
    final openMethod = details.substring(openStart, runStart);

    expect(openMethod, contains('CentralWorkshopJobCardViewerScreen'));
    expect(openMethod, isNot(contains('CentralWorkshopPdfService')));
    expect(openMethod, isNot(contains('pdfBytes')));
    expect(viewer, contains('CentralWorkshopPdfService().jobCard'));
    expect(viewer, contains('Print Job Card'));
    expect(viewer, contains('Share / Download PDF'));
  });
}
