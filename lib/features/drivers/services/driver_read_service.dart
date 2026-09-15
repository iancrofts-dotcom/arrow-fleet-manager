import '../../../backend/drivers/backend_driver_repository.dart';
import '../../../backend/drivers/supabase_driver_gateway.dart';
import '../../../config/backend_mode.dart';
import '../models/driver.dart';
import '../models/driver_identity.dart';
import 'driver_data_source.dart';
import 'local_driver_data_source.dart';
import 'supabase_driver_data_source.dart';

class DriverReadService {
  const DriverReadService(this._dataSource);

  factory DriverReadService.forConfiguredBackend() =>
      DriverReadService.forMode(BackendModeConfig.current);

  factory DriverReadService.forMode(
    BackendMode mode, {
    DriverDataSource? localDataSource,
    DriverDataSource? supabaseDataSource,
  }) => switch (mode) {
    BackendMode.local => DriverReadService(
      localDataSource ?? LocalDriverDataSource(),
    ),
    BackendMode.supabase => DriverReadService(
      supabaseDataSource ??
          SupabaseDriverDataSource(
            BackendDriverRepository(SupabaseDriverGateway()),
          ),
    ),
  };

  final DriverDataSource _dataSource;

  Future<List<Driver>> getDrivers() => _dataSource.listDrivers();

  Future<Driver?> getDriver(DriverIdentity identity) =>
      _dataSource.getDriver(identity);
}
