import 'dart:async';

import 'central_connection_status.dart';
import 'central_resilience_runtime.dart';
import 'central_resilience_scope_provider.dart';
import 'central_resilient_mutation_executor.dart';
import 'supabase_resilience_scope_provider.dart';

/// Starts one conservative recovery loop for central mode.
///
/// No polling is used. Replay is attempted only after the existing connection
/// tracker reports an online transition, and only for the authenticated user's
/// previously server-confirmed organisation scope.
class CentralOfflineSyncService {
  CentralOfflineSyncService({
    CentralResilienceRuntime? runtime,
    CentralResilienceScopeProvider? scopeProvider,
  }) : _runtime = runtime ?? CentralResilienceRuntime.instance,
       _scopeProvider = scopeProvider ?? SupabaseResilienceScopeProvider();

  static final CentralOfflineSyncService instance = CentralOfflineSyncService();

  final CentralResilienceRuntime _runtime;
  final CentralResilienceScopeProvider _scopeProvider;
  bool _started = false;
  bool _replaying = false;
  CentralConnectionState _previousState = CentralConnectionState.unknown;

  void start() {
    if (_started) return;
    _started = true;
    // Force construction so the wildcard replay endpoint is registered before
    // the first online recovery attempt.
    CentralResilientMutationExecutor.instance;
    _previousState = _runtime.tracker.status.state;
    _runtime.tracker.addListener(_handleConnectionChange);
  }

  Future<void> flushNow() => _replayIfPossible();

  void _handleConnectionChange() {
    final next = _runtime.tracker.status.state;
    final becameOnline =
        next == CentralConnectionState.online &&
        _previousState != CentralConnectionState.online;
    _previousState = next;
    if (becameOnline) {
      unawaited(_replayIfPossible());
    }
  }

  Future<void> _replayIfPossible() async {
    if (_replaying) return;
    _replaying = true;
    try {
      final scope = await _scopeProvider.currentScope();
      if (await _runtime.pendingWrites(scope) == 0) return;
      await _runtime.replayPending(scope);
    } catch (_) {
      // Fail closed. Authentication, membership, authorization and server
      // failures remain visible through their normal app paths; this service
      // never clears or cross-replays queued writes after a failed scope check.
    } finally {
      _replaying = false;
    }
  }
}
