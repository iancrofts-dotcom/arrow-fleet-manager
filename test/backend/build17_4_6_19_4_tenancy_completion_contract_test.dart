import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('ownership transfer is owner-only and tenant scoped', () {
    final sql = read(
      'supabase/migrations/20260915070000_tenancy_completion.sql',
    );
    expect(sql, contains('fleet_current_organisation_id()'));
    expect(
      sql,
      contains('Only the current company owner can transfer ownership.'),
    );
    expect(sql, contains("v_target_role <> 'administrator'"));
    expect(sql, contains('owner_user_id = p_new_owner_user_id'));
    expect(sql, contains('organisation_id = v_org'));
  });

  test('company UI exposes protected ownership transfer', () {
    final source = read(
      'lib/features/auth/screens/central/central_organisation_management_screen.dart',
    );
    expect(source, contains("title: const Text('Company ownership')"));
    expect(source, contains("label: const Text('Transfer')"));
    expect(source, contains('_transferOwnership(settings, members)'));
    expect(
      source,
      contains('Only active Administrators can become the company owner.'),
    );
  });

  test(
    'client calls server ownership RPC without service role credentials',
    () {
      final source = read(
        'lib/backend/organisation/central_organisation_service.dart',
      );
      expect(
        source,
        contains("'fleet_transfer_current_organisation_ownership'"),
      );
      expect(source, contains("'p_new_owner_user_id': normalized"));
      expect(source.toLowerCase(), isNot(contains('service_role')));
    },
  );
}
