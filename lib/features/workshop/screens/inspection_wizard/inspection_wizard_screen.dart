import 'package:flutter/material.dart';

import '../../models/inspection_wizard_data.dart';
import '../../services/inspection_save_service.dart';

import 'step1_vehicle_details.dart';
import 'step2_checklist.dart';
import 'step3_summary.dart';
import 'step4_repairs.dart';
import 'step5_signoff.dart';

class InspectionWizardScreen extends StatefulWidget {
  const InspectionWizardScreen({super.key});

  @override
  State<InspectionWizardScreen> createState() =>
      _InspectionWizardScreenState();
}

class _InspectionWizardScreenState
    extends State<InspectionWizardScreen> {
  final InspectionWizardData wizardData =
      InspectionWizardData();

  final InspectionSaveService _saveService =
      InspectionSaveService();

  static const int totalSteps = 5;

  int currentStep = 0;

  final List<String> stepTitles = const [
    'Vehicle Details',
    'Inspection Checklist',
    'Inspection Summary',
    'Repair Review',
    'Sign-off',
  ];

  double get progress =>
      (currentStep + 1) / totalSteps;

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
      final inspectionId =
          await _saveService.saveInspection(
        wizardData,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text(
            'Inspection Saved',
          ),
          content: Text(
            'Inspection #$inspectionId has been saved successfully.',
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          title: const Text(
            'Save Failed',
          ),
          content: Text(
            e.toString(),
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context),
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Workshop Inspection',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),

              const SizedBox(height: 8),

              Text(
                stepTitles[currentStep],
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),

              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius:
                    BorderRadius.circular(8),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Card(
                  clipBehavior:
                      Clip.antiAlias,
                  elevation: 2,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: buildStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}