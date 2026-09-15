import 'central_resilience_scope.dart';

abstract interface class CentralResilienceScopeProvider {
  Future<CentralResilienceScope> currentScope();
}
