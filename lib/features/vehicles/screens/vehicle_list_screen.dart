import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_details_screen.dart';
import '../services/vehicle_search_service.dart';
import '../widgets/fleet_search_bar.dart';
import '../models/vehicle_filter.dart';
import '../services/vehicle_filter_service.dart';
import '../widgets/fleet_filter_bar.dart';
import '../models/vehicle_sort.dart';
import '../services/vehicle_sort_service.dart';
import '../widgets/fleet_sort_button.dart';

class VehicleListScreen extends StatefulWidget {
  final VehicleFilter? initialFilter;

  const VehicleListScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _vehicleService = VehicleService();
 final VehicleSearchService _searchService =
    const VehicleSearchService();

final VehicleFilterService _filterService =
    const VehicleFilterService();

final VehicleSortService _sortService =
    const VehicleSortService();

VehicleFilter _selectedFilter = VehicleFilter.all;
VehicleSort _selectedSort = VehicleSort.registration;


final TextEditingController _searchController =
    TextEditingController();

String _searchQuery = '';

  late Future<List<Vehicle>> vehiclesFuture;

  @override
  void initState() {
    super.initState();

_selectedFilter =
    widget.initialFilter ?? VehicleFilter.all;

loadVehicles();
  }
  @override
void dispose() {
  _searchController.dispose();
  super.dispose();
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
  actions: [
    FleetSortButton(
      selectedSort: _selectedSort,
      onChanged: (sort) {
        setState(() {
          _selectedSort = sort;
        });
      },
    ),
  ],
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

          final searchedVehicles = _searchService.filterVehicles(
  vehicles: snapshot.data ?? [],
  query: _searchQuery,
);

final filteredVehicles = _filterService.filterVehicles(
  vehicles: searchedVehicles,
  filter: _selectedFilter,
);

final vehicles = _sortService.sortVehicles(
  vehicles: filteredVehicles,
  sort: _selectedSort,
);

          if (vehicles.isEmpty) {
            return const Center(
              child: Text(
                "No vehicles found.\nTap Add Vehicle to begin.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Column(
  children: [
    FleetSearchBar(
  controller: _searchController,
  onChanged: (value) {
    setState(() {
      _searchQuery = value;
    });
  },
),

FleetFilterBar(
  selectedFilter: _selectedFilter,
  onChanged: (filter) {
    setState(() {
      _selectedFilter = filter;
    });
  },
),

    Expanded(
      child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return VehicleCard(
  vehicle: vehicles[index],
  onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VehicleDetailsScreen(
        vehicle: vehicles[index],
      ),
    ),
  );

  if (!mounted) return;

  await refreshVehicles();
},
);

                
              },
            ),
       ),
        ),
      ],
    );
        },
      ),
    );
  }
}