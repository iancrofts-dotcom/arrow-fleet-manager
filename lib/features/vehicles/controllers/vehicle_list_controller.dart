import 'package:flutter/foundation.dart';

import '../models/vehicle.dart';
import '../models/vehicle_filter.dart';
import '../services/vehicle_filter_service.dart';
import '../services/vehicle_search_service.dart';
import '../services/vehicle_service.dart';

class VehicleListController extends ChangeNotifier {
  VehicleListController({
    VehicleService? vehicleService,
    VehicleSearchService? searchService,
    VehicleFilterService? filterService,
  })  : _vehicleService = vehicleService ?? VehicleService(),
        _searchService =
            searchService ?? const VehicleSearchService(),
        _filterService =
            filterService ?? const VehicleFilterService();

  final VehicleService _vehicleService;
  final VehicleSearchService _searchService;
  final VehicleFilterService _filterService;

  List<Vehicle> _allVehicles = [];

  String _searchQuery = '';

  VehicleFilter _selectedFilter = VehicleFilter.all;

  List<Vehicle> get vehicles {
    final searched = _searchService.filterVehicles(
      vehicles: _allVehicles,
      query: _searchQuery,
    );

    return _filterService.filterVehicles(
      vehicles: searched,
      filter: _selectedFilter,
    );
  }

  String get searchQuery => _searchQuery;

  VehicleFilter get selectedFilter => _selectedFilter;

  Future<void> loadVehicles() async {
    _allVehicles = await _vehicleService.getVehicles();
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateFilter(VehicleFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
}