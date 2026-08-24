import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/vehicle.dart';
import '../models/vehicle_filter.dart';
import '../models/vehicle_sort.dart';
import '../services/vehicle_filter_service.dart';
import '../services/vehicle_search_service.dart';
import '../services/vehicle_service.dart';
import '../services/vehicle_sort_service.dart';
import '../widgets/fleet_filter_bar.dart';
import '../widgets/fleet_search_bar.dart';
import '../widgets/fleet_sort_button.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_details_screen.dart';

class VehicleListScreen extends StatefulWidget {
  final VehicleFilter? initialFilter;

  const VehicleListScreen({super.key, this.initialFilter});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _vehicleService = VehicleService();

  final PermissionService _permissions = PermissionService.instance;

  final VehicleSearchService _searchService = const VehicleSearchService();

  final VehicleFilterService _filterService = const VehicleFilterService();

  final VehicleSortService _sortService = const VehicleSortService();

  VehicleFilter _selectedFilter = VehicleFilter.all;

  VehicleSort _selectedSort = VehicleSort.registration;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  late Future<List<Vehicle>> vehiclesFuture;

  @override
  void initState() {
    super.initState();

    _selectedFilter = widget.initialFilter ?? VehicleFilter.all;

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
      MaterialPageRoute(builder: (_) => AddVehicleScreen()),
    );

    if (vehicle == null) return;

    await refreshVehicles();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vehicle.registration} added successfully.')),
    );
  }

  Future<void> refresh() async {
    await refreshVehicles();
  }

  void _clearSearchAndFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = VehicleFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canViewVehicles) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to view vehicles.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return AppPageScaffold(
      title: 'Fleet Vehicles',
      subtitle: 'Search, filter and manage the fleet.',
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
      floatingActionButton: _permissions.canManageVehicles
          ? FloatingActionButton.extended(
              onPressed: addVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
      child: FutureBuilder<List<Vehicle>>(
        future: vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading fleet vehicles...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load fleet vehicles',
              message: 'Please try again.',
              onRetry: refresh,
            );
          }

          final allVehicles = snapshot.data ?? const <Vehicle>[];

          if (allVehicles.isEmpty) {
            return const AppEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No vehicles have been added',
              message: 'Use Add Vehicle to begin building the fleet.',
            );
          }

          final searchedVehicles = _searchService.filterVehicles(
            vehicles: allVehicles,
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

          return Column(
            children: [
              SectionCard(
                padding: const EdgeInsets.all(12),
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh,
                  child: vehicles.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 96),
                            AppEmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No vehicles match your search or filters',
                              message:
                                  'Try a different search term or clear your filters.',
                              action: OutlinedButton.icon(
                                onPressed: _clearSearchAndFilters,
                                icon: const Icon(Icons.filter_alt_off_outlined),
                                label: const Text('Clear filters'),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];

                            return VehicleCard(
                              vehicle: vehicle,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VehicleDetailsScreen(vehicle: vehicle),
                                  ),
                                );

                                if (!mounted) {
                                  return;
                                }

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
