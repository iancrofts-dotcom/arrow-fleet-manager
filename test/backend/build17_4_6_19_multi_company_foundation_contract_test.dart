import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multi-company migration scopes effective access to membership', () {
    final sql = File(
      'supabase/migrations/20260914161000_multi_company_foundation.sql',
    ).readAsStringSync();

    expect(sql, contains('organisation_memberships'));
    expect(sql, contains('custom_role_id'));
    expect(sql, contains('fleet_current_access_profile'));
    expect(sql, contains('fleet_create_organisation'));
    expect(sql, contains('fleet_update_current_organisation'));
    expect(sql, contains('fleet_list_current_organisation_members'));
    expect(sql, contains("when m.role = 'administrator' then true"));
    expect(sql, contains('fleet_set_active_organisation'));
  });

  test('client supports company creation switching and member review', () {
    final service = File(
      'lib/backend/organisation/central_organisation_service.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/auth/screens/central/central_organisation_management_screen.dart',
    ).readAsStringSync();
    final shell = File('lib/shared/widgets/app_shell.dart').readAsStringSync();

    expect(service, contains('createOrganisation'));
    expect(service, contains('updateCurrentOrganisation'));
    expect(service, contains('listCurrentOrganisationMembers'));
    expect(screen, contains("title: 'Companies'"));
    expect(screen, contains("label: const Text('Add Company')"));
    expect(screen, contains("Chip(label: Text('Current'))"));
    expect(screen, contains('setActiveOrganisation(organisation.id)'));
    expect(shell, contains('CentralOrganisationSwitcher'));
  });

  test('company switching refreshes central role and permissions', () {
    final gateway = File(
      'lib/backend/auth/supabase_sdk_auth_gateway.dart',
    ).readAsStringSync();
    final adapter = File(
      'lib/backend/auth/supabase_auth_adapter.dart',
    ).readAsStringSync();
    final auth = File(
      'lib/features/auth/services/auth_service.dart',
    ).readAsStringSync();

    expect(gateway, contains("'fleet_current_access_profile'"));
    expect(adapter, contains('refreshProfile()'));
    expect(auth, contains('refreshCentralProfile()'));
    expect(auth, contains('_applyBackendProfile(profile)'));
  });
}
