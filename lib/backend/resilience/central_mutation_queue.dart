import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'central_queued_mutation.dart';

class CentralMutationQueue {
  const CentralMutationQueue({
    this.storageKey = 'fleetiq.central.mutation_queue.v1',
    this.maximumEntries = 500,
  });

  final String storageKey;
  final int maximumEntries;

  Future<List<CentralQueuedMutation>> readAll() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) {
      return const <CentralQueuedMutation>[];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List<dynamic>) return const <CentralQueuedMutation>[];
      return decoded
          .map(CentralQueuedMutation.fromJson)
          .whereType<CentralQueuedMutation>()
          .toList(growable: false);
    } on FormatException {
      return const <CentralQueuedMutation>[];
    }
  }

  Future<void> enqueue(CentralQueuedMutation mutation) async {
    final entries = (await readAll()).toList(growable: true);
    if (entries.any((entry) => entry.id == mutation.id)) return;
    if (entries.length >= maximumEntries) {
      throw StateError(
        'Emergency write queue limit reached ($maximumEntries entries).',
      );
    }
    entries.add(mutation);
    await _write(entries);
  }

  Future<void> replace(CentralQueuedMutation mutation) async {
    final entries = (await readAll()).toList(growable: true);
    final index = entries.indexWhere((entry) => entry.id == mutation.id);
    if (index < 0) return;
    entries[index] = mutation;
    await _write(entries);
  }

  Future<void> remove(String id) async {
    final entries = (await readAll())
        .where((entry) => entry.id != id)
        .toList(growable: false);
    await _write(entries);
  }

  Future<void> clearScope(String scope) async {
    final entries = (await readAll())
        .where((entry) => entry.scope != scope)
        .toList(growable: false);
    await _write(entries);
  }

  Future<int> countForScope(String scope) async =>
      (await readAll()).where((entry) => entry.scope == scope).length;

  Future<void> _write(List<CentralQueuedMutation> entries) async {
    final preferences = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await preferences.remove(storageKey);
      return;
    }
    await preferences.setString(
      storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
