import 'package:arrow_fleet_manager/backend/resilience/central_connection_status.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_failure_kind.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_resilience_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final runtime = CentralResilienceRuntime.instance;

  setUp(runtime.tracker.reset);
  tearDown(runtime.tracker.reset);

  test('successful guarded runtime operation records central online', () async {
    final result = await runtime.run(() async => 42);

    expect(result, 42);
    expect(runtime.tracker.status.state, CentralConnectionState.online);
    expect(runtime.tracker.status.failureKind, CentralFailureKind.none);
  });

  test('network loss records offline and rethrows original error', () async {
    await expectLater(
      runtime.run<void>(() async => throw Exception('Failed host lookup')),
      throwsA(isA<Exception>()),
    );

    expect(runtime.tracker.status.state, CentralConnectionState.offline);
    expect(runtime.tracker.status.failureKind, CentralFailureKind.connectivity);
  });

  test('authorization failure is degraded and never offline', () async {
    await expectLater(
      runtime.run<void>(() async => throw Exception('403 permission denied')),
      throwsA(isA<Exception>()),
    );

    expect(runtime.tracker.status.state, CentralConnectionState.degraded);
    expect(
      runtime.tracker.status.failureKind,
      CentralFailureKind.authorization,
    );
    expect(runtime.tracker.status.isOffline, isFalse);
  });

  test('later successful central operation restores online state', () async {
    await expectLater(
      runtime.run<void>(() async => throw Exception('Network request failed')),
      throwsA(isA<Exception>()),
    );
    expect(runtime.tracker.status.isOffline, isTrue);

    await runtime.run(() async => 'ok');

    expect(runtime.tracker.status.isOnline, isTrue);
  });
}
