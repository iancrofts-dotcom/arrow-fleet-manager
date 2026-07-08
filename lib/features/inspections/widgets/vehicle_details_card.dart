import 'package:flutter/material.dart';

class VehicleDetailsCard extends StatelessWidget {
  final TextEditingController registrationController;
  final TextEditingController driverController;
  final TextEditingController mileageController;
  final TextEditingController inspectorController;

  const VehicleDetailsCard({
    super.key,
    required this.registrationController,
    required this.driverController,
    required this.mileageController,
    required this.inspectorController,
  });

  Widget buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

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
              "Vehicle Details",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            buildField(
              label: "Vehicle Registration",
              icon: Icons.local_shipping,
              controller: registrationController,
            ),

            buildField(
              label: "Driver",
              icon: Icons.person,
              controller: driverController,
            ),

            buildField(
              label: "Mileage",
              icon: Icons.speed,
              controller: mileageController,
              keyboardType: TextInputType.number,
            ),

            buildField(
              label: "Inspector",
              icon: Icons.badge,
              controller: inspectorController,
            ),
          ],
        ),
      ),
    );
  }
}