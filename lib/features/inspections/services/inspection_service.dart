import '../../../database/database_service.dart';
import '../../../database/inspection_repository.dart';
import '../models/inspection.dart';

class InspectionService {
  InspectionService()
      : _repository = InspectionRepository(
          databaseService: DatabaseService(),
        );

  final InspectionRepository _repository;

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

  Future<void> saveInspection(Inspection inspection) async {
    await _repository.saveInspection(inspection);
  }

  void resetSequence() {
    _inspectionSequence = 1;
  }

  int currentSequence() {
    return _inspectionSequence;
  }
}