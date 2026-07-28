import 'package:flutter/material.dart';

import '../vehicles/models/vehicle.dart';

import 'data/inspection_template.dart';
import 'models/inspection.dart';
import 'models/inspection_item.dart';
import 'services/inspection_service.dart';

import 'widgets/checklist_section.dart';
import 'widgets/defect_summary.dart';
import 'widgets/inspection_details_section.dart';
import 'widgets/inspection_header.dart';
import 'widgets/inspection_progress.dart';
import 'widgets/save_button.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() =>
      _InspectionScreenState();
}

class _InspectionScreenState
    extends State<InspectionScreen> {

  final TextEditingController driverController =
      TextEditingController();

  final TextEditingController mileageController =
      TextEditingController();

  final TextEditingController commentsController =
      TextEditingController();

  final InspectionService _inspectionService =
      InspectionService();

  late final Inspection inspection;

  final List<InspectionItem> inspectionItems =
      defaultInspectionTemplate;

  Vehicle? _selectedVehicle;

  String _fuelLevel = 'Full';

  @override
  void initState() {
    super.initState();

    inspection =
        _inspectionService.createInspection();
  }

  @override
  void dispose() {
    driverController.dispose();
    mileageController.dispose();
    commentsController.dispose();

    super.dispose();
  }

  int get completedChecks =>
      inspectionItems
          .where(
            (item) =>
                item.status !=
                InspectionStatus.notApplicable,
          )
          .length;

  int get defectCount =>
      inspectionItems
          .where(
            (item) =>
                item.status ==
                InspectionStatus.fail,
          )
          .length;

  List<InspectionItem> byCategory(
    String category,
  ) {
    return inspectionItems.where(
      (item) => item.category == category,
    ).toList();
  }

  void updateStatus(
    InspectionItem item,
    InspectionStatus status,
  ) {
    setState(() {
      item.status = status;
    });
  }

  void updateNotes(
    InspectionItem item,
    String notes,
  ) {
    item.notes = notes;
  }

  Future<void> saveInspection() async {

    inspection.vehicleId =
        _selectedVehicle?.id;

    inspection.registration =
        _selectedVehicle?.registration ?? '';

    inspection.driver =
        driverController.text.trim();

    inspection.mileage =
        int.tryParse(
              mileageController.text.trim(),
            ) ??
            0;

    inspection.fuelLevel = _fuelLevel;

    inspection.comments =
        commentsController.text.trim();

    inspection.status = 'Completed';

    inspection.overallResult =
        defectCount == 0
            ? 'Pass'
            : 'Fail';

    if (!_inspectionService
        .validateInspection(
      inspection,
    )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete Driver, Vehicle and Odometer.',
          ),
        ),
      );

      return;
    }

    try {
      await _inspectionService.saveInspectionWithResults(
  inspection,
  inspectionItems,
);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Inspection ${inspection.inspectionNumber} saved successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save inspection\n$e',
          ),
        ),
      );
    }
  }
    @override
  Widget build(BuildContext context) {
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
              hintText:
                  'Enter any additional observations...',
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
          SaveButton(
            onSave: saveInspection,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}