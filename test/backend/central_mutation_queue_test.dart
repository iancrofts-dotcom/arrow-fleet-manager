import 'package:arrow_fleet_manager/backend/resilience/central_mutation_queue.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_queued_mutation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  CentralQueuedMutation mutation(String id, String scope) =>
      CentralQueuedMutation(
        id: id,
        scope: scope,
        operation: 'vehicle.update',
        payload: <String, dynamic>{'id': 'vehicle-1'},
        createdAt: DateTime.utc(2026, 9, 11, 12),
      );

  test('queue persists and deduplicates idempotency ids', () async {
    const queue = CentralMutationQueue();
    await queue.enqueue(mutation('q1', 'tenant::user'));
    await queue.enqueue(mutation('q1', 'tenant::user'));

    final entries = await queue.readAll();
    expect(entries, hasLength(1));
    expect(entries.single.id, 'q1');
  });

  test('scope clear never removes another tenant queue', () async {
    const queue = CentralMutationQueue();
    await queue.enqueue(mutation('a', 'tenant-a::user'));
    await queue.enqueue(mutation('b', 'tenant-b::user'));

    await queue.clearScope('tenant-a::user');

    final entries = await queue.readAll();
    expect(entries.map((entry) => entry.id), <String>['b']);
  });

  test(
    'queue enforces maximum capacity instead of silently dropping writes',
    () async {
      const queue = CentralMutationQueue(maximumEntries: 1);
      await queue.enqueue(mutation('a', 'tenant::user'));

      expect(
        () => queue.enqueue(mutation('b', 'tenant::user')),
        throwsA(isA<StateError>()),
      );
    },
  );
}
