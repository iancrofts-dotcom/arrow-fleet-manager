import '../models/security_audit_event.dart';
import '../models/user.dart';
import '../repositories/security_audit_repository.dart';
import 'package:sqflite/sqflite.dart';

class SecurityAuditService {
  SecurityAuditService({
    SecurityAuditRepository? repository,
    DateTime Function()? now,
  }) : _repository = repository ?? SecurityAuditRepository(),
       _now = now ?? DateTime.now;

  final SecurityAuditRepository _repository;
  final DateTime Function() _now;

  Future<void> record({
    required SecurityAuditEventType type,
    User? actor,
    User? target,
    String? detail,
    DatabaseExecutor? executor,
  }) {
    return _repository.insert(
      SecurityAuditEvent(
        type: type,
        occurredAt: _now(),
        actorUserId: actor?.id,
        actorUsername: actor?.username,
        targetUserId: target?.id,
        targetUsername: target?.username,
        detail: detail,
      ),
      executor: executor,
    );
  }

  Future<List<SecurityAuditEvent>> listRecent({int limit = 100}) =>
      _repository.listRecent(limit: limit);
}
