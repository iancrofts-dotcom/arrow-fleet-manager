abstract class WizardStep {
  /// Called before the step becomes visible.
  Future<void> onEntering() async {}

  /// Called before leaving the step.
  Future<void> onLeaving() async {}

  /// Determines whether the wizard can move forward.
  bool canContinue();

  /// Optional validation message.
  String? validationMessage() => null;
}