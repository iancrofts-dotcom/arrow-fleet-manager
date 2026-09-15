import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emergency persistence never imports SQLite or a service role', () {
    final files = Directory(
      'lib/backend/resilience',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart'));
    final source = files.map((file) => file.readAsStringSync()).join('\n');

    for (final forbidden in <String>[
      'AppDatabase',
      'sqflite',
      'SUPABASE_SERVICE_ROLE_KEY',
      'service_role',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('runtime queues only classified offline failures', () {
    final source = File(
      'lib/backend/resilience/central_resilience_runtime.dart',
    ).readAsStringSync();

    expect(source, contains('CentralFailureKind.connectivity'));
    expect(source, contains('CentralFailureKind.timeout'));
    expect(source, contains('if (!_isOfflineEligible(kind)) rethrow;'));
    expect(source, contains('replayPending'));
    expect(source, contains('scope.storageScope'));
  });

  test('queue records idempotency, attempts and last failure', () {
    final source = File(
      'lib/backend/resilience/central_queued_mutation.dart',
    ).readAsStringSync();

    expect(source, contains("'id': id"));
    expect(source, contains("'attempts': attempts"));
    expect(source, contains("'lastError': lastError"));
  });
}
