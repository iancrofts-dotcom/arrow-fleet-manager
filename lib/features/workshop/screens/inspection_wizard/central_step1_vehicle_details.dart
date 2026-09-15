import 'package:flutter/material.dart';

import '../../../../backend/vehicles/backend_vehicle.dart';
import '../../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../../../backend/workshop/backend_workshop_repository.dart';
import '../../../../backend/workshop/backend_workshop_template.dart';
import '../../../../backend/workshop/backend_workshop_writes.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_item.dart';
import '../../models/inspection_wizard_data.dart';
import '../../models/workshop_inspection.dart';

/// Central-data adapter for the original FleetIQ wizard Step 1.
///
/// The layout and movement remain wizard-first; only the option source changes
/// from SQLite repositories to the Supabase backend repositories.
class CentralStep1VehicleDetails extends StatefulWidget {
  const CentralStep1VehicleDetails({
    super.key,
    required this.data,
    required this.repository,
    required this.onNext,
    this.vehicleRepository,
  });

  final InspectionWizardData data;
  final BackendWorkshopRepository repository;
  final BackendVehicleRepository? vehicleRepository;
  final VoidCallback onNext;

  @override
  State<CentralStep1VehicleDetails> createState() =>
      _CentralStep1VehicleDetailsState();
}

class _CentralStep1VehicleDetailsState
    extends State<CentralStep1VehicleDetails> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  late final BackendVehicleRepository _vehicleRepository;

  List<BackendVehicle> _vehicles = const [];
  List<BackendWorkshopTechnician> _technicians = const [];
  List<BackendWorkshopTemplate> _templates = const [];
  String? _vehicleId;
  String? _technicianId;
  String? _templateId;
  WorkshopInspectionType? _inspectionType;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _vehicleRepository =
        widget.vehicleRepository ??
        BackendVehicleRepository(SupabaseVehicleGateway());
    _vehicleId = widget.data.centralVehicleId;
    _technicianId = widget.data.technicianId;
    _templateId = widget.data.centralTemplateId;
    _inspectionType = widget.data.inspectionType;
    if (widget.data.mileage != null) {
      _mileageController.text = widget.data.mileage.toString();
    }
    _load();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait<Object>([
        _vehicleRepository.listVehicles(),
        widget.repository.listTechnicians(),
        widget.repository.listTemplates(),
      ]);
      if (!mounted) return;
      final vehicles = (results[0] as List<BackendVehicle>)
          .where((vehicle) => vehicle.isActive)
          .toList(growable: false);
      final technicians = results[1] as List<BackendWorkshopTechnician>;
      final templates = (results[2] as List<BackendWorkshopTemplate>)
          .where((template) => template.isActive)
          .toList(growable: false);
      setState(() {
        _vehicles = vehicles;
        _technicians = technicians;
        _templates = templates;
        _loading = false;
      });
      if (_inspectionType != null) {
        _ensureTemplateForType(_inspectionType!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError =
            'Unable to load the vehicles, technicians, or inspection templates.';
      });
    }
  }

  List<BackendWorkshopTemplate> _matchingTemplates(
    WorkshopInspectionType? type,
  ) {
    if (type == null) return _templates;
    return _templates
        .where(
          (template) =>
              template.inspectionType == null ||
              template.inspectionType == type.name,
        )
        .toList(growable: false);
  }

  void _ensureTemplateForType(WorkshopInspectionType type) {
    final matching = _matchingTemplates(type);
    if (matching.isEmpty) {
      setState(() => _templateId = null);
      return;
    }
    if (!matching.any((template) => template.id == _templateId)) {
      final selected = matching.firstWhere(
        (template) => template.isDefault,
        orElse: () => matching.first,
      );
      setState(() => _templateId = selected.id);
    }
  }

  BackendVehicle? _vehicle(String? id) {
    if (id == null) return null;
    for (final vehicle in _vehicles) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  BackendWorkshopTechnician? _technician(String? id) {
    if (id == null) return null;
    for (final technician in _technicians) {
      if (technician.id == id) return technician;
    }
    return null;
  }

  BackendWorkshopTemplate? _template(String? id) {
    if (id == null) return null;
    for (final template in _templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final vehicle = _vehicle(_vehicleId);
    final technician = _technician(_technicianId);
    final template = _template(_templateId);
    if (vehicle == null || technician == null || template == null) return;

    setState(() => _loading = true);
    try {
      final keepExistingChecklist =
          widget.data.centralTemplateId == template.id &&
          widget.data.checklistItems.isNotEmpty;
      final templateItems = keepExistingChecklist
          ? null
          : await widget.repository.listTemplateItems(template.id);
      if (!mounted) return;
      widget.data
        ..vehicleId = vehicle.legacyId
        ..centralVehicleId = vehicle.id
        ..registration = vehicle.registration
        ..fleetNumber = vehicle.fleetNumber
        ..mileage = int.parse(_mileageController.text.trim())
        ..inspectionType = _inspectionType
        ..templateId = null
        ..centralTemplateId = template.id
        ..templateName = template.name
        ..technicianId = technician.id
        ..technicianName = technician.username
        ..technician = technician.username;
      if (templateItems != null) {
        widget.data
          ..checklistItems = templateItems
              .map(
                (item) => InspectionChecklistItem(
                  id: item.id,
                  category: item.sectionTitle?.trim().isNotEmpty == true
                      ? item.sectionTitle!
                      : item.category,
                  title: item.title,
                  description: item.description,
                  status: _status(item.defaultStatus),
                  priority: _priority(item.repairPriority),
                  mandatory: item.mandatory,
                  photoRequired: item.photoRequiredOnFail,
                  autoCreateRepair: item.autoCreateRepair,
                  allowNotes: item.allowNotes,
                  responseType: _responseType(item.responseType),
                ),
              )
              .toList(growable: false)
          ..repairJobs = [];
      }
      widget.onNext();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load the selected checklist.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ChecklistStatus _status(String value) => switch (value) {
    'pass' => ChecklistStatus.pass,
    'advisory' => ChecklistStatus.advisory,
    'fail' => ChecklistStatus.fail,
    _ => ChecklistStatus.pending,
  };

  ChecklistPriority _priority(String value) => switch (value) {
    'low' => ChecklistPriority.low,
    'high' => ChecklistPriority.high,
    'critical' => ChecklistPriority.critical,
    _ => ChecklistPriority.medium,
  };

  InspectionResponseType _responseType(String value) => switch (value) {
    'yesNoNotApplicable' => InspectionResponseType.yesNoNotApplicable,
    'text' => InspectionResponseType.text,
    'numeric' => InspectionResponseType.numeric,
    _ => InspectionResponseType.passFailNotApplicable,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: AppLoadingState(label: 'Loading inspection setup...'),
      );
    }
    if (_loadError != null) {
      return AppErrorState(message: _loadError!, onRetry: _load);
    }

    final matchingTemplates = _matchingTemplates(_inspectionType);
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          SectionCard(
            title: 'Vehicle and inspection context',
            subtitle: 'Choose the vehicle, technician, and checklist template.',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _vehicleId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  items: [
                    for (final vehicle in _vehicles)
                      DropdownMenuItem(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.registration} · ${vehicle.fleetNumber}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _vehicleId = value),
                  validator: (value) =>
                      value == null ? 'Select a vehicle' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_vehicleId),
                  initialValue: _vehicle(_vehicleId)?.registration ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Registration'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey('fleet-$_vehicleId'),
                  initialValue: _vehicle(_vehicleId)?.fleetNumber ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Fleet Number'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Inspection details',
            child: Column(
              children: [
                DropdownButtonFormField<WorkshopInspectionType>(
                  initialValue: _inspectionType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Inspection Type',
                    prefixIcon: Icon(Icons.fact_check_outlined),
                  ),
                  items: [
                    for (final type in WorkshopInspectionType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _inspectionType = value);
                    _ensureTemplateForType(value);
                  },
                  validator: (value) =>
                      value == null ? 'Select an inspection type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mileage',
                    prefixIcon: Icon(Icons.speed_outlined),
                  ),
                  validator: (value) {
                    final mileage = int.tryParse(value?.trim() ?? '');
                    return mileage == null || mileage <= 0
                        ? 'Enter valid mileage'
                        : null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Checklist template',
            subtitle: 'Select the checklist used for this inspection.',
            child: DropdownButtonFormField<String>(
              key: ValueKey('template-${_inspectionType?.name}-$_templateId'),
              initialValue: matchingTemplates.any((t) => t.id == _templateId)
                  ? _templateId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Inspection Template',
                prefixIcon: Icon(Icons.article_outlined),
              ),
              items: [
                for (final template in matchingTemplates)
                  DropdownMenuItem(
                    value: template.id,
                    child: Text(template.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _templateId = value),
              validator: (value) => value == null ? 'Select a template' : null,
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Technician',
            child: DropdownButtonFormField<String>(
              initialValue: _technicianId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Assigned Technician',
                prefixIcon: Icon(Icons.engineering_outlined),
              ),
              items: [
                for (final technician in _technicians)
                  DropdownMenuItem(
                    value: technician.id,
                    child: Text(technician.username),
                  ),
              ],
              onChanged: (value) => setState(() => _technicianId = value),
              validator: (value) =>
                  value == null ? 'Select a technician' : null,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue to Checklist'),
            ),
          ),
        ],
      ),
    );
  }
}
