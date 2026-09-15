import 'package:arrow_fleet_manager/backend/resilience/central_resilience_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('cache isolates records by tenant and user scope', () async {
    const cache = CentralResilienceCache();
    await cache.write(
      scope: 'tenant-a::user-1',
      cacheKey: 'vehicles',
      payload: <String, Object>{'count': 3},
      savedAt: DateTime.utc(2026, 9, 11, 12),
    );

    final same = await cache.read(
      scope: 'tenant-a::user-1',
      cacheKey: 'vehicles',
    );
    final otherTenant = await cache.read(
      scope: 'tenant-b::user-1',
      cacheKey: 'vehicles',
    );

    expect((same!.payload as Map<String, dynamic>)['count'], 3);
    expect(otherTenant, isNull);
  });

  test('corrupt cache is treated as unavailable', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'fleetiq.central.cache.v1::tenant::user::calendar',
      '{broken',
    );

    final entry = await const CentralResilienceCache().read(
      scope: 'tenant::user',
      cacheKey: 'calendar',
    );
    expect(entry, isNull);
  });
}
