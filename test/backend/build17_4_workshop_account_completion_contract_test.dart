import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'assigned Technician can read repair evidence and job card embeds photos',
    () {
      final migration = File(
        'supabase/migrations/20260911070000_workshop_jobcard_password_completion.sql',
      ).readAsStringSync();
      final screen = File(
        'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
      ).readAsStringSync();
      final pdf = File(
        'lib/features/workshop/services/central_workshop_pdf_service.dart',
      ).readAsStringSync();

      expect(migration, contains('technicians read assigned repair evidence'));
      expect(migration, contains('repair.technician_profile_id = auth.uid()'));
      expect(screen, contains('downloadEvidence'));
      expect(screen, contains('CentralWorkshopJobCardViewerScreen'));
      expect(pdf, contains('pw.MemoryImage'));
      expect(pdf, contains('Defect photo / evidence'));
    },
  );

  test(
    'technician mileage is separate and manager sign-off has dedicated RPC',
    () {
      final migration = File(
        'supabase/migrations/20260911070000_workshop_jobcard_password_completion.sql',
      ).readAsStringSync();
      final gateway = File(
        'lib/backend/workshop/supabase_workshop_gateway.dart',
      ).readAsStringSync();
      final resilientMigration = File(
        'supabase/migrations/20260914113000_organisation_tenancy_offline.sql',
      ).readAsStringSync();
      final model = File(
        'lib/backend/workshop/backend_workshop_repair_job.dart',
      ).readAsStringSync();

      expect(migration, contains('technician_mileage integer'));
      expect(migration, contains('workshop_update_repair_job_v2'));
      expect(migration, contains('workshop_manager_sign_off_repair_job'));
      expect(gateway, contains('workshopUpdateRepairJob'));
      expect(gateway, contains('workshopSignOffRepairJob'));
      expect(resilientMigration, contains("when 'workshop.repair_job.update'"));
      expect(resilientMigration, contains('workshop_update_repair_job_v2'));
      expect(resilientMigration, contains("p_payload->>'technician_mileage'"));
      expect(
        resilientMigration,
        contains("when 'workshop.repair_job.sign_off'"),
      );
      expect(
        resilientMigration,
        contains('workshop_manager_sign_off_repair_job'),
      );
      expect(model, contains('technicianMileage'));
    },
  );

  test('central Driver account supports change and forgotten passwords', () {
    final account = File(
      'lib/features/drivers/screens/central_driver_account_screen.dart',
    ).readAsStringSync();
    final login = File(
      'lib/features/auth/screens/login_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/auth/services/central_password_service.dart',
    ).readAsStringSync();

    expect(account, contains('Change My Password'));
    expect(login, contains('Forgot password?'));
    expect(service, contains('auth.updateUser'));
    expect(service, contains('resetPasswordForEmail'));
    expect(service, isNot(contains('service_role')));
  });
}
