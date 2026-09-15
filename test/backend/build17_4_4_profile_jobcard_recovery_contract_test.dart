import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Build 17.4.4 uses named sign-off and self-service profile RPC', () {
    final migration = File(
      'supabase/migrations/20260911090000_user_profiles_and_named_signoff.sql',
    ).readAsStringSync();
    expect(migration, contains('full_name'));
    expect(migration, contains('fleet_update_my_profile'));
    expect(migration, contains('Set your full name in My Profile'));
    expect(migration, contains("signed_off_name=v_name"));
  });

  test('Build 17.4.4 opens job cards as native FleetIQ content', () {
    final details = File(
      'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/workshop/screens/central_workshop_job_card_viewer_screen.dart',
    ).readAsStringSync();
    expect(details, contains('CentralWorkshopJobCardViewerScreen'));
    expect(viewer, contains("Key('job-card-viewer-close')"));
    expect(viewer, contains('Defect Evidence'));
    expect(viewer, contains('Share / Download PDF'));
  });

  test('Build 17.4.4 password reset uses configured production redirect', () {
    final source = File(
      'lib/features/auth/services/central_password_service.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('https://fleetiq.unaux.com/app/?route=set-password'),
    );
    expect(
      source,
      contains('String _passwordRedirect() => _configuredRedirect'),
    );
    expect(source, isNot(contains('Uri.base')));
  });

  test('Build 17.4.4 exposes technician profile and password self-service', () {
    final dashboard = File(
      'lib/features/dashboard/sections/role_sections/technician_dashboard.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/auth/screens/central/central_my_profile_screen.dart',
    ).readAsStringSync();
    expect(dashboard, contains('My Profile & Password'));
    expect(profile, contains('Update My Details'));
    expect(profile, contains('Change My Password'));
  });
}
