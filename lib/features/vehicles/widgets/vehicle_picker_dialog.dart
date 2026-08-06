import 'package:flutter/material.dart';

import '../../../database/vehicle_repository.dart';
import '../../../database/database_service.dart';
import '../models/vehicle.dart';

class VehiclePickerDialog extends StatefulWidget {
  const VehiclePickerDialog({super.key});

  static Future<Vehicle?> show(BuildContext context) {
    return showDialog<Vehicle>(
      context: context,
      builder: (_) => const VehiclePickerDialog(),
    );
  }

  @override
  State<VehiclePickerDialog> createState() =>
      _VehiclePickerDialogState();
}

class _VehiclePickerDialogState
    extends State<VehiclePickerDialog> {
  late final VehicleRepository _repository;

  List<Vehicle> _vehicles = [];
  List<Vehicle> _filtered = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _repository = VehicleRepository(
      databaseService: DatabaseService(),
    );

    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await _repository.getVehicles();

    if (!mounted) return;

    setState(() {
      _vehicles = vehicles;
      _filtered = vehicles;
      _loading = false;
    });
  }

  void _search(String value) {
    final query = value.toLowerCase();

    setState(() {
      _filtered = _vehicles.where((vehicle) {
        return vehicle.registration
                .toLowerCase()
                .contains(query) ||
            vehicle.fleetNumber
                .toLowerCase()
                .contains(query) ||
            vehicle.make
                .toLowerCase()
                .contains(query) ||
            vehicle.model
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Vehicle"),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search vehicles...",
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final vehicle = _filtered[index];

                        return ListTile(
                          leading: const Icon(
                            Icons.directions_bus,
                          ),
                          title: Text(
                            "${vehicle.fleetNumber} • ${vehicle.registration}",
                          ),
                          subtitle: Text(
                            "${vehicle.make} ${vehicle.model}",
                          ),
                          onTap: () {
                            Navigator.pop(
                              context,
                              vehicle,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}