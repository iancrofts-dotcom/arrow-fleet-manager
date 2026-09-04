import 'package:arrow_fleet_manager/features/auth/models/security_audit_event.dart';
import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/services/security_audit_service.dart';
import 'package:sqflite/sqflite.dart';

class FakeSecurityAuditService extends SecurityAuditService {
  FakeSecurityAuditService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final events = <SecurityAuditEvent>[];

  @override
  Future<void> record({
    required SecurityAuditEventType type,
    User? actor,
    User? target,
    String? detail,
    DatabaseExecutor? executor,
  }) async {
    events.add(
      SecurityAuditEvent(
        type: type,
        occurredAt: _now(),
        actorUserId: actor?.id,
        actorUsername: actor?.username,
        targetUserId: target?.id,
        targetUsername: target?.username,
        detail: detail,
      ),
    );
  }
}
