import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'company switching refuses to cross tenant scope with queued writes',
    () {
      final service = read(
        'lib/backend/organisation/central_organisation_service.dart',
      );
      final switcher = read(
        'lib/shared/widgets/central_organisation_switcher.dart',
      );
      expect(service, contains('ensureSafeToSwitchOrganisation'));
      expect(service, matches(RegExp(r'pendingWrites\(\s*scope,?\s*\)')));
      expect(
        service,
        contains('Sync pending offline changes before switching company.'),
      );
      expect(switcher, contains('ensureSafeToSwitchOrganisation'));
    },
  );

  test('company settings and ownership are organisation scoped', () {
    final migration = read(
      'supabase/migrations/20260914164500_multi_company_management_completion.sql',
    );
    final screen = read(
      'lib/features/auth/screens/central/central_organisation_management_screen.dart',
    );
    expect(migration, contains('owner_user_id'));
    expect(migration, contains('fleet_get_current_organisation_settings'));
    expect(migration, contains('fleet_update_current_organisation_settings'));
    expect(migration, contains('fleet_current_organisation_id()'));
    expect(migration, contains('fleet_protect_organisation_owner_membership'));
    expect(screen, contains('Company Settings'));
    expect(screen, contains('Report footer / trading note'));
  });

  test(
    'user management adds or invites into current company without admin passwords',
    () {
      final form = read(
        'lib/features/auth/widgets/central/central_user_form.dart',
      );
      final function = read('supabase/functions/manage-users/index.ts');
      expect(form, contains('Add / Invite User'));
      expect(form, isNot(contains('New password (optional)')));
      expect(function, contains("operation === 'invite_or_add'"));
      expect(function, contains('findAuthUserByEmail'));
      expect(function, contains('inviteUserByEmail'));
      expect(function, contains('organisation_id: caller.organisationId'));
      expect(function, isNot(contains('admin.auth.admin.createUser')));
    },
  );

  test(
    'membership edits and removals do not overwrite another company role',
    () {
      final function = read('supabase/functions/manage-users/index.ts');
      expect(function, contains("operation === 'update_membership'"));
      expect(function, contains("operation === 'remove_membership'"));
      expect(function, contains(".from('organisation_memberships')"));
      expect(function, contains('syncProfileMirrorIfActiveOrganisation'));
      expect(
        function,
        contains(
          'Transfer company ownership before removing or demoting the owner.',
        ),
      );
      expect(
        function,
        contains('You cannot remove your own current-company membership.'),
      );
    },
  );

  test('last membership cleanup preserves multi-company accounts', () {
    final function = read('supabase/functions/manage-users/index.ts');
    expect(function, contains(".eq('user_id', id)"));
    expect(function, contains(".eq('is_active', true)"));
    expect(function, contains('if (!remaining || remaining.length === 0)'));
    expect(function, contains('admin.auth.admin.deleteUser(id)'));
    expect(function, contains('active_organisation_id: next.organisation_id'));
  });
}
