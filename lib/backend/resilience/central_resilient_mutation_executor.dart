import '../backend_client.dart';
import 'central_emergency_activation_policy.dart';
import 'central_mutation_replayer.dart';
import 'central_queued_mutation.dart';
import 'central_resilience_runtime.dart';
import 'central_resilience_scope_provider.dart';
import 'central_resilient_write_result.dart';
import 'supabase_resilience_scope_provider.dart';

/// Executes idempotent central mutations through the server-side FleetIQ
/// mutation endpoint. Connectivity/timeout failures are queued by the existing
/// resilience runtime using a real organisation + authenticated-user scope.
class CentralResilientMutationExecutor {
  CentralResilientMutationExecutor({
    CentralResilienceRuntime? runtime,
    CentralResilienceScopeProvider? scopeProvider,
    this._activationPolicy = const CentralEmergencyActivationPolicy(),
  }) : _runtime = runtime ?? CentralResilienceRuntime.instance,
       _scopeProvider = scopeProvider ?? SupabaseResilienceScopeProvider() {
    _ensureReplayHandler();
  }

  static final CentralResilientMutationExecutor instance =
      CentralResilientMutationExecutor();

  final CentralResilienceRuntime _runtime;
  final CentralResilienceScopeProvider _scopeProvider;
  final CentralEmergencyActivationPolicy _activationPolicy;
  bool _replayRegistered = false;

  Future<CentralResilientWriteResult<Object?>> execute({
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final scope = await _scopeProvider.currentScope();
    _activationPolicy.requireSafeScope(scope);
    _ensureReplayHandler();
    return _runtime.runWrite<Object?>(
      scope: scope,
      operation: operation,
      payload: payload,
      execute: (idempotencyKey) => _invoke(
        operation: operation,
        payload: payload,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<String> executeString({
    required String operation,
    required Map<String, dynamic> payload,
    required String queuedValue,
  }) async {
    final result = await execute(operation: operation, payload: payload);
    if (result.queued) return queuedValue;
    final value = result.value;
    if (value is String) return value;
    if (value is Map && value['value'] is String) {
      return value['value'] as String;
    }
    throw StateError('Central mutation returned an invalid string result.');
  }

  Future<void> executeVoid({
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await execute(operation: operation, payload: payload);
  }

  Future<Object?> executeExpectCompleted({
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final result = await execute(operation: operation, payload: payload);
    if (result.queued) {
      throw CentralWriteQueuedException(result.queueId!);
    }
    return result.value;
  }

  void _ensureReplayHandler() {
    if (_replayRegistered) return;
    _runtime.replayer.register(
      CentralMutationReplayer.wildcardOperation,
      _replay,
    );
    _replayRegistered = true;
  }

  Future<void> _replay(CentralQueuedMutation mutation) async {
    await _invoke(
      operation: mutation.operation,
      payload: mutation.payload,
      idempotencyKey: mutation.id,
    );
  }

  Future<Object?> _invoke({
    required String operation,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) => BackendClient.client.rpc(
    'fleet_apply_resilient_mutation',
    params: {
      'p_operation': operation,
      'p_payload': payload,
      'p_idempotency_key': idempotencyKey,
    },
  );
}

/// Signals that FleetIQ safely accepted an operational change into the local
/// encrypted/session-scoped recovery queue rather than completing it online.
/// UI layers may catch this and display a queued-for-sync confirmation.
class CentralWriteQueuedException implements Exception {
  const CentralWriteQueuedException(this.queueId);

  final String queueId;

  @override
  String toString() => 'Change queued for sync ($queueId).';
}
