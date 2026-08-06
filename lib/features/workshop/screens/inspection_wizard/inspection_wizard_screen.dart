import 'package:flutter/material.dart';

import '../../models/inspection_wizard_data.dart';
import 'step1_vehicle_details.dart';
import 'step2_checklist.dart';
import 'step3_summary.dart';
import 'step4_repairs.dart';

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

  int currentStep = 0;

  void nextStep() {
    if (currentStep < 4) {
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

  Widget _buildStep() {
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
        return const Center(
          child: Text(
            'Step 5 - Sign Off\n(Coming Next)',
            textAlign: TextAlign.center,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workshop Inspection',
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentStep + 1) / 5,
          ),
          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Text(
              'Step ${currentStep + 1} of 5',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
          ),
          Expanded(
            child: _buildStep(),
          ),
        ],
      ),
    );
  }
}