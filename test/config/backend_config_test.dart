import 'package:arrow_fleet_manager/config/backend_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a valid HTTPS configuration', () {
    expect(
      BackendConfig.validate(url: 'https://fleet.test', publishableKey: 'key'),
      isNull,
    );
  });
  test('rejects missing and malformed configuration without leaking a key', () {
    expect(
      BackendConfig.validate(url: '', publishableKey: 'secret'),
      isNotNull,
    );
    expect(
      BackendConfig.validate(url: 'ftp://fleet.test', publishableKey: 'secret'),
      isNotNull,
    );
    expect(
      BackendConfig.validate(url: 'https://fleet.test', publishableKey: ''),
      isNotNull,
    );
  });
}
