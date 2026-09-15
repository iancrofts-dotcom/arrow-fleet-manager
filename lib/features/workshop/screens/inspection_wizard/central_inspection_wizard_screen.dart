import 'package:flutter/material.dart';

import '../../../../backend/workshop/backend_workshop_repository.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../auth/services/permission_service.dart';
import '../../models/inspection_wizard_data.dart';
import '../../services/central_inspection_wizard_save_service.dart';
import 'central_step1_vehicle_details.dart';
import 'step2_checklist.dart';
import 'step3_summary.dart';
import 'step4_repairs.dart';
import 'step5_signoff.dart';

const _centralWizardSteps = [
  'Vehicle',
  'Checklist',
  'Summary',
  'Repairs',
  'Sign-off',
];

/// The original FleetIQ Workshop walkthrough with Supabase persistence.
///
/// Checklist selections stay in memory while moving through the wizard. There
/// is no network reload after Pass / Advisory / Fail taps.
class CentralInspectionWizardScreen extends StatefulWidget {
  const CentralInspectionWizardScreen({super.key, required this.repository});

  final BackendWorkshopRepository repository;

  @override
  State<CentralInspectionWizardScreen> createState() =>
      _CentralInspectionWizardScreenState();
}

class _CentralInspectionWizardScreenState
    extends State<CentralInspectionWizardScreen> {
  final InspectionWizardData wizardData = InspectionWizardData();
  late final CentralInspectionWizardSaveService _saveService;

  int currentStep = 0;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _saveService = CentralInspectionWizardSaveService(widget.repository);
  }

  double get progress => (currentStep + 1) / _centralWizardSteps.length;

  bool get _hasChanges =>
      currentStep > 0 ||
      wizardData.centralVehicleId != null ||
      wizardData.mileage != null ||
      wizardData.checklistItems.any(
        (item) => item.completed || item.notes.isNotEmpty,
      );

  void _next() {
    if (currentStep < _centralWizardSteps.length - 1) {
      setState(() => currentStep++);
    }
  }

  void _previous() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  void _close([String? inspectionId]) {
    setState(() => _allowPop = true);
    Navigator.of(context).pop<String?>(inspectionId);
  }

  Future<void> _backToWorkshop() async {
    if (!_hasChanges) {
      _close();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this inspection?'),
        content: const Text('Your inspection changes will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _close();
  }

  Future<void> _finish() async {
    try {
      final inspection = await _saveService.saveInspection(wizardData);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Inspection Saved'),
          content: Text(
            '${inspection.inspectionNumber} has been saved to FleetIQ central Workshop.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) _close(inspection.id);
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.error, color: Colors.red, size: 48),
          title: const Text('Save Failed'),
          content: Text('$error'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _step() => switch (currentStep) {
    0 => CentralStep1VehicleDetails(
      data: wizardData,
      repository: widget.repository,
      onNext: _next,
    ),
    1 => Step2Checklist(data: wizardData, onNext: _next, onPrevious: _previous),
    2 => Step3Summary(data: wizardData, onNext: _next, onPrevious: _previous),
    3 => Step4Repairs(data: wizardData, onNext: _next, onPrevious: _previous),
    4 => Step5Signoff(
      data: wizardData,
      onPrevious: _previous,
      onFinish: _finish,
    ),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canOperateWorkshop) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to create Workshop inspections.',
          ),
        ),
      );
    }

    final registration = wizardData.registration;
    final templateName = wizardData.templateName;
    final subtitle = registration == null || registration.trim().isEmpty
        ? 'Create a new Workshop inspection.'
        : templateName == null || templateName.trim().isEmpty
        ? registration
        : '$registration | $templateName';

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToWorkshop();
      },
      child: AppPageScaffold(
        title: 'Workshop Inspection',
        subtitle: subtitle,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SectionCard(
                child: _CentralProgressStepper(
                  currentStep: currentStep,
                  progress: progress,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _step()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CentralProgressStepper extends StatelessWidget {
  const _CentralProgressStepper({
    required this.currentStep,
    required this.progress,
  });

  final int currentStep;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Step ${currentStep + 1} of ${_centralWizardSteps.length} | ${_centralWizardSteps[currentStep]}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
