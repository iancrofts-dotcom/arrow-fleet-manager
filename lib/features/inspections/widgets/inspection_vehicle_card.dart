import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/widgets/vehicle_picker.dart';

class InspectionVehicleCard extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final ValueChanged<Vehicle?> onVehicleChanged;

  const InspectionVehicleCard({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
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
              "Fleet Vehicle",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            VehiclePicker(
              vehicles: vehicles,
              selectedVehicle: selectedVehicle,
              onChanged: onVehicleChanged,
            ),

            const SizedBox(height: 20),

            if (selectedVehicle == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Select a vehicle to begin the inspection.",
                  textAlign: TextAlign.center,
                ),
              ),

            if (selectedVehicle != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.local_shipping),
                      ),
                      title: Text(
                        selectedVehicle!.fleetNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        selectedVehicle!.registration,
                      ),
                    ),

                    const Divider(),

                    _infoRow(
                      Icons.directions_bus,
                      "Vehicle",
                      "${selectedVehicle!.make} ${selectedVehicle!.model}",
                    ),

                    _infoRow(
                      Icons.calendar_today,
                      "Year",
                      selectedVehicle!.year.toString(),
                    ),

                    _infoRow(
                      Icons.confirmation_number,
                      "VIN",
                      selectedVehicle!.vin.isEmpty
                          ? "-"
                          : selectedVehicle!.vin,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}