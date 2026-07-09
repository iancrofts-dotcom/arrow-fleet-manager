import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
import '../widgets/delete_vehicle_dialog.dart';
import '../widgets/vehicle_actions_sheet.dart';
import 'edit_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _vehicleService = VehicleService();

  late Future<List<Vehicle>> vehiclesFuture;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  void loadVehicles() {
  vehiclesFuture = _vehicleService.getVehicles();
}

Future<void> refreshVehicles() async {
  setState(() {
    loadVehicles();
  });
}

  Future<void> addVehicle() async {
    final vehicle = await Navigator.push<Vehicle>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddVehicleScreen(),
      ),
    );

    if (vehicle == null) return;

    await _vehicleService.addVehicle(vehicle);

    await refreshVehicles();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${vehicle.registration} added successfully.",
        ),
      ),
    );
  }

  Future<void> refresh() async {
   await refreshVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fleet Vehicles"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addVehicle,
        icon: const Icon(Icons.add),
        label: const Text("Add Vehicle"),
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final vehicles = snapshot.data ?? [];

          if (vehicles.isEmpty) {
            return const Center(
              child: Text(
                "No vehicles found.\nTap Add Vehicle to begin.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return VehicleCard(
                  vehicle: vehicles[index],
                  onTap: () async {
  showModalBottomSheet(
    context: context,
    builder: (_) => VehicleActionsSheet(
      onEdit: () async {
        Navigator.pop(context);

        final updatedVehicle = await Navigator.push<Vehicle>(
          context,
          MaterialPageRoute(
            builder: (_) => EditVehicleScreen(
              vehicle: vehicles[index],
            ),
          ),
        );

        if (updatedVehicle != null) {
          await _vehicleService.updateVehicle(updatedVehicle);

          if (!mounted) return;

          setState(loadVehicles);
        }
      },
      onDelete: () async {
        Navigator.pop(context);

        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => DeleteVehicleDialog(
            registration: vehicles[index].registration,
          ),
        );

        if (confirm == true && vehicles[index].id != null) {
          await _vehicleService.deleteVehicle(
            vehicles[index].id!,
          );

          if (!mounted) return;

          setState(loadVehicles);
        }
      },
    ),
  );
},
                );
              },
            ),
          );
        },
      ),
    );
  }
}