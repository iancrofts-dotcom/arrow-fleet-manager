import 'central_connection_status.dart';
import 'central_resilience_scope.dart';

class CentralResilienceStatus {
  const CentralResilienceStatus({
    required this.connection,
    required this.pendingWrites,
    required this.scope,
  });

  final CentralConnectionStatus connection;
  final int pendingWrites;
  final CentralResilienceScope scope;

  bool get hasPendingWrites => pendingWrites > 0;
}
