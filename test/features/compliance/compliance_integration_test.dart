import 'package:arrow_fleet_manager/app/router.dart';
import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/services/permissions.dart';
import 'package:arrow_fleet_manager/features/auth/widgets/protected_screen.dart';
import 'package:arrow_fleet_manager/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Compliance access is limited to Administrators and Managers', () {
    expect(Permissions.canViewCompliance(_user(UserRole.admin)), isTrue);
    expect(Permissions.canViewCompliance(_user(UserRole.manager)), isTrue);
    expect(Permissions.canViewCompliance(_user(UserRole.driver)), isFalse);
  });

  testWidgets('Compliance route uses the protected-screen boundary', (
    tester,
  ) async {
    Widget? route;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            route = AppRouter.routes[AppRouter.compliance]!(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(route, isA<ProtectedScreen>());
  });

  test('Compliance is a secondary AppShell destination after Workshop', () {
    final destinations = AppShellDestinations.all;
    final workshopIndex = destinations.indexWhere(
      (destination) => destination.route == AppRouter.workshop,
    );
    final complianceIndex = destinations.indexWhere(
      (destination) => destination.route == AppRouter.compliance,
    );
    final reportsIndex = destinations.indexWhere(
      (destination) => destination.route == AppRouter.reports,
    );

    expect(complianceIndex, greaterThan(workshopIndex));
    expect(complianceIndex, lessThan(reportsIndex));
    expect(destinations[complianceIndex].label, 'Compliance');
  });
}

User _user(UserRole role) =>
    User(id: role.name, username: role.name, passwordHash: 'hash', role: role);
