import 'dart:convert';

import 'central_connection_tracker.dart';
import 'central_failure_classifier.dart';
import 'central_failure_kind.dart';
import 'central_mutation_queue.dart';
import 'central_mutation_replayer.dart';
import 'central_operation_guard.dart';
import 'central_queued_mutation.dart';
import 'central_replay_report.dart';
import 'central_resilience_cache.dart';
import 'central_resilience_scope.dart';
import 'central_resilient_write_result.dart';

class CentralResilienceRuntime {
  CentralResilienceRuntime._({
    this._cache = const CentralResilienceCache(),
    this._queue = const CentralMutationQueue(),
    this._classifier = const CentralFailureClassifier(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static final CentralResilienceRuntime instance = CentralResilienceRuntime._();

  factory CentralResilienceRuntime.forTesting({
    CentralResilienceCache cache = const CentralResilienceCache(),
    CentralMutationQueue queue = const CentralMutationQueue(),
    CentralFailureClassifier classifier = const CentralFailureClassifier(),
    DateTime Function()? now,
  }) => CentralResilienceRuntime._(
    cache: cache,
    queue: queue,
    classifier: classifier,
    now: now,
  );

  final CentralResilienceCache _cache;
  final CentralMutationQueue _queue;
  final CentralFailureClassifier _classifier;
  final DateTime Function() _now;
  final CentralMutationReplayer replayer = CentralMutationReplayer();

  final CentralConnectionTracker tracker = CentralConnectionTracker();

  late final CentralOperationGuard _guard = CentralOperationGuard(
    tracker: tracker,
  );

  int _sequence = 0;

  Future<T> run<T>(Future<T> Function() operation) => _guard.run(operation);

  /// Runs a central read and stores a last-known-good JSON-safe representation.
  ///
  /// Cache fallback is permitted only for connectivity and timeout failures.
  /// Authentication, authorization, server, and unknown failures are surfaced
  /// normally so FleetIQ never disguises security or server faults as offline.
  Future<T> runCached<T>({
    required CentralResilienceScope scope,
    required String cacheKey,
    required Future<T> Function() operation,
    required Object? Function(T value) encode,
    required T Function(Object? payload) decode,
    Duration? maximumAge,
  }) async {
    final storageScope = scope.storageScope;
    try {
      final result = await operation();
      tracker.recordSuccess();
      await _cache.write(
        scope: storageScope,
        cacheKey: cacheKey,
        payload: encode(result),
        savedAt: _now().toUtc(),
      );
      return result;
    } catch (error) {
      final kind = _classifier.classify(error);
      tracker.recordFailure(kind, message: error.toString());
      if (!_isOfflineEligible(kind)) rethrow;

      final cached = await _cache.read(scope: storageScope, cacheKey: cacheKey);
      if (cached == null) rethrow;
      if (maximumAge != null &&
          _now().toUtc().difference(cached.savedAt) > maximumAge) {
        rethrow;
      }
      return decode(cached.payload);
    }
  }

  /// Runs a central mutation. Only confirmed connectivity/timeout failures can
  /// be queued. Security, validation, RLS, server, and unknown failures rethrow.
  ///
  /// The caller supplies a JSON-safe payload plus a stable operation name. The
  /// queued mutation receives an idempotency key (`id`) that must be forwarded
  /// by the replay handler to the server-side mutation path where supported.
  Future<CentralResilientWriteResult<T>> runWrite<T>({
    required CentralResilienceScope scope,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<T> Function(String idempotencyKey) execute,
  }) async {
    final queueId = _newQueueId(scope.storageScope, operation);
    try {
      final value = await execute(queueId);
      tracker.recordSuccess();
      return CentralResilientWriteResult<T>.completed(value);
    } catch (error) {
      final kind = _classifier.classify(error);
      tracker.recordFailure(kind, message: error.toString());
      if (!_isOfflineEligible(kind)) rethrow;

      await _queue.enqueue(
        CentralQueuedMutation(
          id: queueId,
          scope: scope.storageScope,
          operation: operation.trim(),
          payload: _jsonSafePayload(payload),
          createdAt: _now().toUtc(),
        ),
      );
      return CentralResilientWriteResult<T>.queued(queueId);
    }
  }

  Future<int> pendingWrites(CentralResilienceScope scope) =>
      _queue.countForScope(scope.storageScope);

  /// Replays queued writes in creation order for the current tenant/user scope.
  ///
  /// Replay stops immediately on connectivity/timeout so later operations retain
  /// ordering. Non-connectivity failures are recorded on that queue item and are
  /// left for explicit operator/recovery handling; replay then continues with the
  /// next item to avoid one validation conflict permanently blocking the queue.
  Future<CentralReplayReport> replayPending(
    CentralResilienceScope scope,
  ) async {
    final storageScope = scope.storageScope;
    final all = await _queue.readAll();
    final pending =
        all
            .where((entry) => entry.scope == storageScope)
            .toList(growable: false)
          ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    var examined = 0;
    var replayed = 0;
    var stoppedForConnectivity = false;

    for (final mutation in pending) {
      examined += 1;
      if (!replayer.canReplay(mutation.operation)) {
        await _queue.replace(
          mutation.copyWith(
            attempts: mutation.attempts + 1,
            lastAttemptAt: _now().toUtc(),
            lastError:
                'No replay handler registered for ${mutation.operation}.',
          ),
        );
        continue;
      }

      try {
        await replayer.replay(mutation);
        tracker.recordSuccess();
        await _queue.remove(mutation.id);
        replayed += 1;
      } catch (error) {
        final kind = _classifier.classify(error);
        tracker.recordFailure(kind, message: error.toString());
        await _queue.replace(
          mutation.copyWith(
            attempts: mutation.attempts + 1,
            lastAttemptAt: _now().toUtc(),
            lastError: error.toString(),
          ),
        );
        if (_isOfflineEligible(kind)) {
          stoppedForConnectivity = true;
          break;
        }
      }
    }

    return CentralReplayReport(
      examined: examined,
      replayed: replayed,
      remaining: await _queue.countForScope(storageScope),
      stoppedForConnectivity: stoppedForConnectivity,
    );
  }

  Future<void> clearEmergencyState(CentralResilienceScope scope) async {
    final storageScope = scope.storageScope;
    await _cache.clearScope(storageScope);
    await _queue.clearScope(storageScope);
  }

  bool _isOfflineEligible(CentralFailureKind kind) =>
      kind == CentralFailureKind.connectivity ||
      kind == CentralFailureKind.timeout;

  String _newQueueId(String storageScope, String operation) {
    _sequence += 1;
    final stamp = _now().toUtc().microsecondsSinceEpoch;
    final seed = '$storageScope|${operation.trim()}|$stamp|$_sequence';
    final encoded = base64Url.encode(utf8.encode(seed)).replaceAll('=', '');
    return 'fleetiq_$encoded';
  }

  Map<String, dynamic> _jsonSafePayload(Map<String, dynamic> payload) {
    final encoded = jsonEncode(payload);
    final decoded = jsonDecode(encoded);
    return Map<String, dynamic>.from(decoded as Map);
  }
}
