import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Build 17.4.6.18 adds real organisation membership tenancy', () {
    final migration = File(
      'supabase/migrations/20260914113000_organisation_tenancy_offline.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('create table if not exists public.organisations'),
    );
    expect(
      migration,
      contains('create table if not exists public.organisation_memberships'),
    );
    expect(migration, contains('fleet_current_organisation_id'));
    expect(migration, contains('fleet_set_active_organisation'));
    expect(migration, contains('as restrictive'));
    expect(migration, contains('fleet_org_isolation'));
    expect(migration, isNot(contains("'default'")));
    expect(migration, isNot(contains("'global'")));
    expect(migration, isNot(contains("'single-tenant'")));
  });

  test(
    'central scope is authenticated user plus server-confirmed organisation',
    () {
      final provider = File(
        'lib/backend/resilience/supabase_resilience_scope_provider.dart',
      ).readAsStringSync();
      final organisations = File(
        'lib/backend/organisation/central_organisation_service.dart',
      ).readAsStringSync();

      expect(provider, contains('BackendClient.client.auth.currentUser'));
      expect(provider, contains('currentOrganisationId()'));
      expect(provider, contains('tenantId:'));
      expect(provider, contains('userId: user.id'));
      expect(organisations, contains("'fleet_current_organisation_id'"));
      expect(organisations, contains('CentralFailureKind.connectivity'));
      expect(organisations, contains('CentralFailureKind.timeout'));
      expect(organisations, contains('confirmed_organisation'));
    },
  );

  test('offline replay is idempotent and tenant scoped', () {
    final migration = File(
      'supabase/migrations/20260914113000_organisation_tenancy_offline.sql',
    ).readAsStringSync();
    final executor = File(
      'lib/backend/resilience/central_resilient_mutation_executor.dart',
    ).readAsStringSync();
    final sync = File(
      'lib/backend/resilience/central_offline_sync_service.dart',
    ).readAsStringSync();

    expect(migration, contains('fleet_mutation_receipts'));
    expect(migration, contains('p_idempotency_key'));
    expect(migration, contains('fleet_apply_resilient_mutation'));
    expect(executor, contains('requireSafeScope'));
    expect(executor, contains('idempotencyKey'));
    expect(sync, contains('replayPending'));
    expect(sync, contains('becameOnline'));
  });

  test('only JSON-safe non-binary operational mutations are replayable', () {
    final workshop = File(
      'lib/backend/workshop/supabase_workshop_gateway.dart',
    ).readAsStringSync();
    final documents = File(
      'lib/backend/documents/supabase_central_document_gateway.dart',
    ).readAsStringSync();

    expect(
      workshop,
      contains('CentralEmergencyOperationCatalog.workshopSaveInspectionItem'),
    );
    expect(
      workshop,
      contains('CentralEmergencyOperationCatalog.workshopUpdateRepairJob'),
    );
    expect(
      workshop,
      contains('CentralEmergencyOperationCatalog.workshopCompleteInspection'),
    );
    expect(
      documents,
      contains('CentralEmergencyOperationCatalog.documentArchive'),
    );
    expect(documents, contains('uploadBinary'));
    expect(documents, isNot(contains('documentRegister,')));
  });

  test('new document paths are organisation prefixed', () {
    final documents = File(
      'lib/backend/documents/supabase_central_document_gateway.dart',
    ).readAsStringSync();
    final workshop = File(
      'lib/backend/workshop/supabase_workshop_gateway.dart',
    ).readAsStringSync();

    expect(documents, contains("'\$organisationId/\$entityType/\$entityId/"));
    expect(workshop, contains("'\$organisationId/workshop/\$inspectionId/"));
  });

  test('central user and driver creation attaches membership', () {
    final users = File(
      'supabase/functions/manage-users/index.ts',
    ).readAsStringSync();
    final drivers = File(
      'supabase/functions/manage-drivers/index.ts',
    ).readAsStringSync();

    expect(users, contains(".from('organisation_memberships')"));
    expect(users, contains('caller.organisationId'));
    expect(drivers, contains(".from('organisation_memberships')"));
    expect(drivers, contains('caller.organisation_id'));
    expect(drivers, contains('organisation_id: caller.organisation_id'));
  });
}
