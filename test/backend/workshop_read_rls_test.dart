import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('technician role is committed before Workshop policies use it', () {
    final roleMigration = File(
      'supabase/migrations/20260909060000_technician_role_foundation.sql',
    ).readAsStringSync();
    final workshopMigration = File(
      'supabase/migrations/20260909060100_workshop_read_foundation.sql',
    ).readAsStringSync();

    expect(roleMigration, contains("add value if not exists 'technician'"));
    expect(workshopMigration, contains("has_fleetiq_role('technician')"));
  });

  test('central Workshop foundation is SELECT only', () {
    final migration = File(
      'supabase/migrations/20260909060100_workshop_read_foundation.sql',
    ).readAsStringSync().toLowerCase();

    for (final table in <String>[
      'workshop_inspections',
      'workshop_inspection_items',
      'workshop_repair_jobs',
    ]) {
      expect(
        migration,
        contains('revoke all on table public.$table from anon, authenticated'),
      );
      expect(
        migration,
        contains('grant select on table public.$table to authenticated'),
      );
    }

    expect(migration, isNot(contains('grant insert')));
    expect(migration, isNot(contains('grant update')));
    expect(migration, isNot(contains('grant delete')));
    expect(migration, isNot(contains('for insert to authenticated')));
    expect(migration, isNot(contains('for update to authenticated')));
    expect(migration, isNot(contains('for delete to authenticated')));
  });

  test('technicians are restricted to assigned Workshop rows', () {
    final migration = File(
      'supabase/migrations/20260909060100_workshop_read_foundation.sql',
    ).readAsStringSync();

    expect(migration, contains('technician_profile_id = auth.uid()'));
    expect(
      migration,
      contains('inspection.technician_profile_id = auth.uid()'),
    );
  });
}
