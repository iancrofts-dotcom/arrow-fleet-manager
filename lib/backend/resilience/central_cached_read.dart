import 'central_resilience_runtime.dart';
import 'central_resilience_scope_provider.dart';
import 'supabase_resilience_scope_provider.dart';

/// Tenant/user-scoped last-known-good cache wrapper for JSON-safe central reads.
///
/// Only confirmed connectivity/timeout failures may use cache fallback. Auth,
/// RLS, server and unknown failures continue to surface normally through
/// [CentralResilienceRuntime].
class CentralCachedRead {
  CentralCachedRead({
    CentralResilienceRuntime? runtime,
    CentralResilienceScopeProvider? scopeProvider,
  }) : _runtime = runtime ?? CentralResilienceRuntime.instance,
       _scopeProvider = scopeProvider ?? SupabaseResilienceScopeProvider();

  final CentralResilienceRuntime _runtime;
  final CentralResilienceScopeProvider _scopeProvider;

  Future<List<Map<String, dynamic>>> list({
    required String cacheKey,
    required Future<List<Map<String, dynamic>>> Function() operation,
    Duration? maximumAge,
  }) async {
    final scope = await _scopeProvider.currentScope();
    return _runtime.runCached<List<Map<String, dynamic>>>(
      scope: scope,
      cacheKey: cacheKey,
      operation: operation,
      maximumAge: maximumAge,
      encode: (rows) => rows,
      decode: (payload) {
        if (payload is! List) {
          throw StateError('Cached FleetIQ list payload was invalid.');
        }
        return payload
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
      },
    );
  }

  Future<Map<String, dynamic>?> maybeSingle({
    required String cacheKey,
    required Future<Map<String, dynamic>?> Function() operation,
    Duration? maximumAge,
  }) async {
    final scope = await _scopeProvider.currentScope();
    return _runtime.runCached<Map<String, dynamic>?>(
      scope: scope,
      cacheKey: cacheKey,
      operation: operation,
      maximumAge: maximumAge,
      encode: (row) => row,
      decode: (payload) {
        if (payload == null) return null;
        if (payload is! Map) {
          throw StateError('Cached FleetIQ record payload was invalid.');
        }
        return Map<String, dynamic>.from(payload);
      },
    );
  }
}
