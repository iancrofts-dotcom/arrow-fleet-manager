import 'dart:io';

import 'package:arrow_fleet_manager/backend/resilience/central_emergency_activation_policy.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_resilience_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = CentralEmergencyActivationPolicy();

  test('emergency activation accepts an explicit tenant and user scope', () {
    expect(
      () => policy.requireSafeScope(
        const CentralResilienceScope(
          tenantId: 'organisation-123',
          userId: 'user-456',
        ),
      ),
      returnsNormally,
    );
  });

  test('emergency activation fails closed without tenant identity', () {
    expect(
      () => policy.requireSafeScope(
        const CentralResilienceScope(tenantId: '', userId: 'user-456'),
      ),
      throwsStateError,
    );
  });

  test('emergency activation fails closed without user identity', () {
    expect(
      () => policy.requireSafeScope(
        const CentralResilienceScope(tenantId: 'organisation-123', userId: ''),
      ),
      throwsStateError,
    );
  });

  test('shared placeholder tenant scopes are rejected', () {
    for (final tenant in <String>['default', 'global', 'shared', 'unknown']) {
      expect(
        () => policy.requireSafeScope(
          CentralResilienceScope(tenantId: tenant, userId: 'user-456'),
        ),
        throwsStateError,
        reason: tenant,
      );
    }
  });

  test('Build 17.4.6.4 does not add a fake organisation migration', () {
    final directory = Directory('supabase/migrations');
    if (!directory.existsSync()) return;
    final names = directory
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.contains('17_4_6_4'));
    expect(names, isEmpty);
  });
}
