import 'package:flutter/material.dart';

import 'data/inspection_template.dart';
import 'models/inspection.dart';
import 'widgets/checklist_tile.dart';
import 'widgets/inspection_header.dart';
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

  late final Inspection inspection;

  final inspectionItems = defaultInspectionTemplate;

  @override
  void initState() {
    super.initState();

    inspection = Inspection(
      inspectionNumber: "AST-${DateTime.now().year}-000001",
      inspectionDate: DateTime.now(),
    );
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

  void saveInspection() {
    inspection.registration = registrationController.text;
    inspection.driver = driverController.text;
    inspection.inspector = inspectorController.text;
    inspection.comments = commentsController.text;

    inspection.mileage =
        int.tryParse(mileageController.text.trim()) ?? 0;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Inspection saved successfully (database coming in v0.4.0)"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Inspection"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InspectionHeader(
            inspectionNumber: inspection.inspectionNumber,
            inspectionDate: inspection.inspectionDate,
          ),

          const SizedBox(height: 20),

          VehicleDetailsCard(
            registrationController: registrationController,
            driverController: driverController,
            mileageController: mileageController,
            inspectorController: inspectorController,
          ),

          const SizedBox(height: 25),

          Text(
            "Daily Walkaround Inspection",
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 15),

          ...inspectionItems.map(
            (item) => ChecklistTile(item: item),
          ),

          const SizedBox(height: 25),

          TextField(
            controller: commentsController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: "General Comments",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          SaveButton(
            onSave: saveInspection,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}