import 'package:flutter/material.dart';

import '../../../backend/vehicles/backend_vehicle.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/backend_workshop_template.dart';
import '../../../backend/workshop/backend_workshop_writes.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class CentralNewWorkshopInspectionScreen extends StatefulWidget {
  const CentralNewWorkshopInspectionScreen({
    super.key,
    required this.repository,
    this.vehicleRepository,
  });

  final BackendWorkshopRepository repository;
  final BackendVehicleRepository? vehicleRepository;

  @override
  State<CentralNewWorkshopInspectionScreen> createState() =>
      _CentralNewWorkshopInspectionScreenState();
}

class _CentralNewWorkshopInspectionScreenState
    extends State<CentralNewWorkshopInspectionScreen> {
  late final BackendVehicleRepository _vehicles;
  late Future<_Options> _options;
  final _formKey = GlobalKey<FormState>();
  final _mileage = TextEditingController();
  final _notes = TextEditingController();
  String? _vehicleId;
  String? _technicianId;
  String? _templateId;
  String _type = 'scheduledService';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _vehicles =
        widget.vehicleRepository ??
        BackendVehicleRepository(SupabaseVehicleGateway());
    _options = _loadOptions();
  }

  Future<_Options> _loadOptions() async {
    final vehicles = (await _vehicles.listVehicles())
        .where((vehicle) => vehicle.isActive)
        .toList(growable: false);
    final technicians = await widget.repository.listTechnicians();
    final templates = await widget.repository.listTemplates();
    if (_templateId == null && templates.isNotEmpty) {
      final matching = _matchingTemplates(templates, _type);
      if (matching.isNotEmpty) {
        _templateId = matching
            .firstWhere(
              (template) => template.isDefault,
              orElse: () => matching.first,
            )
            .id;
      }
    }
    return _Options(
      vehicles: vehicles,
      technicians: technicians,
      templates: templates,
    );
  }

  List<BackendWorkshopTemplate> _matchingTemplates(
    List<BackendWorkshopTemplate> templates,
    String type,
  ) => templates
      .where(
        (template) =>
            template.isActive &&
            (template.inspectionType == null ||
                template.inspectionType == type),
      )
      .toList(growable: false);

  void _inspectionTypeChanged(String type, List<BackendWorkshopTemplate> all) {
    final matching = _matchingTemplates(all, type);
    setState(() {
      _type = type;
      if (!matching.any((template) => template.id == _templateId)) {
        _templateId = matching.isEmpty
            ? null
            : matching
                  .firstWhere(
                    (template) => template.isDefault,
                    orElse: () => matching.first,
                  )
                  .id;
      }
    });
  }

  @override
  void dispose() {
    _mileage.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        !_formKey.currentState!.validate() ||
        _vehicleId == null ||
        _templateId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await widget.repository.createInspectionFromTemplate(
        BackendWorkshopTemplateInspectionCreate(
          vehicleId: _vehicleId!,
          templateId: _templateId!,
          inspectionType: _type,
          mileage: int.parse(_mileage.text.trim()),
          notes: _notes.text.trim(),
          technicianProfileId: _technicianId,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<BackendWorkshopInspection>(created);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create inspection: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'New workshop inspection',
    subtitle:
        'Create a central inspection from a pre-populated FleetIQ template.',
    child: FutureBuilder<_Options>(
      future: _options,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading workshop options...');
        }
        if (snapshot.hasError || snapshot.data == null) {
          return AppErrorState(
            title: 'Unable to load inspection options',
            message:
                'Vehicles, technicians or inspection templates could not be loaded.',
            onRetry: () => setState(() => _options = _loadOptions()),
          );
        }
        final options = snapshot.data!;
        final templates = _matchingTemplates(options.templates, _type);
        return Form(
          key: _formKey,
          child: ListView(
            children: [
              SectionCard(
                title: 'Inspection details',
                subtitle:
                    'The selected template automatically creates the full checklist.',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _vehicleId,
                      decoration: const InputDecoration(labelText: 'Vehicle'),
                      items: [
                        for (final vehicle in options.vehicles)
                          DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.registration} · ${vehicle.fleetNumber}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _vehicleId = value),
                      validator: (value) =>
                          value == null ? 'Select a vehicle.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Inspection type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'scheduledService',
                          child: Text('Scheduled service'),
                        ),
                        DropdownMenuItem(
                          value: 'defectInspection',
                          child: Text('Defect inspection'),
                        ),
                        DropdownMenuItem(
                          value: 'annualInspection',
                          child: Text('Annual inspection'),
                        ),
                        DropdownMenuItem(
                          value: 'motPreparation',
                          child: Text('MOT preparation'),
                        ),
                        DropdownMenuItem(
                          value: 'repairInspection',
                          child: Text('Repair inspection'),
                        ),
                        DropdownMenuItem(
                          value: 'returnToService',
                          child: Text('Return to service'),
                        ),
                        DropdownMenuItem(
                          value: 'driverDailyInspection',
                          child: Text('Driver daily inspection'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _inspectionTypeChanged(value, options.templates);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('template-$_type-$_templateId'),
                      initialValue:
                          templates.any(
                            (template) => template.id == _templateId,
                          )
                          ? _templateId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Inspection template',
                      ),
                      items: [
                        for (final template in templates)
                          DropdownMenuItem(
                            value: template.id,
                            child: Text(
                              '${template.name} · v${template.version}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _templateId = value),
                      validator: (value) =>
                          value == null ? 'Select a template.' : null,
                    ),
                    if (templates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No active central template is available for this inspection type.',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mileage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Mileage'),
                      validator: (value) {
                        final mileage = int.tryParse(value?.trim() ?? '');
                        return mileage == null || mileage < 0
                            ? 'Enter a valid mileage.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _technicianId,
                      decoration: const InputDecoration(
                        labelText: 'Technician',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Not assigned'),
                        ),
                        for (final technician in options.technicians)
                          DropdownMenuItem<String?>(
                            value: technician.id,
                            child: Text(technician.username),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _technicianId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving || templates.isEmpty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(
                  _saving
                      ? 'Creating inspection...'
                      : 'Create pre-populated inspection',
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Options {
  const _Options({
    required this.vehicles,
    required this.technicians,
    required this.templates,
  });

  final List<BackendVehicle> vehicles;
  final List<BackendWorkshopTechnician> technicians;
  final List<BackendWorkshopTemplate> templates;
}
