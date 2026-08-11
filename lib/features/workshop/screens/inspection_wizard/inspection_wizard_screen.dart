import 'package:flutter/material.dart';

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
      Navigator.of(context).pop();
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
      Navigator.of(context).pop();
    }
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
        Navigator.pop(context, true);
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
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: theme.colorScheme.surfaceContainerLowest,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1440,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _InspectionHeader(
                        data: wizardData,
                        onBackToWorkshop: _backToWorkshop,
                      ),

                      const SizedBox(height: 20),

                      _ProgressStepper(
                        currentStep: currentStep,
                        progress: progress,
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: buildStep(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
}

class _InspectionHeader extends StatelessWidget {
  final InspectionWizardData data;
  final VoidCallback onBackToWorkshop;

  const _InspectionHeader({
    required this.data,
    required this.onBackToWorkshop,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final details = [
      (
        'Vehicle Registration',
        data.registration ?? 'Not selected',
      ),
      (
        'Fleet Number',
        data.fleetNumber ?? 'Not selected',
      ),
      (
        'Inspection Type',
        data.inspectionType?.name ?? 'Not selected',
      ),
      (
        'Technician',
        data.technicianName ?? 'Current technician',
      ),
      (
        'Date & Time',
        _dateLabel(data.dateStarted),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBackToWorkshop,
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              label: const Text(
                'Back to Workshop',
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Centred Arrow logo.
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 90,
            ),
            child: Image.asset(
              'assets/images/arrow_logo.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Arrow Fleet Manager',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),

          Text(
            'Workshop',
            style: Theme.of(context).textTheme.titleSmall,
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 28,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: details
                .map(
                  (detail) => _HeaderDetail(
                    label: detail.$1,
                    value: detail.$2,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _HeaderDetail extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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