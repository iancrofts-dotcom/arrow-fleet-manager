import '../../../backend/drivers/backend_driver_mapper.dart';
import '../../../backend/drivers/backend_driver_repository.dart';
import '../models/driver.dart';
import '../models/driver_identity.dart';
import 'driver_data_source.dart';

class SupabaseDriverDataSource implements DriverDataSource {
  const SupabaseDriverDataSource(this._repository);

  final BackendDriverRepository _repository;

  @override
  Future<List<Driver>> listDrivers() async => (await _repository.listDrivers())
      .map((driver) => driver.toAppDriver())
      .toList();

  @override
  Future<Driver?> getDriver(DriverIdentity identity) async {
    final driver = await _repository.getDriver(
      identity.centralIdOrNull ??
          (throw UnsupportedError('Central Driver lookup requires a UUID.')),
    );
    return driver?.toAppDriver();
  }
}
