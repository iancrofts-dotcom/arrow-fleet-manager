import 'dart:async';

import 'package:arrow_fleet_manager/features/auth/screens/set_password_screen.dart';
import 'package:arrow_fleet_manager/features/auth/services/invitation_password_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements InvitationPasswordGateway {
  _FakeGateway({required this.hasSession, this.submission});

  final bool hasSession;
  final Completer<void>? submission;
  int updateCalls = 0;
  String? receivedPassword;

  @override
  Future<bool> hasInvitationSession() async => hasSession;

  @override
  Future<void> updatePassword(String password) {
    updateCalls++;
    receivedPassword = password;
    return submission?.future ?? Future<void>.value();
  }
}

Future<void> _pumpScreen(WidgetTester tester, _FakeGateway gateway) async {
  await tester.pumpWidget(
    MaterialApp(home: SetPasswordScreen(gateway: gateway)),
  );
  await tester.pump();
}

Future<void> _enterPasswords(
  WidgetTester tester,
  String password,
  String confirmation,
) async {
  await tester.enterText(find.byKey(const Key('new-password')), password);
  await tester.enterText(
    find.byKey(const Key('confirm-password')),
    confirmation,
  );
  await tester.tap(find.text('Set password'));
  await tester.pump();
}

void main() {
  testWidgets('missing or invalid invitation shows a safe state', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeGateway(hasSession: false));

    expect(find.text('Invitation unavailable'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('password shorter than eight characters is rejected', (
    tester,
  ) async {
    final gateway = _FakeGateway(hasSession: true);
    await _pumpScreen(tester, gateway);
    await _enterPasswords(tester, 'short', 'short');

    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
    expect(gateway.updateCalls, 0);
  });

  testWidgets('password mismatch is rejected', (tester) async {
    final gateway = _FakeGateway(hasSession: true);
    await _pumpScreen(tester, gateway);
    await _enterPasswords(tester, 'long-enough', 'different-password');

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(gateway.updateCalls, 0);
  });

  testWidgets('valid password invokes only the password gateway', (
    tester,
  ) async {
    final gateway = _FakeGateway(hasSession: true);
    await _pumpScreen(tester, gateway);
    await _enterPasswords(tester, 'secure-pass', 'secure-pass');

    expect(gateway.updateCalls, 1);
    expect(gateway.receivedPassword, 'secure-pass');
    expect(find.text('Password set'), findsOneWidget);
    expect(find.text('Continue to FleetIQ'), findsOneWidget);
  });

  testWidgets('submission is guarded against double taps', (tester) async {
    final pending = Completer<void>();
    final gateway = _FakeGateway(hasSession: true, submission: pending);
    await _pumpScreen(tester, gateway);

    await tester.enterText(
      find.byKey(const Key('new-password')),
      'secure-pass',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password')),
      'secure-pass',
    );
    await tester.tap(find.text('Set password'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(gateway.updateCalls, 1);
    pending.complete();
    await tester.pump();
    expect(find.text('Password set'), findsOneWidget);
  });
}
