import '../../features/drivers/models/driver.dart';
import '../../features/drivers/models/driver_identity.dart';
import 'backend_driver.dart';
import 'backend_driver_mapper.dart';
import 'central_driver_management_gateway.dart';

class CentralDriverManagementRepository {
  const CentralDriverManagementRepository(this._gateway);

  final CentralDriverManagementGateway _gateway;

  Future<Driver> createDriver(Driver driver) async {
    final row = await _gateway.createDriver(_values(driver));
    return BackendDriver.fromJson(row).toAppDriver();
  }

  Future<Driver> updateDriver(Driver driver) async {
    final id = driver.identity?.centralIdOrNull;
    if (id == null) {
      throw UnsupportedError('Central Driver update requires a Supabase UUID.');
    }
    final row = await _gateway.updateDriver(id, _values(driver));
    return BackendDriver.fromJson(row).toAppDriver();
  }

  Future<void> deleteDriver(DriverIdentity identity) async {
    final id = identity.centralIdOrNull;
    if (id == null) {
      throw UnsupportedError(
        'Central Driver deletion requires a Supabase UUID.',
      );
    }
    await _gateway.deleteDriver(id);
  }

  Future<Driver> deactivateDriver(DriverIdentity identity) async {
    final id = identity.centralIdOrNull;
    if (id == null) {
      throw UnsupportedError(
        'Central Driver deactivation requires a Supabase UUID.',
      );
    }
    final row = await _gateway.deactivateDriver(id);
    return BackendDriver.fromJson(row).toAppDriver();
  }

  Map<String, dynamic> _values(Driver driver) => {
    'first_name': driver.firstName,
    'last_name': driver.lastName,
    'licence_number': driver.licenceNumber,
    'licence_expiry': driver.licenceExpiry == null
        ? null
        : _date(driver.licenceExpiry!),
    'phone': driver.phone,
    'email': driver.email,
    'username': driver.username,
    'is_active': driver.isActive,
  };
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
