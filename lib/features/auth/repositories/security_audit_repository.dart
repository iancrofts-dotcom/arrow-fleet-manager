import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../models/security_audit_event.dart';

class SecurityAuditRepository {
  SecurityAuditRepository({AppDatabase? database})
    : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<void> insert(
    SecurityAuditEvent event, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _database.database();
    await db.insert('security_audit_events', event.toMap());
  }

  Future<List<SecurityAuditEvent>> listRecent({int limit = 100}) async {
    final db = await _database.database();
    final rows = await db.query(
      'security_audit_events',
      orderBy: 'occurred_at DESC, id DESC',
      limit: limit,
    );
    return rows
        .map((row) => SecurityAuditEvent.fromMap(row))
        .toList(growable: false);
  }
}
