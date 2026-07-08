import 'package:flutter/material.dart';

class VehicleDetailsCard extends StatelessWidget {

  final TextEditingController registration;
  final TextEditingController driver;
  final TextEditingController inspector;
  final TextEditingController mileage;

  const VehicleDetailsCard({
    super.key,
    required this.registration,
    required this.driver,
    required this.inspector,
    required this.mileage,
  });

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            field("Vehicle Registration", registration),

            field("Driver", driver),

            field("Mileage", mileage),

            field("Inspector", inspector),

          ],
        ),
      ),
    );
  }
}