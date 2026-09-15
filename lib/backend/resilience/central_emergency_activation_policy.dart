import 'central_resilience_scope.dart';

/// Fail-closed policy for enabling emergency queued writes.
///
/// FleetIQ must never activate emergency mutation replay with an inferred,
/// blank, or shared tenant identity. The tenant identifier must come from an
/// authenticated server-authoritative organisation/membership path.
class CentralEmergencyActivationPolicy {
  const CentralEmergencyActivationPolicy();

  void requireSafeScope(CentralResilienceScope scope) {
    final tenantId = scope.tenantId.trim();
    final userId = scope.userId.trim();
    if (tenantId.isEmpty) {
      throw StateError(
        'Emergency writes require a server-authoritative FleetIQ tenant ID.',
      );
    }
    if (userId.isEmpty) {
      throw StateError(
        'Emergency writes require an authenticated FleetIQ user ID.',
      );
    }
    if (_placeholderTenantIds.contains(tenantId.toLowerCase())) {
      throw StateError(
        'Emergency writes cannot use a placeholder/shared tenant scope.',
      );
    }
  }

  static const Set<String> _placeholderTenantIds = <String>{
    'default',
    'global',
    'shared',
    'unknown',
    'none',
    'single-tenant',
  };
}
