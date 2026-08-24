import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/status_badge.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class AssignVehicleScreen extends StatefulWidget {
  const AssignVehicleScreen({super.key});

  @override
  State<AssignVehicleScreen> createState() => _AssignVehicleScreenState();
}

class _AssignVehicleScreenState extends State<AssignVehicleScreen> {
  final VehicleService _vehicleService = VehicleService();

  late Future<List<Vehicle>> _vehiclesFuture;

  final TextEditingController _searchController = TextEditingController();

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

  List<Vehicle> _filterVehicles(List<Vehicle> vehicles) {
    final activeVehicles = vehicles.where((vehicle) => vehicle.active);

    if (_search.isEmpty) return activeVehicles.toList(growable: false);

    final query = _search.toLowerCase();

    return activeVehicles.where((vehicle) {
      return vehicle.registration.toLowerCase().contains(query) ||
          vehicle.fleetNumber.toLowerCase().contains(query) ||
          vehicle.make.toLowerCase().contains(query) ||
          vehicle.model.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canViewVehicles) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to select fleet vehicles.'),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Assign Vehicle',
      subtitle: 'Select an active vehicle for this driver.',
      child: Column(
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingState(
                    label: 'Loading active vehicles...',
                  );
                }

                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Unable to load vehicles',
                    message: 'Please try again.',
                    onRetry: () => setState(() {
                      _vehiclesFuture = _vehicleService.getVehicles();
                    }),
                  );
                }

                final vehicles = _filterVehicles(snapshot.data ?? []);

                if (vehicles.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No active vehicles available',
                    message:
                        'Only active vehicles can be assigned to a driver.',
                  );
                }

                return ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text(vehicle.registration),
                        subtitle: Text(
                          '${vehicle.fleetNumber}\n'
                          '${vehicle.make} ${vehicle.model}',
                        ),
                        isThreeLine: true,
                        trailing: StatusBadge.success('Active'),
                        onTap: () {
                          Navigator.pop(context, vehicle);
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
