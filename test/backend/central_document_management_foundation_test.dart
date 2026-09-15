import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'central Documents use private Storage plus security-definer metadata RPCs',
    () {
      final sql = File(
        'supabase/migrations/20260909103000_central_document_management.sql',
      ).readAsStringSync();
      final gateway = File(
        'lib/backend/documents/supabase_central_document_gateway.dart',
      ).readAsStringSync();

      expect(sql, contains('fleet_register_document'));
      expect(sql, contains('fleet_archive_document'));
      expect(sql, contains("bucket_id = 'fleet-documents'"));
      expect(sql, contains('security definer'));
      expect(
        sql,
        contains(
          'revoke insert,update,delete on public.fleet_documents from anon,authenticated',
        ),
      );
      expect(gateway, contains("from('fleet-documents')"));
      expect(gateway, contains('createSignedUrl'));
    },
  );

  test('Driver document visibility remains role-scoped', () {
    final sql = File(
      'supabase/migrations/20260909103000_central_document_management.sql',
    ).readAsStringSync();

    expect(sql, contains("public.has_fleetiq_role('driver')"));
    expect(sql, contains("public.has_fleetiq_role('technician')"));
    expect(sql, contains('technician_profile_id = auth.uid()'));
    expect(sql, contains('driver_id = ('));
  });
}
