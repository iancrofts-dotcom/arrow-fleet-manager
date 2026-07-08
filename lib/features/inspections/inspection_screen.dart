import 'package:flutter/material.dart';

import 'data/inspection_template.dart';
import 'models/inspection.dart';
import 'models/inspection_item.dart';
import 'services/inspection_service.dart';
import 'widgets/checklist_section.dart';
import 'widgets/defect_summary.dart';
import 'widgets/inspection_header.dart';
import 'widgets/inspection_progress.dart';
import 'widgets/save_button.dart';
import 'widgets/vehicle_details_card.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final registrationController = TextEditingController();
  final driverController = TextEditingController();
  final mileageController = TextEditingController();
  final inspectorController = TextEditingController();
  final commentsController = TextEditingController();

  final InspectionService _inspectionService = InspectionService();

  late final Inspection inspection;

  final List<InspectionItem> inspectionItems = defaultInspectionTemplate;

  @override
  void initState() {
    super.initState();
    inspection = _inspectionService.createInspection();
  }

  @override
  void dispose() {
    registrationController.dispose();
    driverController.dispose();
    mileageController.dispose();
    inspectorController.dispose();
    commentsController.dispose();
    super.dispose();
  }

  int get completedChecks =>
      inspectionItems.where((i) => i.status != InspectionStatus.notApplicable).length;

  int get defectCount =>
      inspectionItems.where((i) => i.status == InspectionStatus.fail).length;

  List<InspectionItem> byCategory(String category) =>
      inspectionItems.where((i) => i.category == category).toList();

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
  debugPrint("STEP 1");

  inspection.registration = registrationController.text.trim();
  inspection.driver = driverController.text.trim();
  inspection.inspector = inspectorController.text.trim();
  inspection.comments = commentsController.text.trim();
  inspection.mileage = int.tryParse(mileageController.text.trim()) ?? 0;

  debugPrint("STEP 2");

  if (!_inspectionService.validateInspection(inspection)) {
    debugPrint("Validation failed");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please complete Registration, Driver and Inspector.",
        ),
      ),
    );
    return;
  }

  debugPrint("STEP 3");

  try {
    await _inspectionService.saveInspection(inspection);
    debugPrint("STEP 4");
  } catch (e, stackTrace) {
    debugPrint("SAVE ERROR: $e");
    debugPrint(stackTrace.toString());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Database error: $e"),
      ),
    );
    return;
  }

  if (!mounted) return;

  debugPrint("STEP 5");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "Inspection ${inspection.inspectionNumber} saved successfully.",
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Walkaround Inspection'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InspectionHeader(
            inspectionNumber: inspection.inspectionNumber,
            inspectionDate: inspection.inspectionDate,
          ),

          const SizedBox(height: 20),

          InspectionProgress(
            completed: completedChecks,
            total: inspectionItems.length,
          ),

          const SizedBox(height: 20),

          VehicleDetailsCard(
            registrationController: registrationController,
            driverController: driverController,
            mileageController: mileageController,
            inspectorController: inspectorController,
          ),

          const SizedBox(height: 20),

          ChecklistSection(
            title: 'Exterior',
            items: byCategory('Exterior'),
            onStatusChanged: updateStatus,
            onNotesChanged: updateNotes,
          ),

          ChecklistSection(
            title: 'Safety',
            items: byCategory('Safety'),
            onStatusChanged: updateStatus,
            onNotesChanged: updateNotes,
          ),

          ChecklistSection(
            title: 'Accessibility',
            items: byCategory('Accessibility'),
            onStatusChanged: updateStatus,
            onNotesChanged: updateNotes,
          ),

          const SizedBox(height: 20),

          TextField(
            controller: commentsController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'General Comments',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          DefectSummary(
            completedChecks: completedChecks,
            totalChecks: inspectionItems.length,
            defectCount: defectCount,
          ),

          const SizedBox(height: 30),

          SaveButton(
            onSave: saveInspection,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}