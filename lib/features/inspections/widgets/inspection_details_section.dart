import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/screens/assign_vehicle_screen.dart';

class InspectionDetailsSection extends StatefulWidget {
  final TextEditingController driverController;
  final TextEditingController mileageController;

  /// Callback when a vehicle is selected
  final ValueChanged<Vehicle?>? onVehicleChanged;

  /// Callback when the fuel level changes
  final ValueChanged<String>? onFuelLevelChanged;

  final Vehicle? lockedVehicle;
  final bool lockDriver;

  const InspectionDetailsSection({
    super.key,
    required this.driverController,
    required this.mileageController,
    this.onVehicleChanged,
    this.onFuelLevelChanged,
    this.lockedVehicle,
    this.lockDriver = false,
  });

  @override
  State<InspectionDetailsSection> createState() =>
      _InspectionDetailsSectionState();
}

class _InspectionDetailsSectionState
    extends State<InspectionDetailsSection> {
  Vehicle? _selectedVehicle;

  String _fuelLevel = 'Full';

  Future<void> _selectVehicle() async {
    if (widget.lockedVehicle != null) {
      return;
    }
    final vehicle = await Navigator.push<Vehicle>(
      context,
      MaterialPageRoute(
        builder: (_) => const AssignVehicleScreen(),
      ),
    );

    if (vehicle != null) {
      setState(() {
        _selectedVehicle = vehicle;
      });

      widget.onVehicleChanged?.call(vehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = widget.lockedVehicle ?? _selectedVehicle;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Walkaround Details',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: widget.driverController,
              readOnly: widget.lockDriver,
              decoration: const InputDecoration(
                labelText: 'Driver',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Vehicle',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: widget.lockedVehicle == null ? _selectVehicle : null,
              borderRadius:
                  BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: selectedVehicle == null
                    ? const Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Select Vehicle',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedVehicle.registration,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Fleet: ${selectedVehicle.fleetNumber}',
                          ),

                          Text(
                            '${selectedVehicle.make} ${selectedVehicle.model}',
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
                  widget.mileageController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Odometer',
                prefixIcon:
                    Icon(Icons.speed),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Fuel Level',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [                _fuelChip('Full'),
                _fuelChip('¾'),
                _fuelChip('½'),
                _fuelChip('¼'),
                _fuelChip('Empty'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fuelChip(String value) {
    return ChoiceChip(
      label: Text(value),
      selected: _fuelLevel == value,
      onSelected: (_) {
        setState(() {
          _fuelLevel = value;
        });

        widget.onFuelLevelChanged?.call(value);
      },
    );
  }
}
