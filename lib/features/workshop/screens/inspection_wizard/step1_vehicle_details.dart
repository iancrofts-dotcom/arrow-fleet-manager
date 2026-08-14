import 'package:flutter/material.dart';

import '../../models/inspection_wizard_data.dart';
import '../../models/workshop_inspection.dart';

import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/widgets/vehicle_selector.dart';

import '../../controllers/inspection_wizard_controller.dart';
import '../../../auth/models/user.dart';
import '../../../auth/models/user_role.dart';
import '../../../auth/services/user_service.dart';
import '../../models/inspection_template.dart';
import '../../repositories/inspection_template_repository.dart';

class Step1VehicleDetails extends StatefulWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;

  const Step1VehicleDetails({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<Step1VehicleDetails> createState() =>
      _Step1VehicleDetailsState();
}

class _Step1VehicleDetailsState
    extends State<Step1VehicleDetails> {
  final _formKey = GlobalKey<FormState>();

  final _registrationController =
      TextEditingController();

  final _fleetNumberController =
      TextEditingController();

  final _mileageController =
      TextEditingController();

  WorkshopInspectionType? _inspectionType;

  late final InspectionWizardController _controller;

List<Vehicle> _vehicles = [];
List<User> _technicians = [];

Vehicle? _selectedVehicle;
User? _selectedTechnician;

bool _loading = true;
bool _loadingTechnicians = true;
List<InspectionTemplate> _templates = [];
bool _loadingTemplates = true;
String _templateSelection = 'default';

  @override
  void initState() {
    super.initState();

    _registrationController.text =
        widget.data.registration ?? '';

    _fleetNumberController.text =
        widget.data.fleetNumber ?? '';

    if (widget.data.mileage != null) {
      _mileageController.text =
          widget.data.mileage.toString();
    }

    _inspectionType =
        widget.data.inspectionType;

        _controller = InspectionWizardController(
  data: widget.data,
);

_loadVehicles();
    _loadTechnicians();
    _loadTemplates();
  }



  @override
  void dispose() {
    _registrationController.dispose();
    _fleetNumberController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.data.mileage =
        int.parse(_mileageController.text);

    widget.data.inspectionType =
        _inspectionType;

    

    if (_selectedVehicle == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please select a vehicle'),
    ),
  );
  return;
}

if (_selectedTechnician == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please select a technician'),
    ),
  );
  return;
}

widget.onNext();

  }

  Future<void> _loadVehicles() async {
  final vehicles = await _controller.loadVehicles();

  if (!mounted) return;

  setState(() {
    _vehicles = vehicles;

    _loading = false;
  });
}

  Future<void> _loadTechnicians() async {
    final users = await UserService.instance.getUsersByRole(
      UserRole.technician,
    );

    if (!mounted) return;

    User? selected;

    if (widget.data.technicianId != null) {
      for (final technician in users) {
        final technicianId = int.tryParse(technician.id);

        if (technicianId == widget.data.technicianId) {
          selected = technician;
          break;
        }
      }
    }

    selected ??= _findTechnicianByName(
      users,
      widget.data.technicianName,
    );

    setState(() {
      _technicians = users;
      _selectedTechnician = selected;
      _loadingTechnicians = false;
    });
  }

  Future<void> _loadTemplates() async {
    final templates = await InspectionTemplateRepository().getActiveTemplates();

    if (!mounted) return;

    setState(() {
      _templates = templates;
      _templateSelection = widget.data.templateId?.toString() ?? 'default';
      _loadingTemplates = false;
    });
  }

  void _selectTemplate(String value) {
    final templateId = int.tryParse(value);
    final template = _templateForId(templateId);

    setState(() {
      _templateSelection = value;
      widget.data.templateId = templateId;
      widget.data.templateName = template?.name;
      widget.data.checklistItems = [];
      widget.data.repairJobs = [];
    });
  }

  InspectionTemplate? _templateForId(int? templateId) {
    if (templateId == null) return null;

    for (final template in _templates) {
      if (template.id == templateId) return template;
    }

    return null;
  }

  User? _findTechnicianByName(
    List<User> users,
    String? name,
  ) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    final target = name.trim().toLowerCase();

    for (final technician in users) {
      if (technician.username.toLowerCase() == target) {
        return technician;
      }
    }

    return null;
  }

  void _selectTechnician(
    User technician,
  ) {
    final technicianId = int.tryParse(technician.id);

    if (technicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This technician account has an invalid ID. '
            'Please recreate the technician user.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedTechnician = technician;

      widget.data.technicianId = technicianId;
      widget.data.technicianName =
          technician.username;
      widget.data.technician =
          technician.username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding:
            const EdgeInsets.all(24),
        children: [
          Text(
            'Vehicle Details',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 24),

          
                  Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 16),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          VehicleSelector(
            vehicles: _vehicles,
            selectedVehicle: _selectedVehicle,
            onChanged: (vehicle) {
              if (vehicle == null) return;

              setState(() {
                _selectedVehicle = vehicle;

                _controller.selectVehicle(vehicle);

                _registrationController.text =
                    vehicle.registration;

                _fleetNumberController.text =
                    vehicle.fleetNumber;
              });
            },
          ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _registrationController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Registration',
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _fleetNumberController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Fleet Number',
          ),
        ),
      ],
    ),
  ),
),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingTemplates
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      initialValue: _templateSelection,
                      decoration: const InputDecoration(
                        labelText: 'Inspection Template',
                        prefixIcon: Icon(Icons.article_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'default',
                          child: Text('Default Workshop Checklist'),
                        ),
                        ..._templates.map(
                          (template) => DropdownMenuItem(
                            value: template.id.toString(),
                            child: Text(template.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _selectTemplate(value);
                        }
                      },
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the technician responsible for this inspection.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingTechnicians)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else if (_technicians.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No active technicians are available. '
                              'Add an active Technician user before starting an inspection.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<User>(
                      initialValue:
                          _selectedTechnician,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Inspection Technician',
                        prefixIcon:
                            Icon(Icons.engineering_outlined),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: _technicians
                          .map(
                            (technician) =>
                                DropdownMenuItem<User>(
                              value: technician,
                              child: Text(
                                technician.username,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (technician) {
                        if (technician == null) {
                          return;
                        }

                        _selectTechnician(
                          technician,
                        );
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Select a technician';
                        }

                        return null;
                      },
                    ),
                ],
              ),
            ),
          ),

          TextFormField(
            controller:
                _mileageController,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'Current Mileage',
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Enter the mileage';
              }

              if (int.tryParse(value) ==
                  null) {
                return 'Mileage must be a number';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<WorkshopInspectionType>(
  initialValue: _inspectionType,
  decoration: const InputDecoration(
    labelText: 'Inspection Type',
  ),
  items: WorkshopInspectionType.values
      .map(
        (type) => DropdownMenuItem(
          value: type,
          child: Text(type.name),
        ),
      )
      .toList(),
  onChanged: (value) {
    setState(() {
      _inspectionType = value;
    });
  },
  validator: (value) =>
      value == null ? 'Select an inspection type' : null,
),

          const SizedBox(height: 40),

          Align(
            alignment:
                Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _continue,
              icon:
                  const Icon(Icons.arrow_forward),
              label:
                  const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
