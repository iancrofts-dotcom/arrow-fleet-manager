import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resilient Workshop repair mutations preserve secured RPC semantics',
    () {
      final gateway = File(
        'lib/backend/workshop/supabase_workshop_gateway.dart',
      ).readAsStringSync();
      final migration = File(
        'supabase/migrations/20260914113000_organisation_tenancy_offline.sql',
      ).readAsStringSync();

      expect(gateway, contains('CentralResilientMutationExecutor.instance'));
      expect(gateway, contains('workshopUpdateRepairJob'));
      expect(gateway, contains('workshopSignOffRepairJob'));

      expect(migration, contains("when 'workshop.repair_job.update'"));
      expect(migration, contains('workshop_update_repair_job_v2'));
      expect(migration, contains("p_payload->>'technician_mileage'"));
      expect(migration, contains("when 'workshop.repair_job.sign_off'"));
      expect(migration, contains('workshop_manager_sign_off_repair_job'));
    },
  );
}
