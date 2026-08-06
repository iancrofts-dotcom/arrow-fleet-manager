import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/widgets/vehicle_picker_dialog.dart';
import '../models/workshop_inspection.dart';
import '../repositories/workshop_repository.dart';
import '../services/workshop_template_service.dart';
import 'workshop_checklist_screen.dart';

class NewWorkshopInspectionScreen extends StatefulWidget {
  const NewWorkshopInspectionScreen({super.key});

  @override
  State<NewWorkshopInspectionScreen> createState() =>
      _NewWorkshopInspectionScreenState();
}

class _NewWorkshopInspectionScreenState
    extends State<NewWorkshopInspectionScreen> {
  final _formKey = GlobalKey<FormState>();

  Vehicle? _selectedVehicle;

final WorkshopRepository _repository =
    WorkshopRepository();

final WorkshopTemplateService _templateService =
    const WorkshopTemplateService();
    
  final TextEditingController _technicianController =
      TextEditingController();

  final TextEditingController _mileageController =
      TextEditingController();

  String _inspectionType = 'PMI';

  @override
  void dispose() {
    _technicianController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectVehicle() async {
    final vehicle = await VehiclePickerDialog.show(context);

    if (vehicle == null) return;

    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  Future<void> _continue() async {
  if (_selectedVehicle == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a vehicle'),
      ),
    );
    return;
  }

  if (!_formKey.currentState!.validate()) {
    return;
  }

  final now = DateTime.now();

  // Create the inspection
  final inspection = WorkshopInspection(
    inspectionNumber: 'WS-${now.millisecondsSinceEpoch}',
    vehicleId: _selectedVehicle!.id!,
    registration: _selectedVehicle!.registration,
    fleetNumber: _selectedVehicle!.fleetNumber,
    technicianName: _technicianController.text.trim(),

    inspectionType: WorkshopInspectionType.annualInspection,
    status: WorkshopInspectionStatus.inProgress,
    vehicleStatus: VehicleWorkshopStatus.underRepair,

    dateStarted: now,

    mileage: int.parse(_mileageController.text),

    overallResult: InspectionResult.pending,

    inspectionScore: 0,
    criticalFailures: 0,
    advisories: 0,
    repairsRequired: 0,
    labourHours: 0,
    totalCost: 0,
    notes: '',

    createdAt: now,
    updatedAt: now,
  );

  // Save inspection
  final inspectionId =
      await _repository.createInspection(inspection);

  // Generate checklist
  final checklist =
      _templateService.createDefaultPmiChecklist(
    inspectionId: inspectionId,
  );

  // Save checklist items
  await _repository.addInspectionItems(checklist);

  if (!mounted) return;

  // Open checklist
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WorkshopChecklistScreen(
        inspectionId: inspectionId,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Workshop Inspection'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _selectedVehicle == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No vehicle selected',
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _selectVehicle,
                            icon: const Icon(Icons.directions_bus),
                            label: const Text('Select Vehicle'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Vehicle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(
                              Icons.directions_bus,
                              size: 40,
                            ),
                            title: Text(
                              '${_selectedVehicle!.fleetNumber} • ${_selectedVehicle!.registration}',
                            ),
                            subtitle: Text(
                              '${_selectedVehicle!.make} ${_selectedVehicle!.model}',
                            ),
                          ),
                          const Divider(),
                          Text('Year: ${_selectedVehicle!.year}'),
                          Text('VIN: ${_selectedVehicle!.vin}'),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _selectVehicle,
                            icon: const Icon(Icons.edit),
                            label: const Text('Change Vehicle'),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _inspectionType,
              decoration: const InputDecoration(
                labelText: 'Inspection Type',
                prefixIcon: Icon(Icons.fact_check),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'PMI',
                  child: Text('PMI'),
                ),
                DropdownMenuItem(
                  value: 'Safety',
                  child: Text('Safety'),
                ),
                DropdownMenuItem(
                  value: 'MOT',
                  child: Text('MOT'),
                ),
                DropdownMenuItem(
                  value: 'Service',
                  child: Text('Service'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _inspectionType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _technicianController,
              decoration: const InputDecoration(
                labelText: 'Technician',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Enter technician name'
                      : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mileage',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Enter mileage'
                      : null,
            ),

            const SizedBox(height: 30),

            FilledButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to Checklist'),
            ),
          ],
        ),
      ),
    );
  }
}