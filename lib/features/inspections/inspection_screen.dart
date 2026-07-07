import 'package:flutter/material.dart';

import 'data/inspection_template.dart';
import 'widgets/checklist_tile.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {

  final registration = TextEditingController();
  final driver = TextEditingController();
  final mileage = TextEditingController();
  final inspector = TextEditingController();
  final comments = TextEditingController();

  final inspectionItems = defaultInspection;

  @override
  void dispose() {
    registration.dispose();
    driver.dispose();
    mileage.dispose();
    inspector.dispose();
    comments.dispose();
    super.dispose();
  }

  Widget field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          const Text(
            "Vehicle Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          field("Vehicle Registration", registration),

          field("Driver", driver),

          field("Mileage", mileage),

          field("Inspector", inspector),

          const SizedBox(height: 25),

          const Text(
            "Daily Vehicle Checks",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ...inspectionItems.map(
            (item) => ChecklistTile(item: item),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: comments,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: "General Comments",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Inspection Ready To Save"),
                  ),
                );

              },
              icon: const Icon(Icons.save),
              label: const Text(
                "Save Inspection",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),

          const SizedBox(height: 40),

        ],
      ),
    );
  }
}