import 'package:flutter/material.dart';

class InspectionDetailsSection extends StatelessWidget {
  final TextEditingController driverController;
  final TextEditingController mileageController;
  final TextEditingController inspectorController;

  const InspectionDetailsSection({
    super.key,
    required this.driverController,
    required this.mileageController,
    required this.inspectorController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inspection Details",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: driverController,
              decoration: const InputDecoration(
                labelText: "Driver",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Mileage",
                prefixIcon: Icon(Icons.speed),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: inspectorController,
              decoration: const InputDecoration(
                labelText: "Inspector",
                prefixIcon: Icon(Icons.assignment_ind),
              ),
            ),
          ],
        ),
      ),
    );
  }
}