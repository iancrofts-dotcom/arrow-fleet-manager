import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default backend mode is local', () {
    expect(BackendModeConfig.current, BackendMode.local);
  });

  test('parses explicit local and Supabase modes', () {
    expect(BackendModeConfig.parse('local'), BackendMode.local);
    expect(BackendModeConfig.parse('supabase'), BackendMode.supabase);
  });

  test('invalid backend mode fails closed', () {
    expect(() => BackendModeConfig.parse('automatic'), throwsStateError);
    expect(
      BackendModeConfig.validate(
        mode: 'automatic',
        supabaseUrl: '',
        supabasePublishableKey: '',
      ),
      isNotNull,
    );
  });

  test('local mode does not require Supabase configuration', () {
    expect(
      BackendModeConfig.validate(
        mode: 'local',
        supabaseUrl: '',
        supabasePublishableKey: '',
      ),
      isNull,
    );
  });

  test('Supabase mode requires a valid URL and publishable key', () {
    expect(
      BackendModeConfig.validate(
        mode: 'supabase',
        supabaseUrl: '',
        supabasePublishableKey: '',
      ),
      isNotNull,
    );
    expect(
      BackendModeConfig.validate(
        mode: 'supabase',
        supabaseUrl: 'https://fleet.test',
        supabasePublishableKey: 'publishable-key',
      ),
      isNull,
    );
  });
}
