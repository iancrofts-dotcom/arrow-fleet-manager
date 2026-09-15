import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260909080000_workshop_templates_documents_evidence.sql',
  ).readAsStringSync();

  test(
    'Build 10 creates central templates and pre-populated inspection RPC',
    () {
      expect(
        migration,
        contains(
          'create table if not exists public.workshop_inspection_templates',
        ),
      );
      expect(migration, contains('public.workshop_inspection_template_items'));
      expect(migration, contains('workshop_create_inspection_from_template'));
      expect(migration, contains('FleetIQ Workshop Safety Inspection'));
      expect(
        migration,
        contains('insert into public.workshop_inspection_items'),
      );
    },
  );

  test(
    'Build 10 creates private evidence storage and central document metadata',
    () {
      expect(
        migration,
        contains('create table if not exists public.fleet_documents'),
      );
      expect(
        migration,
        contains("'fleet-documents', 'fleet-documents', false"),
      );
      expect(migration, contains('workshop_register_evidence'));
      expect(migration, contains('photo_count=photo_count+1'));
      expect(migration, contains('A required failure photo is missing'));
    },
  );

  test('central document tables keep direct database mutations closed', () {
    expect(
      migration,
      contains(
        'revoke insert,update,delete on public.workshop_inspection_templates from anon,authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'revoke insert,update,delete on public.workshop_inspection_template_items from anon,authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'revoke insert,update,delete on public.fleet_documents from anon,authenticated',
      ),
    );
  });
}
