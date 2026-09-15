import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/platform/platform_capabilities.dart';

void main() {
  test('Supabase mode exposes only centralised release routes', () {
    const nativeCentral = PlatformCapabilities(
      isWeb: false,
      backendMode: BackendMode.supabase,
    );

    for (final route in <String>[
      '/dashboard',
      '/vehicles',
      '/drivers',
      '/calendar',
      '/compliance',
      '/workshop',
      '/documents',
      '/users',
      '/reports',
    ]) {
      expect(nativeCentral.routeAvailable(route), isTrue, reason: route);
    }

    for (final route in <String>['/maintenance', '/settings']) {
      expect(nativeCentral.routeAvailable(route), isFalse, reason: route);
    }

    expect(nativeCentral.supportsLocalData, isFalse);
  });

  test('native local mode retains existing routes and local data', () {
    const nativeLocal = PlatformCapabilities(
      isWeb: false,
      backendMode: BackendMode.local,
    );

    expect(nativeLocal.supportsLocalData, isTrue);
    expect(nativeLocal.routeAvailable('/users'), isTrue);
    expect(nativeLocal.routeAvailable('/workshop'), isTrue);
    expect(nativeLocal.routeAvailable('/reports'), isTrue);
    expect(nativeLocal.routeAvailable('/documents'), isTrue);
  });

  test('native Supabase direct routes cannot fall back to local features', () {
    final source = File(
      'lib/app/router_feature_screens_native.dart',
    ).readAsStringSync();

    expect(source, contains("as local_users"));
    expect(source, contains("as local_workshop"));
    expect(source, contains("as local_reports"));
    expect(source, contains("as local_documents"));
    expect(source, contains('central_users.CentralUserManagementScreen'));
    expect(source, contains('central_workshop.CentralWorkshopDashboardScreen'));
    expect(source, contains('CentralFleetReportService'));
    expect(source, contains('central_documents.CentralDocumentListScreen'));
    expect(source, contains('CentralDashboardParityService'));
    expect(source, contains('CentralCalendarParityService'));
    expect(source, contains('CentralComplianceParityService'));
    expect(source, isNot(contains('_CentralFeatureUnavailable')));
  });
}
