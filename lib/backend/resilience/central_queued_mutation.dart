class CentralQueuedMutation {
  const CentralQueuedMutation({
    required this.id,
    required this.scope,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastAttemptAt,
    this.lastError,
  });

  final String id;
  final String scope;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final DateTime? lastAttemptAt;
  final String? lastError;

  CentralQueuedMutation copyWith({
    int? attempts,
    DateTime? lastAttemptAt,
    String? lastError,
    bool clearLastError = false,
  }) {
    return CentralQueuedMutation(
      id: id,
      scope: scope,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'scope': scope,
    'operation': operation,
    'payload': payload,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
    'lastAttemptAt': lastAttemptAt?.toUtc().toIso8601String(),
    'lastError': lastError,
  };

  static CentralQueuedMutation? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id']?.toString() ?? '';
    final scope = value['scope']?.toString() ?? '';
    final operation = value['operation']?.toString() ?? '';
    final createdAt = DateTime.tryParse(value['createdAt']?.toString() ?? '');
    final payload = value['payload'];
    if (id.isEmpty ||
        scope.isEmpty ||
        operation.isEmpty ||
        createdAt == null ||
        payload is! Map<String, dynamic>) {
      return null;
    }

    return CentralQueuedMutation(
      id: id,
      scope: scope,
      operation: operation,
      payload: Map<String, dynamic>.from(payload),
      createdAt: createdAt.toUtc(),
      attempts: value['attempts'] is int ? value['attempts'] as int : 0,
      lastAttemptAt: DateTime.tryParse(
        value['lastAttemptAt']?.toString() ?? '',
      )?.toUtc(),
      lastError: value['lastError']?.toString(),
    );
  }
}
