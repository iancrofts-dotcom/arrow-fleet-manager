import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class AssignVehicleScreen extends StatefulWidget {
  const AssignVehicleScreen({super.key});

  @override
  State<AssignVehicleScreen> createState() =>
      _AssignVehicleScreenState();
}

class _AssignVehicleScreenState
    extends State<AssignVehicleScreen> {
  final VehicleService _vehicleService =
      VehicleService();

  late Future<List<Vehicle>> _vehiclesFuture;

  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _vehicleService.getVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Vehicle> _filterVehicles(
    List<Vehicle> vehicles,
  ) {
    if (_search.isEmpty) {
      return vehicles;
    }

    final query = _search.toLowerCase();

    return vehicles.where((vehicle) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Vehicle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search vehicles...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Vehicle>>(
              future: _vehiclesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                    ),
                  );
                }

                final vehicles =
                    _filterVehicles(
                  snapshot.data ?? [],
                );

                if (vehicles.isEmpty) {
                  return const Center(
                    child: Text(
                      'No vehicles found.',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder:
                      (context, index) {
                    final vehicle =
                        vehicles[index];

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.local_shipping,
                        ),
                        title: Text(
                          vehicle.registration,
                        ),
                        subtitle: Text(
                          '${vehicle.fleetNumber}\n'
                          '${vehicle.make} ${vehicle.model}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          Navigator.pop(
                            context,
                            vehicle,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}