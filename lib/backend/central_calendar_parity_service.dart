import 'package:flutter/material.dart';

import '../features/calendar/models/calendar_event.dart';
import 'documents/central_document_repository.dart';
import 'documents/supabase_central_document_gateway.dart';
import 'drivers/backend_driver_repository.dart';
import 'drivers/central_driver_compliance_repository.dart';
import 'drivers/supabase_driver_compliance_gateway.dart';
import 'drivers/supabase_driver_gateway.dart';
import 'vehicles/backend_vehicle_repository.dart';
import 'vehicles/supabase_vehicle_gateway.dart';
import 'workshop/backend_workshop_repository.dart';
import 'workshop/supabase_workshop_gateway.dart';

class CentralCalendarParityService {
  const CentralCalendarParityService();

  Future<List<CalendarEvent>> loadEvents() async {
    final vehicles = await BackendVehicleRepository(
      SupabaseVehicleGateway(),
    ).listVehicles();
    final drivers = await BackendDriverRepository(
      SupabaseDriverGateway(),
    ).listDrivers();
    final compliance = await const CentralDriverComplianceRepository(
      SupabaseDriverComplianceGateway(),
    ).listCompliance();
    final complianceByDriver = {
      for (final item in compliance) item.driverId: item,
    };
    final events = <CalendarEvent>[];

    for (final vehicle in vehicles.where((item) => item.isActive)) {
      final subtitle = vehicle.fleetNumber.isEmpty
          ? vehicle.registration
          : '${vehicle.registration} • ${vehicle.fleetNumber}';
      if (vehicle.motExpiry != null) {
        events.add(
          CalendarEvent(
            title: vehicle.motType == 'psv' ? 'PSV MOT Due' : 'MOT Due',
            subtitle: subtitle,
            date: vehicle.motExpiry!,
            type: CalendarEventType.vehicle,
            icon: Icons.directions_car,
            color: Colors.blue,
            source: vehicle,
          ),
        );
      }
      if (vehicle.taxiPlateExpiry != null) {
        events.add(
          CalendarEvent(
            title: 'Vehicle Licence (Taxi) Expiry',
            subtitle: subtitle,
            date: vehicle.taxiPlateExpiry!,
            type: CalendarEventType.vehicle,
            icon: Icons.local_taxi_outlined,
            color: Colors.orange,
            source: vehicle,
          ),
        );
      }
      if (vehicle.serviceDue != null) {
        events.add(
          CalendarEvent(
            title: 'Service Due',
            subtitle: subtitle,
            date: vehicle.serviceDue!,
            type: CalendarEventType.maintenance,
            icon: Icons.build,
            color: Colors.orange,
            source: vehicle,
          ),
        );
      }
      if (vehicle.psvGarageCheckEnabled && vehicle.psvGarageCheckDue != null) {
        events.add(
          CalendarEvent(
            title: 'PSV Garage Check Due',
            subtitle:
                '$subtitle • ${vehicle.psvGarageCheckIntervalWeeks}-week schedule',
            date: vehicle.psvGarageCheckDue!,
            type: CalendarEventType.maintenance,
            icon: Icons.fact_check_outlined,
            color: Colors.orange,
            source: vehicle,
          ),
        );
      }
      if (vehicle.taxiSafetyCheckEnabled &&
          vehicle.taxiSafetyCheckDue != null) {
        events.add(
          CalendarEvent(
            title: 'Taxi Safety Check Due',
            subtitle:
                '$subtitle • ${vehicle.taxiSafetyCheckIntervalWeeks}-week schedule',
            date: vehicle.taxiSafetyCheckDue!,
            type: CalendarEventType.maintenance,
            icon: Icons.health_and_safety_outlined,
            color: Colors.orange,
            source: vehicle,
          ),
        );
      }
    }

    for (final driver in drivers.where((item) => item.isActive)) {
      final record = complianceByDriver[driver.id];
      final subtitle = '${driver.firstName} ${driver.lastName}'.trim();
      final licenceExpiry = record?.licenceExpiry ?? driver.licenceExpiry;
      if (licenceExpiry != null) {
        events.add(
          CalendarEvent(
            title: 'Driving Licence Expiry',
            subtitle: subtitle,
            date: licenceExpiry,
            type: CalendarEventType.licence,
            icon: Icons.badge_outlined,
            color: Colors.orange,
            source: driver,
          ),
        );
      }
      for (final item in <(String, DateTime?, CalendarEventType, IconData)>[
        (
          'CPC Expiry',
          record?.cpcExpiry,
          CalendarEventType.cpc,
          Icons.school_outlined,
        ),
        (
          'Medical Expiry',
          record?.medicalExpiry,
          CalendarEventType.medical,
          Icons.medical_information_outlined,
        ),
        (
          'DBS Expiry',
          record?.dbsExpiry,
          CalendarEventType.dbs,
          Icons.verified_user_outlined,
        ),
        (
          'Taxi / Private Hire Licence Expiry',
          record?.taxiLicenceExpiry,
          CalendarEventType.taxiLicence,
          Icons.local_taxi_outlined,
        ),
      ]) {
        if (item.$2 == null) continue;
        events.add(
          CalendarEvent(
            title: item.$1,
            subtitle: subtitle,
            date: item.$2!,
            type: item.$3,
            icon: item.$4,
            color: Colors.orange,
            source: driver,
          ),
        );
      }
    }

    // Document expiries are first-class calendar events in central mode.
    // Keep them under the Documents filter even when their category (for
    // example MOT) also has a statutory vehicle due-date event elsewhere.
    // This intentionally represents two different records: the vehicle due
    // date and the uploaded document's own expiry date.
    try {
      final documents = await const CentralDocumentRepository(
        SupabaseCentralDocumentGateway(),
      ).listDocuments();
      final vehiclesById = {
        for (final vehicle in vehicles) vehicle.id: vehicle,
      };
      final driversById = {for (final driver in drivers) driver.id: driver};

      for (final document in documents) {
        final expiresOn = document.expiresOn;
        if (expiresOn == null) continue;

        final subtitle = switch (document.entityType.toLowerCase()) {
          'vehicle' =>
            vehiclesById[document.entityId]?.registration ?? 'Vehicle document',
          'driver' => (() {
            final driver = driversById[document.entityId];
            return driver == null
                ? 'Driver document'
                : '${driver.firstName} ${driver.lastName}'.trim();
          })(),
          _ =>
            document.entityType.isEmpty
                ? 'Fleet document'
                : '${document.entityType} document',
        };

        events.add(
          CalendarEvent(
            title: document.title.trim().isEmpty
                ? document.fileName
                : document.title.trim(),
            subtitle: subtitle,
            date: expiresOn,
            type: CalendarEventType.document,
            icon: _documentIcon(document.category),
            color: _documentColor(expiresOn),
            source: document,
          ),
        );
      }
    } catch (_) {
      // A role without document access must still retain its fleet/driver
      // calendar rather than losing the whole page.
    }

    // Outstanding Workshop defects are operational vehicle issues. Keep them
    // in the calendar without allowing a Workshop permission failure to hide
    // the statutory compliance dates above.
    try {
      final repairs = await const BackendWorkshopRepository(
        SupabaseWorkshopGateway(),
      ).listRepairJobs();
      for (final repair in repairs.where((item) => item.isOutstanding)) {
        events.add(
          CalendarEvent(
            title: 'Vehicle Issue • ${repair.title}',
            subtitle:
                '${repair.vehicleRegistration} • ${repair.status} • ${repair.priority}',
            date: repair.createdAt,
            type: CalendarEventType.maintenance,
            icon: Icons.warning_amber_outlined,
            color: Colors.red,
            source: repair,
          ),
        );
      }
    } catch (_) {
      // Calendar remains usable for roles that do not have Workshop read access.
    }

    events.sort((left, right) {
      final byDate = left.date.compareTo(right.date);
      if (byDate != 0) return byDate;
      final bySubtitle = left.subtitle.compareTo(right.subtitle);
      if (bySubtitle != 0) return bySubtitle;
      return left.title.compareTo(right.title);
    });
    return events;
  }
}

IconData _documentIcon(String category) {
  switch (category.toLowerCase()) {
    case 'mot':
      return Icons.directions_car_outlined;
    case 'service':
      return Icons.build_outlined;
    case 'insurance':
    case 'policy':
      return Icons.policy_outlined;
    case 'licence':
    case 'license':
      return Icons.badge_outlined;
    case 'cpc':
      return Icons.school_outlined;
    case 'medical':
      return Icons.medical_information_outlined;
    case 'dbs':
      return Icons.verified_user_outlined;
    case 'taxi_licence':
    case 'taxi_license':
    case 'taxi_plate':
      return Icons.local_taxi_outlined;
    default:
      return Icons.description_outlined;
  }
}

Color _documentColor(DateTime expiry) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(expiry.year, expiry.month, expiry.day);
  if (date.isBefore(today)) return Colors.red;
  if (!date.isAfter(today.add(const Duration(days: 30)))) {
    return Colors.orange;
  }
  return Colors.blue;
}
