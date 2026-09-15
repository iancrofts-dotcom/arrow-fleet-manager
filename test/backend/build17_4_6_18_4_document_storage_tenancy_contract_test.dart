import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document registration accepts only tenant-prefixed canonical paths', () {
    final sql = File(
      'supabase/migrations/20260914143500_document_storage_tenancy_fix.sql',
    ).readAsStringSync();

    expect(sql, contains('v_org := public.fleet_current_organisation_id()'));
    expect(
      sql,
      contains(
        "v_org::text || '/' || p_entity_type || '/' || p_entity_id::text || '/'",
      ),
    );
    expect(sql, contains('organisation_id,'));
    expect(sql, contains('d.organisation_id = v_org'));
    expect(sql, contains('v.organisation_id = v_org'));
    expect(sql, contains("public.fleet_has_permission('manage_documents')"));
    expect(sql, contains("o.bucket_id = 'fleet-documents'"));
    expect(sql, contains('o.name = p_storage_path'));
  });

  test('document upload UI does not expose raw backend exceptions', () {
    final source = File(
      'lib/features/documents/screens/central_edit_document_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains(r"Text('Unable to upload document.\n$error')")),
    );
    expect(source, isNot(contains('PostgrestException')));
    expect(
      source,
      contains(
        'Unable to upload document. Check your connection and permissions, then try again.',
      ),
    );
  });
}
