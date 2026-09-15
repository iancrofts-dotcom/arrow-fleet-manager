import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'central Driver dashboard routes My Account to Supabase account screen',
    () {
      final source = File(
        'lib/features/dashboard/sections/role_sections/driver_dashboard.dart',
      ).readAsStringSync();

      expect(source, contains('CentralDriverAccountScreen'));
      expect(source, contains('child: isCentral'));
    },
  );

  test('central Driver account does not use legacy local account services', () {
    final source = File(
      'lib/features/drivers/screens/central_driver_account_screen.dart',
    ).readAsStringSync();

    expect(source, contains('currentBackendDriverId'));
    expect(source, contains('BackendDriverRepository'));
    expect(source, contains('CentralDriverComplianceScreen'));
    expect(source, contains('CentralDocumentListScreen'));
    expect(
      source,
      isNot(contains("import '../../auth/services/user_service.dart';")),
    );
    expect(source, isNot(contains('UserService.')));
    expect(source, isNot(contains('DriverComplianceService.')));
  });
}
