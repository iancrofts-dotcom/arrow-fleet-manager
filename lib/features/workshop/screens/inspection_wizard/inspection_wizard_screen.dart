import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../auth/services/permission_service.dart';
import '../../models/inspection_wizard_data.dart';
import '../../services/inspection_save_service.dart';
import 'step1_vehicle_details.dart';
import 'step2_checklist.dart';
import 'step3_summary.dart';
import 'step4_repairs.dart';
import 'step5_signoff.dart';

const List<String> _steps = [
  'Vehicle',
  'Checklist',
  'Summary',
  'Repairs',
  'Sign-off',
];

class InspectionWizardScreen extends StatefulWidget {
  const InspectionWizardScreen({super.key});

  @override
  State<InspectionWizardScreen> createState() =>
      _InspectionWizardScreenState();
}

class _InspectionWizardScreenState extends State<InspectionWizardScreen> {
  final InspectionWizardData wizardData = InspectionWizardData();
  final InspectionSaveService _saveService = InspectionSaveService();

  static const int totalSteps = 5;

  int currentStep = 0;
  bool _allowPop = false;

  double get progress => (currentStep + 1) / totalSteps;

  bool get _hasChanges {
    return currentStep > 0 ||
        wizardData.vehicleId != null ||
        wizardData.mileage != null ||
        wizardData.inspectionType != null ||
        wizardData.checklistItems.any(
          (item) => item.completed || item.notes.isNotEmpty,
        );
  }

  Future<void> _backToWorkshop() async {
    if (!_hasChanges) {
      _closeWizard();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this inspection?'),
        content: const Text(
          'Your inspection changes will not be saved.',
        ),
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

    if (discard == true && mounted) {
      _closeWizard();
    }
  }

  void _closeWizard([Object? result]) {
    setState(() => _allowPop = true);
    Navigator.of(context).pop(result);
  }

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep++;
      });
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  Future<void> finishInspection() async {
    try {
      final inspectionId = await _saveService.saveInspection(wizardData);

      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Inspection Saved'),
          content: Text(
            'Inspection #$inspectionId has been saved successfully.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        _closeWizard(true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          title: const Text('Save Failed'),
          content: Text(e.toString()),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildStep() {
    switch (currentStep) {
      case 0:
        return Step1VehicleDetails(
          data: wizardData,
          onNext: nextStep,
        );

      case 1:
        return Step2Checklist(
          data: wizardData,
          onNext: nextStep,
          onPrevious: previousStep,
        );

      case 2:
        return Step3Summary(
          data: wizardData,
          onNext: nextStep,
          onPrevious: previousStep,
        );

      case 3:
        return Step4Repairs(
          data: wizardData,
          onNext: nextStep,
          onPrevious: previousStep,
        );

      case 4:
        return Step5Signoff(
          data: wizardData,
          onPrevious: previousStep,
          onFinish: finishInspection,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageWorkshop) {
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
            : '$registration • $templateName';

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _backToWorkshop();
        }
      },
      child: AppPageScaffold(
        title: 'Inspection Wizard',
        subtitle: subtitle,
        child: Column(
          children: [
            SectionCard(
              child: _ProgressStepper(
                currentStep: currentStep,
                progress: progress,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SectionCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  final int currentStep;
  final double progress;

  const _ProgressStepper({
    required this.currentStep,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Inspection progress',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                  ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: List.generate(
            _steps.length,
            (index) {
              final complete = index < currentStep;
              final active = index == currentStep;

              final color = complete || active
                  ? scheme.primary
                  : scheme.outlineVariant;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              complete
                                  ? Icons.check
                                  : Icons.circle,
                              size: complete
                                  ? 18
                                  : active
                                      ? 10
                                      : 8,
                              color: complete || active
                                  ? scheme.onPrimary
                                  : scheme.outline,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            _steps[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: active
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),

                    if (index != _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentStep
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
