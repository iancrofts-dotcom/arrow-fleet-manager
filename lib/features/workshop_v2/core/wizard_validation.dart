abstract class WizardValidation {
  const WizardValidation();

  /// Returns true when the step is valid.
  bool validate();

  /// Optional message shown when validation fails.
  String? get message;
}

class AlwaysValid extends WizardValidation {
  const AlwaysValid();

  @override
  bool validate() => true;

  @override
  String? get message => null;
}