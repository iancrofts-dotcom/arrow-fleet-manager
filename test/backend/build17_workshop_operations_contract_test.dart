import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Build 17 keeps Workshop repair mutations behind secured RPCs', () {
    final gateway = File(
      'lib/backend/workshop/supabase_workshop_gateway.dart',
    ).readAsStringSync();
    final migration = File(
      'supabase/migrations/20260910080000_workshop_operations_completion.sql',
    ).readAsStringSync();
    final resilientMigration = File(
      'supabase/migrations/20260914113000_organisation_tenancy_offline.sql',
    ).readAsStringSync();

    expect(gateway, contains('workshopSignOffRepairJob'));
    expect(
      resilientMigration,
      contains('workshop_manager_sign_off_repair_job'),
    );
    expect(gateway, contains("'workshop_save_template'"));
    expect(migration, contains('security definer'));
    expect(
      migration,
      contains(
        'revoke insert,update,delete on public.workshop_repair_jobs from anon,authenticated',
      ),
    );
    expect(
      migration,
      contains('Technicians must submit repairs for management sign-off'),
    );
  });

  test('Build 17 promotes defects and exposes job card/report/template UX', () {
    final migration = File(
      'supabase/migrations/20260910080000_workshop_operations_completion.sql',
    ).readAsStringSync();
    final jobCard = File(
      'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
    ).readAsStringSync();
    final templates = File(
      'lib/features/workshop/screens/central_workshop_template_wizard_screen.dart',
    ).readAsStringSync();
    final reports = File(
      'lib/features/workshop/screens/central_workshop_reports_screen.dart',
    ).readAsStringSync();

    expect(migration, contains('workshop_auto_create_repair_from_defect'));
    expect(jobCard, contains('Manager sign-off'));
    expect(jobCard, contains('Defect evidence'));
    expect(jobCard, contains('awaitingParts'));
    expect(templates, contains('Wizard'));
    expect(templates, contains('Create repair job from failed defect'));
    expect(reports, contains('Preview / Print Report'));
  });

  test('Build 17 includes Driver workspace fix on the Build 16.2 baseline', () {
    final driverMigration = File(
      'supabase/migrations/20260910064500_driver_assigned_vehicle_and_daily_inspection.sql',
    ).readAsStringSync();
    final driverService = File(
      'lib/features/inspections/services/central_driver_daily_inspection_service.dart',
    ).readAsStringSync();

    expect(driverMigration, contains('drivers read current assigned vehicle'));
    expect(driverMigration, contains('workshop_save_driver_daily_inspection'));
    expect(driverService, contains('workshop_save_driver_daily_inspection'));
  });
}
