import '../models/inspection.dart';

class InspectionService {
  static int _inspectionSequence = 1;

  Inspection createInspection() {
    return Inspection(
      inspectionNumber: generateInspectionNumber(),
      inspectionDate: DateTime.now(),
    );
  }

  String generateInspectionNumber() {
    final year = DateTime.now().year;

    final number =
        'AST-$year-${_inspectionSequence.toString().padLeft(6, '0')}';

    _inspectionSequence++;

    return number;
  }

  bool validateInspection(Inspection inspection) {
    return inspection.registration.trim().isNotEmpty &&
        inspection.driver.trim().isNotEmpty &&
        inspection.inspector.trim().isNotEmpty;
  }

  void resetSequence() {
    _inspectionSequence = 1;
  }

  int currentSequence() {
    return _inspectionSequence;
  }
}