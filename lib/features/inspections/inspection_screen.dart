import 'package:flutter/material.dart';

import 'data/inspection_template.dart';
import 'models/inspection.dart';
import 'models/inspection_item.dart';
import 'services/inspection_service.dart';
import 'widgets/checklist_section.dart';
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

  int get completedChecks {
    return inspectionItems
        .where((item) => item.status != InspectionStatus.notApplicable)
        .length;
  }

  List<InspectionItem> byCategory(String category) {
    return inspectionItems
        .where((item) => item.category == category)
        .toList();
  }

  void saveInspection() {
    inspection.registration = registrationController.text;
    inspection.driver = driverController.text;
    inspection.inspector = inspectorController.text;
    inspection.comments = commentsController.text;

    inspection.mileage = int.tryParse(mileageController.text) ?? 0;

    final valid = _inspectionService.validateInspection(inspection);

    if (!mounted) return;

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please complete Registration, Driver and Inspector.",
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Inspection ${inspection.inspectionNumber} validated successfully.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Walkaround Inspection"),
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
            title: "Exterior",
            items: byCategory("Exterior"),
          ),

          ChecklistSection(
            title: "Safety",
            items: byCategory("Safety"),
          ),

          ChecklistSection(
            title: "Accessibility",
            items: byCategory("Accessibility"),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: commentsController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: "General Comments",
              border: OutlineInputBorder(),
            ),
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