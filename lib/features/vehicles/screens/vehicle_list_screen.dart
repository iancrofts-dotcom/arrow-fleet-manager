import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';

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

  Future<void> addVehicle() async {
    final vehicle = await Navigator.push<Vehicle>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddVehicleScreen(),
      ),
    );

    if (vehicle == null) return;

    await _vehicleService.addVehicle(vehicle);

    setState(() {
      loadVehicles();
    });

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
    setState(() {
      loadVehicles();
    });
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
                  onTap: () {},
                );
              },
            ),
          );
        },
      ),
    );
  }
}