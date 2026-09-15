import 'package:arrow_fleet_manager/backend/resilience/central_failure_kind.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_resilience_runtime.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_resilience_scope.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_resilient_write_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NetworkFailure implements Exception {
  const _NetworkFailure();
  @override
  String toString() => 'SocketException: network unreachable';
}

class _AuthorizationFailure implements Exception {
  const _AuthorizationFailure();
  @override
  String toString() => 'permission denied by row-level security';
}

void main() {
  const scope = CentralResilienceScope(tenantId: 'tenant-1', userId: 'user-1');

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('successful central read seeds last-known-good cache', () async {
    final runtime = CentralResilienceRuntime.forTesting(
      now: () => DateTime.utc(2026, 9, 11, 12),
    );

    final result = await runtime.runCached<List<String>>(
      scope: scope,
      cacheKey: 'vehicles',
      operation: () async => <String>['A', 'B'],
      encode: (value) => value,
      decode: (payload) => (payload! as List<dynamic>).cast<String>(),
    );

    expect(result, <String>['A', 'B']);
    expect(runtime.tracker.status.isOnline, isTrue);
  });

  test('network failure uses last-known-good read cache', () async {
    var now = DateTime.utc(2026, 9, 11, 12);
    final runtime = CentralResilienceRuntime.forTesting(now: () => now);

    await runtime.runCached<List<String>>(
      scope: scope,
      cacheKey: 'vehicles',
      operation: () async => <String>['cached'],
      encode: (value) => value,
      decode: (payload) => (payload! as List<dynamic>).cast<String>(),
    );

    now = now.add(const Duration(minutes: 5));
    final result = await runtime.runCached<List<String>>(
      scope: scope,
      cacheKey: 'vehicles',
      operation: () async => throw const _NetworkFailure(),
      encode: (value) => value,
      decode: (payload) => (payload! as List<dynamic>).cast<String>(),
      maximumAge: const Duration(hours: 2),
    );

    expect(result, <String>['cached']);
    expect(runtime.tracker.status.isOffline, isTrue);
  });

  test('authorization failure never falls back to cache', () async {
    final runtime = CentralResilienceRuntime.forTesting();
    await runtime.runCached<String>(
      scope: scope,
      cacheKey: 'secret',
      operation: () async => 'cached',
      encode: (value) => value,
      decode: (payload) => payload! as String,
    );

    await expectLater(
      runtime.runCached<String>(
        scope: scope,
        cacheKey: 'secret',
        operation: () async => throw const _AuthorizationFailure(),
        encode: (value) => value,
        decode: (payload) => payload! as String,
      ),
      throwsA(isA<_AuthorizationFailure>()),
    );
    expect(
      runtime.tracker.status.failureKind,
      CentralFailureKind.authorization,
    );
    expect(runtime.tracker.status.isOffline, isFalse);
  });

  test('network write is queued and returns queue id', () async {
    final runtime = CentralResilienceRuntime.forTesting(
      now: () => DateTime.utc(2026, 9, 11, 12),
    );

    final result = await runtime.runWrite<String>(
      scope: scope,
      operation: 'vehicle.update',
      payload: <String, dynamic>{'id': 'v1', 'registration': 'AB12 CDE'},
      execute: (_) async => throw const _NetworkFailure(),
    );

    expect(result.disposition, CentralWriteDisposition.queued);
    expect(result.queueId, startsWith('fleetiq_'));
    expect(await runtime.pendingWrites(scope), 1);
  });

  test('authorization write is not queued', () async {
    final runtime = CentralResilienceRuntime.forTesting();

    await expectLater(
      runtime.runWrite<String>(
        scope: scope,
        operation: 'vehicle.update',
        payload: <String, dynamic>{'id': 'v1'},
        execute: (_) async => throw const _AuthorizationFailure(),
      ),
      throwsA(isA<_AuthorizationFailure>()),
    );
    expect(await runtime.pendingWrites(scope), 0);
  });

  test(
    'replay removes completed mutation and preserves idempotency id',
    () async {
      final runtime = CentralResilienceRuntime.forTesting(
        now: () => DateTime.utc(2026, 9, 11, 12),
      );

      final queued = await runtime.runWrite<void>(
        scope: scope,
        operation: 'vehicle.update',
        payload: <String, dynamic>{'id': 'v1'},
        execute: (_) async => throw const _NetworkFailure(),
      );
      final expectedId = queued.queueId;
      String? replayId;

      runtime.replayer.register('vehicle.update', (mutation) async {
        replayId = mutation.id;
      });

      final report = await runtime.replayPending(scope);
      expect(report.replayed, 1);
      expect(report.remaining, 0);
      expect(replayId, expectedId);
    },
  );

  test(
    'replay stops on renewed connectivity loss to preserve ordering',
    () async {
      final runtime = CentralResilienceRuntime.forTesting(
        now: () => DateTime.utc(2026, 9, 11, 12),
      );

      for (final id in <String>['v1', 'v2']) {
        await runtime.runWrite<void>(
          scope: scope,
          operation: 'vehicle.update',
          payload: <String, dynamic>{'id': id},
          execute: (_) async => throw const _NetworkFailure(),
        );
      }

      runtime.replayer.register(
        'vehicle.update',
        (_) async => throw const _NetworkFailure(),
      );

      final report = await runtime.replayPending(scope);
      expect(report.examined, 1);
      expect(report.replayed, 0);
      expect(report.remaining, 2);
      expect(report.stoppedForConnectivity, isTrue);
    },
  );

  test('scope refuses empty tenant or user identifiers', () {
    expect(
      () => const CentralResilienceScope(
        tenantId: '',
        userId: 'user',
      ).storageScope,
      throwsA(isA<StateError>()),
    );
  });
}
