import '../../documents/services/document_service.dart';
import '../../drivers/services/driver_compliance_service.dart';
import '../../drivers/services/driver_service.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../../maintenance/services/maintenance_service.dart';

import '../mappers/compliance_calendar_mapper.dart';
import '../mappers/document_calendar_mapper.dart';
import '../mappers/maintenance_calendar_mapper.dart';
import '../mappers/vehicle_calendar_mapper.dart';
import '../models/calendar_event.dart';

class CalendarService {
  CalendarService({
    VehicleService? vehicleService,
    MaintenanceService? maintenanceService,
    DocumentService? documentService,
    DriverService? driverService,
    DriverComplianceService? complianceService,
  })  : _vehicleService = vehicleService ?? VehicleService(),
        _maintenanceService =
            maintenanceService ?? MaintenanceService(),
        _documentService =
            documentService ?? DocumentService(),
        _driverService = driverService ?? DriverService(),
        _complianceService =
            complianceService ?? DriverComplianceService();

  final VehicleService _vehicleService;
  final MaintenanceService _maintenanceService;
  final DocumentService _documentService;
  final DriverService _driverService;
  final DriverComplianceService _complianceService;

  final VehicleCalendarMapper _vehicleMapper =
      const VehicleCalendarMapper();

  final MaintenanceCalendarMapper _maintenanceMapper =
      const MaintenanceCalendarMapper();

  final DocumentCalendarMapper _documentMapper =
      const DocumentCalendarMapper();

  final ComplianceCalendarMapper _complianceMapper =
      const ComplianceCalendarMapper();

  Future<List<CalendarEvent>> buildEvents() async {
    final vehicles =
        await _vehicleService.getVehicles();

    final vehicleMap =
        await _vehicleService.getVehicleMap();

    final maintenance =
        await _maintenanceService.getAll();

    final documents =
        await _documentService.getAll();

    final drivers =
        await _driverService.getDriverMap();

    final compliance =
        await _complianceService.getAll();

    final events = <CalendarEvent>[];

    events.addAll(
      _vehicleMapper.map(vehicles),
    );

    events.addAll(
      _maintenanceMapper.map(
        maintenance,
        vehicleMap,
      ),
    );

    events.addAll(
      _documentMapper.map(
        documents: documents,
        vehicles: vehicleMap,
        drivers: drivers,
      ),
    );

    events.addAll(
      _complianceMapper.map(
        records: compliance,
        drivers: drivers,
      ),
    );

    events.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return events;
  }
}