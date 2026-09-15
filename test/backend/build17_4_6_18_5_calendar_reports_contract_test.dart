import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central calendar includes live document expiry events', () {
    final source = File(
      'lib/backend/central_calendar_parity_service.dart',
    ).readAsStringSync();

    expect(source, contains('CentralDocumentRepository'));
    expect(source, contains('SupabaseCentralDocumentGateway'));
    expect(source, contains('.listDocuments()'));
    expect(source, contains('document.expiresOn'));
    expect(source, contains('CalendarEventType.document'));
    expect(source, contains('document.entityId'));
    expect(source, contains('document.title.trim().isEmpty'));
  });

  test('Windows Supabase Reports Centre wires every report module loader', () {
    final source = File(
      'lib/app/router_feature_screens_native.dart',
    ).readAsStringSync();

    expect(source, contains('CentralReportsCentreService'));
    expect(source, contains('generateDocument:'));
    expect(source, contains('CentralReportsCentreService().generate(query)'));
    expect(source, contains('CentralResilienceRuntime.instance.run'));
  });
}
