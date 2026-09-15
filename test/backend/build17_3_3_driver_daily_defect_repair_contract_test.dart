import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Driver daily defects use one secured Repair Job creation path', () {
    final migration = File(
      'supabase/migrations/20260910170000_driver_daily_defect_repair_fix.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains(
        'create or replace function public.workshop_save_driver_daily_inspection',
      ),
    );
    expect(migration, contains('auto_create_repair'));
    expect(migration, contains("(v_status = 'fail' or v_repair_required)"));
    expect(
      migration,
      isNot(contains('insert into public.workshop_repair_jobs(')),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.workshop_save_driver_daily_inspection',
      ),
    );
  });
}
