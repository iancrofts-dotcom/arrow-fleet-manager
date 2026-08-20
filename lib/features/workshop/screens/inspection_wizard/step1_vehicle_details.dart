import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_page_scaffold.dart';
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
  State<Step1VehicleDetails> createState() => _Step1VehicleDetailsState();
}

class _Step1VehicleDetailsState extends State<Step1VehicleDetails> {
  final _formKey = GlobalKey<FormState>();

  final _registrationController = TextEditingController();

  final _fleetNumberController = TextEditingController();

  final _mileageController = TextEditingController();

  WorkshopInspectionType? _inspectionType;

  late final InspectionWizardController _controller;

  final InspectionTemplateRepository _templateRepository =
      InspectionTemplateRepository();

  List<Vehicle> _vehicles = [];
  List<User> _technicians = [];
  List<InspectionTemplate> _templates = [];

  Vehicle? _selectedVehicle;
  User? _selectedTechnician;
  String _templateSelection = 'default';

  bool _loading = true;
  String? _loadError;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();

    _registrationController.text = widget.data.registration ?? '';

    _fleetNumberController.text = widget.data.fleetNumber ?? '';

    if (widget.data.mileage != null) {
      _mileageController.text = widget.data.mileage.toString();
    }

    _inspectionType = widget.data.inspectionType;

    _controller = InspectionWizardController(data: widget.data);
    _loadStepData();
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

    widget.data.mileage = int.parse(_mileageController.text);

    widget.data.inspectionType = _inspectionType;

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
    }

    if (_selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a technician')),
      );
      return;
    }

    widget.onNext();
  }

  Future<void> _loadStepData() async {
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<Object>([
        _controller.loadVehicles(),
        UserService.instance.getUsersByRole(UserRole.technician),
        _templateRepository.getActiveTemplates(),
      ]);
      if (!mounted || request != _loadRequest) return;

      final vehicles = results[0] as List<Vehicle>;
      final technicians = results[1] as List<User>;
      final templates = results[2] as List<InspectionTemplate>;
      final selectedVehicle = _vehicleForId(
        vehicles,
        _selectedVehicle?.id ?? widget.data.vehicleId,
      );
      final selectedTechnician = _technicianForId(
        technicians,
        _selectedTechnician?.id ?? widget.data.technicianId,
      );
      final selectedTemplate = _templateForIdIn(
        templates,
        widget.data.templateId,
      );

      setState(() {
        _vehicles = vehicles;
        _technicians = technicians;
        _templates = templates;
        _selectedVehicle = selectedVehicle;
        _selectedTechnician = selectedTechnician;
        _templateSelection = selectedTemplate?.id.toString() ?? 'default';
        _loading = false;
      });

      // A template that is no longer active cannot be used for a new
      // inspection. Preserve valid selections; clear only this stale one.
      if (widget.data.templateId != null && selectedTemplate == null) {
        widget.data.templateId = null;
        widget.data.templateName = null;
        widget.data.checklistItems = [];
        widget.data.repairJobs = [];
      }
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _loading = false;
        _loadError =
            'Unable to load the vehicles, technicians, or inspection templates.';
      });
    }
  }

  Vehicle? _vehicleForId(List<Vehicle> vehicles, int? id) {
    if (id == null) return null;
    for (final vehicle in vehicles) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  User? _technicianForId(List<User> technicians, String? id) {
    if (id == null) return null;
    for (final technician in technicians) {
      if (technician.id == id) return technician;
    }
    return null;
  }

  InspectionTemplate? _templateForIdIn(
    List<InspectionTemplate> templates,
    int? templateId,
  ) {
    if (templateId == null) return null;
    for (final template in templates) {
      if (template.id == templateId) return template;
    }
    return null;
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

  void _selectTechnician(User technician) {
    setState(() {
      _selectedTechnician = technician;

      widget.data.technicianId = technician.id;
      widget.data.technicianName = technician.username;
      widget.data.technician = technician.username;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: AppLoadingState(label: 'Loading inspection setup...'),
      );
    }

    if (_loadError != null) {
      return AppErrorState(message: _loadError!, onRetry: _loadStepData);
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Vehicle Details',
            style: Theme.of(context).textTheme.headlineSmall,
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

                  VehicleSelector(
                    vehicles: _vehicles,
                    selectedVehicle: _selectedVehicle,
                    onChanged: (vehicle) {
                      if (vehicle == null) return;

                      setState(() {
                        _selectedVehicle = vehicle;

                        _controller.selectVehicle(vehicle);

                        _registrationController.text = vehicle.registration;

                        _fleetNumberController.text = vehicle.fleetNumber;
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
              child: DropdownButtonFormField<String>(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the technician responsible for this inspection.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_technicians.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No active technicians are available. '
                              'Add an active Technician user before starting an inspection.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<User>(
                      initialValue: _selectedTechnician,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Inspection Technician',
                        prefixIcon: Icon(Icons.engineering_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _technicians
                          .map(
                            (technician) => DropdownMenuItem<User>(
                              value: technician,
                              child: Text(
                                technician.username,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (technician) {
                        if (technician == null) {
                          return;
                        }

                        _selectTechnician(technician);
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
            controller: _mileageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Current Mileage'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter the mileage';
              }

              if (int.tryParse(value) == null) {
                return 'Mileage must be a number';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<WorkshopInspectionType>(
            initialValue: _inspectionType,
            decoration: const InputDecoration(labelText: 'Inspection Type'),
            items: WorkshopInspectionType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.name)),
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
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
