import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central cached reads remain tenant and user scoped', () {
    final helper = File(
      'lib/backend/resilience/central_cached_read.dart',
    ).readAsStringSync();

    expect(helper, contains('currentScope()'));
    expect(helper, contains('runCached'));
    expect(helper, contains('SupabaseResilienceScopeProvider'));
    expect(helper, contains('Cached FleetIQ list payload was invalid'));
    expect(helper, contains('Cached FleetIQ record payload was invalid'));
  });

  test('Workshop core read paths use last-known-good cache', () {
    final workshop = File(
      'lib/backend/workshop/supabase_workshop_gateway.dart',
    ).readAsStringSync();

    expect(workshop, contains("cacheKey: 'workshop:inspections:list'"));
    expect(workshop, contains("'workshop:inspection_items:\$inspectionId'"));
    expect(workshop, contains("'workshop:repairs:list'"));
    expect(workshop, contains("'workshop:templates:list'"));
    expect(workshop, contains("'workshop:evidence:\$inspectionItemId'"));
  });

  test('Fleet Drivers Compliance Assignments and Documents cache metadata', () {
    final vehicles = File(
      'lib/backend/vehicles/supabase_vehicle_gateway.dart',
    ).readAsStringSync();
    final drivers = File(
      'lib/backend/drivers/supabase_driver_gateway.dart',
    ).readAsStringSync();
    final assignments = File(
      'lib/backend/drivers/supabase_driver_assignment_gateway.dart',
    ).readAsStringSync();
    final compliance = File(
      'lib/backend/drivers/supabase_driver_compliance_gateway.dart',
    ).readAsStringSync();
    final documents = File(
      'lib/backend/documents/supabase_central_document_gateway.dart',
    ).readAsStringSync();

    expect(vehicles, contains("cacheKey: 'vehicles:list'"));
    expect(drivers, contains("cacheKey: 'drivers:list'"));
    expect(assignments, contains("cacheKey: 'driver_assignments:list'"));
    expect(compliance, contains("cacheKey: 'driver_compliance:list'"));
    expect(documents, contains("cacheKey: 'documents:list'"));
    expect(documents, contains('uploadBinary'));
  });

  test(
    'Workshop offline UI is friendly and does not expose raw exception text',
    () {
      final screen = File(
        'lib/features/workshop/screens/central_workshop_dashboard_screen.dart',
      ).readAsStringSync();
      final banner = File(
        'lib/shared/widgets/central_connection_banner.dart',
      ).readAsStringSync();

      expect(screen, contains('CentralConnectionBoundary'));
      expect(screen, contains('Workshop unavailable offline'));
      expect(screen, contains('No saved Workshop data is available'));
      expect(screen, isNot(contains(r'${snapshot.error}')));
      expect(banner, contains('You’re offline'));
      expect(
        banner,
        contains('Supported changes will sync when you reconnect.'),
      );
    },
  );

  test('offline cache never adds a SQLite fallback', () {
    final helper = File(
      'lib/backend/resilience/central_cached_read.dart',
    ).readAsStringSync();
    final workshop = File(
      'lib/backend/workshop/supabase_workshop_gateway.dart',
    ).readAsStringSync();

    expect(helper.toLowerCase(), isNot(contains('sqlite')));
    expect(workshop.toLowerCase(), isNot(contains('sqlite')));
  });
}
