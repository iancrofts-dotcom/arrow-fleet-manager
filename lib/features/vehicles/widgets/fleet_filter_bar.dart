import 'package:flutter/material.dart';

import '../models/vehicle_filter.dart';

class FleetFilterBar extends StatelessWidget {
  final VehicleFilter selectedFilter;
  final ValueChanged<VehicleFilter> onChanged;

  const FleetFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Wrap(
        spacing: 8,
        children: VehicleFilter.values.map((filter) {
          return FilterChip(
            label: Text(_label(filter)),
            selected: selectedFilter == filter,
            onSelected: (_) => onChanged(filter),
          );
        }).toList(),
      ),
    );
  }

  String _label(VehicleFilter filter) {
    switch (filter) {
      case VehicleFilter.all:
        return 'All';

      case VehicleFilter.active:
        return 'Active';

      case VehicleFilter.workshop:
        return 'Workshop';

      case VehicleFilter.retired:
        return 'Retired';

      case VehicleFilter.motDue:
        return 'MOT Due';

      case VehicleFilter.serviceDue:
        return 'Service Due';

      case VehicleFilter.overdue:
        return 'Overdue';
    }
  }
}