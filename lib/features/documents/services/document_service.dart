import '../models/fleet_document.dart';
import '../repositories/document_repository.dart';

class DocumentService {
  DocumentService();

  final DocumentRepository _repository =
      DocumentRepository();

  Future<List<FleetDocument>> getAll() {
    return _repository.getAll();
  }

  Future<List<FleetDocument>> getByDriver(
    int driverId,
  ) {
    return _repository.getByDriver(driverId);
  }

  Future<List<FleetDocument>> getByVehicle(
    int vehicleId,
  ) {
    return _repository.getByVehicle(vehicleId);
  }

  Future<void> save(
    FleetDocument document,
  ) {
    return _repository.save(document);
  }

  Future<void> delete(
    int id,
  ) {
    return _repository.delete(id);
  }

  String status(
    DateTime expiryDate,
  ) {
    if (expiryDate.isBefore(DateTime.now())) {
      return 'Expired';
    }

    if (expiryDate
            .difference(DateTime.now())
            .inDays <=
        30) {
      return 'Due Soon';
    }

    return 'Valid';
  }

  int daysRemaining(
    DateTime expiryDate,
  ) {
    return expiryDate
        .difference(DateTime.now())
        .inDays;
  }

  Future<List<FleetDocument>> expiringSoon() async {
    final documents = await getAll();

    return documents.where((document) {
      return document.isDueSoon;
    }).toList();
  }

  Future<List<FleetDocument>> expired() async {
    final documents = await getAll();

    return documents.where((document) {
      return document.isExpired;
    }).toList();
  }
}