import 'package:arrow_fleet_manager/backend/resilience/central_connection_status.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_connection_tracker.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_failure_classifier.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_failure_kind.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_operation_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CentralFailureClassifier', () {
    const classifier = CentralFailureClassifier();

    test('recognises clear connectivity failures', () {
      expect(
        classifier.classify(Exception('SocketException: Failed host lookup')),
        CentralFailureKind.connectivity,
      );
      expect(
        classifier.classify(Exception('TypeError: Failed to fetch')),
        CentralFailureKind.connectivity,
      );
    });

    test('recognises timeouts separately', () {
      expect(
        classifier.classify(Exception('The request timed out')),
        CentralFailureKind.timeout,
      );
    });

    test('does not treat authentication or RLS failures as offline', () {
      expect(
        classifier.classify(Exception('Unauthorized status code: 401')),
        CentralFailureKind.authentication,
      );
      expect(
        classifier.classify(Exception('new row violates row-level security')),
        CentralFailureKind.authorization,
      );
    });

    test('recognises backend outage responses as server failures', () {
      expect(
        classifier.classify(Exception('503 Service Unavailable')),
        CentralFailureKind.server,
      );
    });

    test('unknown failures remain unknown', () {
      expect(
        classifier.classify(Exception('unexpected parsing problem')),
        CentralFailureKind.unknown,
      );
    });
  });

  group('CentralConnectionTracker', () {
    final fixedTime = DateTime.utc(2026, 9, 11, 12, 0);

    test('starts unknown and records successful central access', () {
      final tracker = CentralConnectionTracker(now: () => fixedTime);
      expect(tracker.status.state, CentralConnectionState.unknown);

      tracker.recordSuccess();

      expect(tracker.status.state, CentralConnectionState.online);
      expect(tracker.status.failureKind, CentralFailureKind.none);
      expect(tracker.status.lastCheckedAt, fixedTime);
    });

    test('only connectivity and timeout failures become offline', () {
      final tracker = CentralConnectionTracker(now: () => fixedTime);

      tracker.recordFailure(CentralFailureKind.connectivity);
      expect(tracker.status.state, CentralConnectionState.offline);

      tracker.recordFailure(CentralFailureKind.timeout);
      expect(tracker.status.state, CentralConnectionState.offline);

      for (final kind in <CentralFailureKind>[
        CentralFailureKind.authentication,
        CentralFailureKind.authorization,
        CentralFailureKind.server,
        CentralFailureKind.unknown,
      ]) {
        tracker.recordFailure(kind);
        expect(
          tracker.status.state,
          CentralConnectionState.degraded,
          reason: kind.name,
        );
      }
    });
  });

  group('CentralOperationGuard', () {
    test('records online after successful central operation', () async {
      final tracker = CentralConnectionTracker();
      final guard = CentralOperationGuard(tracker: tracker);

      final value = await guard.run(() async => 42);

      expect(value, 42);
      expect(tracker.status.state, CentralConnectionState.online);
    });

    test('records offline then rethrows original network failure', () async {
      final tracker = CentralConnectionTracker();
      final guard = CentralOperationGuard(tracker: tracker);
      final failure = Exception('SocketException: network is unreachable');

      await expectLater(
        guard.run<void>(() async => throw failure),
        throwsA(same(failure)),
      );
      expect(tracker.status.state, CentralConnectionState.offline);
      expect(tracker.status.failureKind, CentralFailureKind.connectivity);
    });

    test('authorization failure is degraded, never offline', () async {
      final tracker = CentralConnectionTracker();
      final guard = CentralOperationGuard(tracker: tracker);

      await expectLater(
        guard.run<void>(
          () async => throw Exception('403 Forbidden: permission denied'),
        ),
        throwsException,
      );

      expect(tracker.status.state, CentralConnectionState.degraded);
      expect(tracker.status.failureKind, CentralFailureKind.authorization);
    });
  });
}
