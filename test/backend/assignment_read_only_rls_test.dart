import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release lock removes central assignment write access', () {
    final sql = File(
      'supabase/migrations/20260908160000_assignment_read_only_lock.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains(
        'revoke insert, update, delete on table public.driver_assignments',
      ),
    );
    expect(
      sql,
      contains('drop policy if exists "fleet managers insert assignments"'),
    );
    expect(
      sql,
      contains('drop policy if exists "fleet managers update assignments"'),
    );
    expect(
      sql,
      contains(
        'grant select on table public.driver_assignments to authenticated',
      ),
    );
  });

  test('assignment foundation keeps role-scoped SELECT policy', () {
    final sql = File(
      'supabase/migrations/20260907030000_driver_assignment_foundation.sql',
    ).readAsStringSync();

    expect(sql, contains('create policy "fleet roles read assignments"'));
    expect(sql, contains("public.has_fleetiq_role('administrator')"));
    expect(sql, contains("public.has_fleetiq_role('manager')"));
    expect(sql, contains("public.has_fleetiq_role('workshop')"));
    expect(sql, contains("public.has_fleetiq_role('driver')"));
    expect(
      sql,
      contains('and driver_id = (select driver_id from public.profiles'),
    );
  });

  test('read-only lock is later than the assignment foundation migration', () {
    final migrations =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => name.endsWith('.sql'))
            .toList()
          ..sort();

    final foundation = migrations.indexOf(
      '20260907030000_driver_assignment_foundation.sql',
    );
    final lock = migrations.indexOf(
      '20260908160000_assignment_read_only_lock.sql',
    );

    expect(foundation, greaterThanOrEqualTo(0));
    expect(lock, greaterThan(foundation));
  });

  test('release lock never restores assignment mutation privileges', () {
    final sql = File(
      'supabase/migrations/20260908160000_assignment_read_only_lock.sql',
    ).readAsStringSync().toLowerCase();

    expect(sql, isNot(contains('grant insert')));
    expect(sql, isNot(contains('grant update')));
    expect(sql, isNot(contains('grant delete')));
    expect(sql, isNot(contains('for insert')));
    expect(sql, isNot(contains('for update')));
    expect(sql, isNot(contains('for delete')));
  });
}
