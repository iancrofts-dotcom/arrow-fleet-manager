import 'package:flutter/material.dart';

import '../vehicles/models/vehicle.dart';

import '../auth/services/auth_service.dart';
import '../auth/services/permission_service.dart';
import '../../config/backend_mode.dart';

import 'data/inspection_template.dart';
import 'models/inspection.dart';
import 'models/inspection_item.dart';
import 'services/inspection_service.dart';
import 'services/driver_daily_workshop_save_service.dart';
import 'services/central_driver_daily_inspection_service.dart';

import 'widgets/checklist_section.dart';
import 'widgets/defect_summary.dart';
import 'widgets/inspection_details_section.dart';
import 'widgets/inspection_header.dart';
import 'widgets/inspection_progress.dart';
import 'widgets/save_button.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({
    super.key,
    this.assignedVehicle,
    this.assignedDriverName,
  });

  final Vehicle? assignedVehicle;
  final String? assignedDriverName;

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final TextEditingController driverController = TextEditingController();

  final TextEditingController mileageController = TextEditingController();

  final TextEditingController commentsController = TextEditingController();

  final InspectionService _inspectionService = InspectionService();
  final DriverDailyWorkshopSaveService _workshopSaveService =
      DriverDailyWorkshopSaveService();
  final CentralDriverDailyInspectionService _centralDailyInspectionService =
      const CentralDriverDailyInspectionService();

  late final Inspection inspection;

  final List<InspectionItem> inspectionItems = defaultInspectionTemplate;

  Vehicle? _selectedVehicle;

  String _fuelLevel = 'Full';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    inspection = _inspectionService.createInspection();

    _selectedVehicle = widget.assignedVehicle;
    driverController.text = widget.assignedDriverName ?? '';
    if (BackendModeConfig.current == BackendMode.supabase &&
        PermissionService.instance.isDriver &&
        _selectedVehicle != null) {
      _prefillCentralMileage();
    }
  }

  Future<void> _prefillCentralMileage() async {
    final vehicle = _selectedVehicle;
    if (vehicle == null) return;
    try {
      final mileage = await _centralDailyInspectionService.latestMileage(
        vehicle,
      );
      if (!mounted ||
          mileage == null ||
          mileage <= 0 ||
          mileageController.text.trim().isNotEmpty) {
        return;
      }
      setState(() => mileageController.text = mileage.toString());
    } catch (_) {
      // A missing historic reading must not block today's walk-round.
    }
  }

  @override
  void dispose() {
    driverController.dispose();
    mileageController.dispose();
    commentsController.dispose();

    super.dispose();
  }

  int get completedChecks => inspectionItems
      .where((item) => item.status != InspectionStatus.notApplicable)
      .length;

  int get defectCount => inspectionItems
      .where((item) => item.status == InspectionStatus.fail)
      .length;

  List<InspectionItem> byCategory(String category) {
    return inspectionItems.where((item) => item.category == category).toList();
  }

  void updateStatus(InspectionItem item, InspectionStatus status) {
    setState(() {
      item.status = status;
    });
  }

  void updateNotes(InspectionItem item, String notes) {
    item.notes = notes;
  }

  Future<void> saveInspection() async {
    if (_isSaving) return;

    final isDriverDailyInspection = PermissionService.instance.isDriver;
    final isCentral = BackendModeConfig.current == BackendMode.supabase;
    final driverId = AuthService.instance.currentDriverId;
    final centralDriverId = AuthService.instance.currentBackendDriverId;
    final vehicle = _selectedVehicle;
    final driverName =
        AuthService.instance.currentUser?.username ??
        widget.assignedDriverName ??
        '';
    final hasDriverIdentity = isCentral
        ? centralDriverId != null
        : driverId != null;

    if (isDriverDailyInspection &&
        (!hasDriverIdentity || vehicle == null || driverName.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Daily inspections must use your assigned Driver and vehicle.',
          ),
        ),
      );
      return;
    }

    inspection.vehicleId = _selectedVehicle?.id;

    inspection.registration = _selectedVehicle?.registration ?? '';

    inspection.driver = isDriverDailyInspection
        ? driverName.trim()
        : driverController.text.trim();

    inspection.mileage = int.tryParse(mileageController.text.trim()) ?? 0;

    inspection.fuelLevel = _fuelLevel;

    inspection.comments = commentsController.text.trim();

    inspection.status = 'Completed';

    inspection.overallResult = defectCount == 0 ? 'Pass' : 'Fail';

    if (inspection.mileage <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the current odometer reading.'),
        ),
      );
      return;
    }

    // Central Driver inspections use UUID vehicle identity and are validated by
    // the authenticated RPC. The legacy validator requires a SQLite vehicleId,
    // which is intentionally null for central vehicles.
    if (!(isDriverDailyInspection && isCentral) &&
        !_inspectionService.validateInspection(inspection)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete Driver, Vehicle and Odometer.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Object? workshopInspectionId;
      if (isDriverDailyInspection) {
        if (vehicle == null) {
          throw StateError('Assigned Driver and vehicle are required.');
        }

        if (isCentral) {
          if (centralDriverId == null) {
            throw StateError('A linked central Driver account is required.');
          }
          workshopInspectionId = await _centralDailyInspectionService.save(
            inspection: inspection,
            items: inspectionItems,
            vehicle: vehicle,
          );
        } else {
          if (driverId == null) {
            throw StateError('Assigned Driver and vehicle are required.');
          }
          workshopInspectionId = await _workshopSaveService.save(
            inspection: inspection,
            items: inspectionItems,
            driverId: driverId,
            driverName: driverName,
            vehicle: vehicle,
          );
        }
      } else {
        await _inspectionService.saveInspectionWithResults(
          inspection,
          inspectionItems,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDriverDailyInspection
                ? 'Daily inspection saved to Workshop (#$workshopInspectionId).'
                : 'Inspection ${inspection.inspectionNumber} saved successfully.',
          ),
        ),
      );
      if (isDriverDailyInspection) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      final driverMessage = e is CentralDriverDailyInspectionSaveException
          ? 'Daily inspection save error: ${e.diagnosticMessage}'
          : 'Daily inspection save error: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 15),
          content: SelectableText(
            isDriverDailyInspection
                ? driverMessage
                : 'Failed to save inspection\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;
    final driverNeedsLockedInspection = permissions.isDriver;

    final hasDriverIdentity = BackendModeConfig.current == BackendMode.supabase
        ? AuthService.instance.currentBackendDriverId != null
        : AuthService.instance.currentDriverId != null;

    if (driverNeedsLockedInspection &&
        (!permissions.canPerformDailyInspection ||
            !hasDriverIdentity ||
            widget.assignedVehicle == null ||
            widget.assignedDriverName == null)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Daily inspections must be started from your assigned vehicle.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Daily Walkaround'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// Header
          InspectionHeader(
            inspectionNumber: inspection.inspectionNumber,
            inspectionDate: inspection.inspectionDate,
          ),

          const SizedBox(height: 20),

          /// Progress
          InspectionProgress(
            completed: completedChecks,
            total: inspectionItems.length,
          ),

          const SizedBox(height: 20),

          /// Driver / Vehicle / Odometer
          InspectionDetailsSection(
            driverController: driverController,
            mileageController: mileageController,
            lockedVehicle: driverNeedsLockedInspection
                ? widget.assignedVehicle
                : null,
            lockDriver: driverNeedsLockedInspection,

            onVehicleChanged: (vehicle) {
              setState(() {
                _selectedVehicle = vehicle;
              });
            },

            onFuelLevelChanged: (fuel) {
              setState(() {
                _fuelLevel = fuel;
              });
            },
          ),

          const SizedBox(height: 24),

          /// Exterior Checks
          ChecklistSection(
            title: 'Exterior',
            items: byCategory('Exterior'),
            onStatusChanged: updateStatus,
            onNotesChanged: updateNotes,
          ),

          const SizedBox(height: 20),

          /// Safety Checks
          ChecklistSection(
            title: 'Safety',
            items: byCategory('Safety'),
            onStatusChanged: updateStatus,
            onNotesChanged: updateNotes,
          ),

          const SizedBox(height: 20),

          /// Accessibility Checks
          ChecklistSection(
            title: 'Accessibility',
            items: byCategory('Accessibility'),
            onStatusChanged: updateStatus,
            onNotesChanged: updateNotes,
          ),

          const SizedBox(height: 20),

          /// General Comments
          TextField(
            controller: commentsController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'General Comments',
              hintText: 'Enter any additional observations...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 24),

          /// Inspection Summary
          DefectSummary(
            completedChecks: completedChecks,
            totalChecks: inspectionItems.length,
            defectCount: defectCount,
          ),

          const SizedBox(height: 30),

          /// Save Inspection
          SaveButton(onSave: saveInspection, isSaving: _isSaving),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
