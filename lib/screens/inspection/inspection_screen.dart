import 'package:flutter/material.dart';
import '../../database/database_service.dart';

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

  @override
  void dispose() {
    registrationController.dispose();
    driverController.dispose();
    mileageController.dispose();
    inspectorController.dispose();
    commentsController.dispose();
    super.dispose();
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Inspection"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            buildField("Vehicle Registration", registrationController),

            buildField("Driver", driverController),

            buildField("Mileage", mileageController),

            buildField("Inspector", inspectorController),

            TextField(
              controller: commentsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Comments",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
  onPressed: () async {

    await DatabaseService.saveInspection(
      registration: registrationController.text,
      driver: driverController.text,
      mileage: mileageController.text,
      inspector: inspectorController.text,
      comments: commentsController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Inspection Saved"),
      ),
    );
  },
  icon: const Icon(Icons.save),
  label: const Text("Save Inspection"),
)
            )
          ],
        ),
      ),
    );
  }
}