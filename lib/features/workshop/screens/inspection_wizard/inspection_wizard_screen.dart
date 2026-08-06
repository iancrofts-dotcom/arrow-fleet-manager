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

  int _currentStep = 0;

  static const int _totalSteps = 5;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return Step1VehicleDetails(
          data: wizardData,
          onNext: _nextStep,
        );

      case 1:
        return Step2Checklist(
          data: wizardData,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );

      case 2:
        return Step3Summary(
          data: wizardData,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );

      case 3:
        return Step4Repairs(
          data: wizardData,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );

      case 4:
        return Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                size: 72,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Step 5\nSign-off',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Coming next',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Vehicle Details';
      case 1:
        return 'Inspection Checklist';
      case 2:
        return 'Inspection Summary';
      case 3:
        return 'Repair Review';
      case 4:
        return 'Sign-off';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (_currentStep + 1) / _totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workshop Inspection',
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
          ),
          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _stepTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}