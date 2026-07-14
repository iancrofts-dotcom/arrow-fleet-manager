import 'driver.dart';

class DriverAssignmentResult {
  const DriverAssignmentResult({
    required this.cancelled,
    this.driver,
  });

  final bool cancelled;
  final Driver? driver;

  bool get removeAssignment =>
      !cancelled && driver == null;

  bool get hasDriver =>
      !cancelled && driver != null;
}