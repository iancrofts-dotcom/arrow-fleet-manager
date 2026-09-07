import 'dart:async';

import 'package:arrow_fleet_manager/backend/auth/fleet_auth_adapter.dart';
import 'package:arrow_fleet_manager/backend/backend_profile.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/features/auth/screens/login_screen.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/widgets/auth_gate.dart';
import 'package:arrow_fleet_manager/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('remote gate does not expose protected shell before resolution', (
    tester,
  ) async {
    final signOut = Completer<void>();
    final auth = AuthService(enableSessionWatchdog: false)
      ..configureBackend(
        mode: BackendMode.supabase,
        remoteAuthAdapter: _DelayedSignOutAdapter(signOut.future),
      );

    await tester.pumpWidget(MaterialApp(home: AuthGate(authService: auth)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);

    signOut.complete();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });
}

class _DelayedSignOutAdapter implements FleetAuthAdapter {
  _DelayedSignOutAdapter(this.signOutFuture);

  final Future<void> signOutFuture;

  @override
  BackendProfile? get currentProfile => null;

  @override
  bool get isAuthenticated => false;

  @override
  Future<BackendProfile?> signIn({
    required String identifier,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() => signOutFuture;
}
