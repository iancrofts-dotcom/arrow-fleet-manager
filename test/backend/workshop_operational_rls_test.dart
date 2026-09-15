import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workshop operational migration keeps direct writes closed', () {
    final sql = File(
      'supabase/migrations/20260909070000_workshop_operational_writes.sql',
    ).readAsStringSync();

    expect(sql, contains('security definer'));
    expect(
      sql,
      contains('revoke insert, update, delete on public.workshop_inspections'),
    );
    expect(
      sql,
      contains(
        'revoke insert, update, delete on public.workshop_inspection_items',
      ),
    );
    expect(
      sql,
      contains('revoke insert, update, delete on public.workshop_repair_jobs'),
    );
    expect(sql, contains("public.has_fleetiq_role('technician')"));
    expect(sql, contains('technician_profile_id'));
    expect(sql, contains('workshop_sign_off_inspection'));
    expect(
      sql,
      contains('Outstanding repair jobs must be resolved before sign-off'),
    );
  });

  test('only authenticated receives operational RPC execute grants', () {
    final sql = File(
      'supabase/migrations/20260909070000_workshop_operational_writes.sql',
    ).readAsStringSync();

    expect(sql, isNot(contains('grant insert')));
    expect(sql, isNot(contains('grant update')));
    expect(sql, isNot(contains('grant delete')));
    expect(
      sql,
      contains('grant execute on function public.workshop_create_inspection'),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.workshop_save_inspection_item',
      ),
    );
    expect(
      sql,
      contains('grant execute on function public.workshop_update_repair_job'),
    );
  });
}
