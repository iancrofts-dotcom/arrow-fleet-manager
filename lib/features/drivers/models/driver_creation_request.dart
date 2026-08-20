import 'driver.dart';

/// In-memory input for creating a Driver and its linked login account.
///
/// The password is intentionally not part of [Driver] or any persisted map.
class DriverCreationRequest {
  const DriverCreationRequest({required this.driver, required this.password});

  final Driver driver;
  final String password;
}
