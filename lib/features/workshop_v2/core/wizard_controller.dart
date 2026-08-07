import 'package:flutter/foundation.dart';

class WizardController extends ChangeNotifier {
  WizardController({
    required this.totalSteps,
  });

  final int totalSteps;

  int _currentStep = 0;

  int get currentStep => _currentStep;

  double get progress =>
      (_currentStep + 1) / totalSteps;

  bool get isFirstStep =>
      _currentStep == 0;

  bool get isLastStep =>
      _currentStep == totalSteps - 1;

  bool next() {
    if (isLastStep) {
      return false;
    }

    _currentStep++;
    notifyListeners();
    return true;
  }

  bool previous() {
    if (isFirstStep) {
      return false;
    }

    _currentStep--;
    notifyListeners();
    return true;
  }

  void jumpTo(int step) {
    if (step < 0 || step >= totalSteps) {
      return;
    }

    _currentStep = step;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    notifyListeners();
  }
}