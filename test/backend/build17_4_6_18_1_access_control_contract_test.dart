import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('custom roles are organisation scoped and permission based', () {
    final migration = read(
      'supabase/migrations/20260914114500_custom_roles_driver_delete.sql',
    );
    expect(
      migration,
      contains('create table if not exists public.custom_roles'),
    );
    expect(migration, contains('organisation_id uuid not null'));
    expect(migration, contains('custom_role_id uuid'));
    expect(migration, contains('fleet_has_permission'));
    expect(migration, contains('as restrictive for select'));
    expect(migration, contains('as restrictive for update'));
  });

  test('custom roles cannot grant FleetIQ organisation administration', () {
    final permissions = read(
      'lib/features/auth/services/permission_service.dart',
    );
    expect(permissions, contains('bool get canManageUsers => isAdmin;'));
    expect(permissions, contains('bool get canEditSettings => isAdmin;'));
    expect(permissions, contains('customPermissions'));
  });

  test('user management exposes custom-role administration and assignment', () {
    final screen = read(
      'lib/features/auth/screens/central/central_user_management_screen.dart',
    );
    final form = read(
      'lib/features/auth/widgets/central/central_user_form.dart',
    );
    final function = read('supabase/functions/manage-users/index.ts');
    expect(screen, contains('Custom Roles'));
    expect(form, contains('(Custom)'));
    expect(function, contains("operation === 'create_role'"));
    expect(function, contains("operation === 'update_role'"));
    expect(function, contains("operation === 'delete_role'"));
    expect(function, contains('custom_role_id'));
  });

  test('Driver deletion is Administrator only and retains history', () {
    final screen = read(
      'lib/features/drivers/screens/central_driver_details_screen.dart',
    );
    final function = read('supabase/functions/manage-drivers/index.ts');
    final gateway = read(
      'lib/backend/drivers/supabase_driver_management_gateway.dart',
    );
    expect(screen, contains('PermissionService.instance.isAdmin'));
    expect(screen, contains('Historical records retained'));
    expect(function, contains("operation === 'delete'"));
    expect(function, contains("caller.role !== 'administrator'"));
    expect(function, contains('deleted_at'));
    expect(function, contains('admin.auth.admin.deleteUser'));
    expect(gateway, contains("_invoke('delete'"));
  });

  test('deleted Drivers are removed from the active Driver list', () {
    final gateway = read('lib/backend/drivers/supabase_driver_gateway.dart');
    expect(gateway, contains(".isFilter('deleted_at', null)"));
  });
}
