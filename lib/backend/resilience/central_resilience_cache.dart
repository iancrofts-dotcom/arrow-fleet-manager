import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CentralResilienceCacheEntry {
  const CentralResilienceCacheEntry({
    required this.payload,
    required this.savedAt,
  });

  final Object? payload;
  final DateTime savedAt;
}

class CentralResilienceCache {
  const CentralResilienceCache({this.prefix = 'fleetiq.central.cache.v1'});

  final String prefix;

  String _key(String scope, String cacheKey) => '$prefix::$scope::$cacheKey';

  Future<void> write({
    required String scope,
    required String cacheKey,
    required Object? payload,
    DateTime? savedAt,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(scope, cacheKey),
      jsonEncode(<String, Object?>{
        'savedAt': (savedAt ?? DateTime.now().toUtc()).toIso8601String(),
        'payload': payload,
      }),
    );
  }

  Future<CentralResilienceCacheEntry?> read({
    required String scope,
    required String cacheKey,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key(scope, cacheKey));
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      final savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
      if (savedAt == null) return null;
      return CentralResilienceCacheEntry(
        payload: decoded['payload'],
        savedAt: savedAt.toUtc(),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> remove({required String scope, required String cacheKey}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(scope, cacheKey));
  }

  Future<void> clearScope(String scope) async {
    final preferences = await SharedPreferences.getInstance();
    final marker = '$prefix::$scope::';
    final keys = preferences.getKeys().where((key) => key.startsWith(marker));
    for (final key in keys.toList(growable: false)) {
      await preferences.remove(key);
    }
  }
}
