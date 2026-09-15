import 'central_queued_mutation.dart';

typedef CentralMutationReplayHandler =
    Future<void> Function(CentralQueuedMutation mutation);

class CentralMutationReplayer {
  static const wildcardOperation = '*';

  final Map<String, CentralMutationReplayHandler> _handlers =
      <String, CentralMutationReplayHandler>{};

  void register(String operation, CentralMutationReplayHandler handler) {
    final normalized = operation.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(operation, 'operation', 'Must not be empty.');
    }
    _handlers[normalized] = handler;
  }

  void unregister(String operation) {
    _handlers.remove(operation.trim());
  }

  bool canReplay(String operation) =>
      _handlers.containsKey(operation.trim()) ||
      _handlers.containsKey(wildcardOperation);

  Future<void> replay(CentralQueuedMutation mutation) async {
    final handler =
        _handlers[mutation.operation] ?? _handlers[wildcardOperation];
    if (handler == null) {
      throw StateError(
        'No emergency replay handler registered for ${mutation.operation}.',
      );
    }
    await handler(mutation);
  }
}
