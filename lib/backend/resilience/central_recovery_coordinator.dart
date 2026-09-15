import 'central_emergency_activation_policy.dart';
import 'central_replay_report.dart';
import 'central_resilience_runtime.dart';
import 'central_resilience_scope.dart';

/// Coordinates explicit recovery after central connectivity returns.
///
/// This class does not invent tenant identity and does not automatically replay
/// on app startup. Callers must resolve the current authenticated tenant/user
/// scope from a server-authoritative membership source before replay.
class CentralRecoveryCoordinator {
  CentralRecoveryCoordinator({
    CentralResilienceRuntime? runtime,
    this._activationPolicy = const CentralEmergencyActivationPolicy(),
  }) : _runtime = runtime ?? CentralResilienceRuntime.instance;

  final CentralResilienceRuntime _runtime;
  final CentralEmergencyActivationPolicy _activationPolicy;

  Future<int> pendingWrites(CentralResilienceScope scope) {
    _activationPolicy.requireSafeScope(scope);
    return _runtime.pendingWrites(scope);
  }

  Future<CentralReplayReport> replay(CentralResilienceScope scope) {
    _activationPolicy.requireSafeScope(scope);
    return _runtime.replayPending(scope);
  }

  Future<void> clearEmergencyState(CentralResilienceScope scope) {
    _activationPolicy.requireSafeScope(scope);
    return _runtime.clearEmergencyState(scope);
  }
}
