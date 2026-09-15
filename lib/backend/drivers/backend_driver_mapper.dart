import '../../features/drivers/models/driver.dart';
import '../../features/drivers/models/driver_identity.dart';
import 'backend_driver.dart';

extension BackendDriverMapper on BackendDriver {
  Driver toAppDriver() => Driver(
    identity: DriverIdentity.central(id),
    firstName: firstName,
    lastName: lastName,
    licenceNumber: licenceNumber,
    licenceExpiry: licenceExpiry,
    phone: phone,
    email: email,
    username: username,
    isActive: isActive,
  );
}
