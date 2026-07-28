import '../../../database/database_service.dart';
import '../../../database/inspection_repository.dart';

import '../models/inspection.dart';
import '../models/inspection_item.dart';
import '../repositories/inspection_results_repository.dart';

class InspectionService {
  InspectionService()
      : _repository = InspectionRepository(
          databaseService: DatabaseService(),
        ),
        _resultsRepository = InspectionResultsRepository(
          appDatabase: DatabaseService().database,
        );

  final InspectionRepository _repository;
  final InspectionResultsRepository _resultsRepository;

  static int _inspectionSequence = 1;

  Inspection createInspection() {
    return Inspection(
      inspectionNumber: generateInspectionNumber(),
      inspectionDate: DateTime.now(),
      status: 'New',
      overallResult: 'Pending',
      fuelLevel: 'Full',
    );
  }

  String generateInspectionNumber() {
    final year = DateTime.now().year;

    final number =
        'AST-$year-${_inspectionSequence.toString().padLeft(6, '0')}';

    _inspectionSequence++;

    return number;
  }

  bool validateInspection(
    Inspection inspection,
  ) {
    return inspection.driver.trim().isNotEmpty &&
        inspection.vehicleId != null &&
        inspection.mileage > 0;
  }

  /// Saves only the inspection header.
  /// Used by the ViewModel and any legacy code.
  Future<void> saveInspection(
    Inspection inspection,
  ) async {
    await _repository.saveInspection(
      inspection,
    );
  }

  /// Saves the inspection header and all checklist items.
  /// Used by the Driver Daily Walkaround screen.
  Future<void> saveInspectionWithResults(
    Inspection inspection,
    List<InspectionItem> items,
  ) async {
    await _repository.saveInspection(
      inspection,
    );

    await _resultsRepository.saveItems(
      inspectionNumber: inspection.inspectionNumber,
      items: items,
    );
  }

  Future<List<Inspection>> getInspections() {
    return _repository.getInspections();
  }

  Future<Inspection?> getInspectionById(
    int id,
  ) async {
    final inspections =
        await _repository.getInspections();

    try {
      return inspections.firstWhere(
        (inspection) => inspection.id == id,
      );
    } catch (_) {
      return null;
    }
  }  Future<List<Inspection>> getVehicleInspections(
    int vehicleId,
  ) async {
    final inspections =
        await _repository.getInspections();

    return inspections
        .where(
          (inspection) =>
              inspection.vehicleId == vehicleId,
        )
        .toList();
  }

  Future<List<InspectionItem>>
      getInspectionResults(
    String inspectionNumber,
  ) {
    return _resultsRepository.getItems(
      inspectionNumber,
    );
  }

  Future<List<InspectionItem>>
      getFailedInspectionResults(
    String inspectionNumber,
  ) {
    return _resultsRepository.getFailedItems(
      inspectionNumber,
    );
  }

  Future<void> deleteInspectionResults(
    String inspectionNumber,
  ) {
    return _resultsRepository.deleteInspectionResults(
      inspectionNumber,
    );
  }

  Future<int> getInspectionCount() {
    return _repository.getInspectionCount();
  }

  void resetSequence() {
    _inspectionSequence = 1;
  }

  int currentSequence() {
    return _inspectionSequence;
  }
}