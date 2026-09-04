enum SecurityAuditEventType {
  userCreated,
  userUpdated,
  userActivated,
  userDeactivated,
  roleChanged,
  passwordChangedByAdministrator,
  userDeleted,
  driverUsernameSynced,
}

class SecurityAuditEvent {
  const SecurityAuditEvent({
    this.id,
    required this.type,
    required this.occurredAt,
    this.actorUserId,
    this.actorUsername,
    this.targetUserId,
    this.targetUsername,
    this.detail,
  });

  final int? id;
  final SecurityAuditEventType type;
  final DateTime occurredAt;
  final String? actorUserId;
  final String? actorUsername;
  final String? targetUserId;
  final String? targetUsername;
  final String? detail;

  Map<String, Object?> toMap() => {
    'event_type': type.name,
    'occurred_at': occurredAt.toIso8601String(),
    'actor_user_id': actorUserId,
    'actor_username': actorUsername,
    'target_user_id': targetUserId,
    'target_username': targetUsername,
    'detail': detail,
  };

  factory SecurityAuditEvent.fromMap(Map<String, Object?> map) =>
      SecurityAuditEvent(
        id: map['id'] as int?,
        type: SecurityAuditEventType.values.firstWhere(
          (type) => type.name == map['event_type'],
        ),
        occurredAt: DateTime.parse(map['occurred_at']! as String),
        actorUserId: map['actor_user_id'] as String?,
        actorUsername: map['actor_username'] as String?,
        targetUserId: map['target_user_id'] as String?,
        targetUsername: map['target_username'] as String?,
        detail: map['detail'] as String?,
      );
}
