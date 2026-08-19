import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';
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

  Future<FleetDocument?> getCurrentComplianceDocument(
    int driverId,
    DocumentCategory category,
  ) {
    _assertCanViewDriver(driverId);
    return _repository.getCurrentComplianceDocument(driverId, category);
  }

  Future<List<FleetDocument>> getComplianceDocumentHistory(
    int driverId,
    DocumentCategory category,
  ) {
    _assertCanViewDriver(driverId);
    return _repository.getComplianceDocumentHistory(driverId, category);
  }

  Future<List<FleetDocument>> getCurrentComplianceDocuments(int driverId) {
    _assertCanViewDriver(driverId);
    return _repository.getCurrentComplianceDocuments(driverId);
  }

  Future<int> uploadComplianceEvidence({
    required int driverId,
    required DocumentCategory category,
    required File sourceFile,
    required String title,
    required DateTime? expirySnapshot,
    String? notes,
  }) async {
    _assertCanManageDriver(driverId);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Selected document file could not be found.', sourceFile.path);
    }
    final storedPath = await _storeUniqueFile(
      sourceFile: sourceFile,
      driverId: driverId,
      category: category,
    );
    final now = DateTime.now();
    final document = FleetDocument(
      title: title.trim().isEmpty ? _defaultTitle(category) : title.trim(),
      category: category,
      filePath: storedPath,
      issueDate: now,
      expiryDate: expirySnapshot,
      lastUpdated: now,
      notes: notes?.trim(),
      driverId: driverId,
      uploadedByUserId: AuthService.instance.currentUserId,
      originalFileName: path.basename(sourceFile.path),
    );
    if (category.isSingleCurrentComplianceCategory) {
      return _repository.replaceCurrentComplianceDocument(document);
    }
    return _repository.insert(document);
  }

  void _assertCanViewDriver(int driverId) {
    final permissions = PermissionService.instance;
    if (permissions.canViewDriverComplianceDocuments) return;
    if (permissions.canViewOwnComplianceDocuments &&
        AuthService.instance.currentDriverId == driverId) {
      return;
    }
    throw StateError('You do not have permission to view these compliance documents.');
  }

  void _assertCanManageDriver(int driverId) {
    final permissions = PermissionService.instance;
    if (permissions.canManageDriverComplianceDocuments) return;
    if (permissions.canViewOwnComplianceDocuments &&
        AuthService.instance.currentDriverId == driverId) {
      return;
    }
    throw StateError('You do not have permission to manage these compliance documents.');
  }

  Future<String> _storeUniqueFile({
    required File sourceFile,
    required int driverId,
    required DocumentCategory category,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetDirectory = Directory(path.join(directory.path, 'fleet_documents'));
    await targetDirectory.create(recursive: true);
    final extension = path.extension(sourceFile.path).toLowerCase();
    final token = Random.secure().nextInt(1 << 32).toRadixString(16);
    final name = '${driverId}_${category.name}_${DateTime.now().microsecondsSinceEpoch}_$token$extension';
    final destination = File(path.join(targetDirectory.path, name));
    await sourceFile.copy(destination.path);
    return destination.path;
  }

  String _defaultTitle(DocumentCategory category) => switch (category) {
        DocumentCategory.licence => 'Driving Licence Evidence',
        DocumentCategory.cpc => 'CPC Evidence',
        DocumentCategory.medical => 'Medical Evidence',
        DocumentCategory.dbs => 'DBS Evidence',
        DocumentCategory.tachographCard => 'Tachograph Card Evidence',
        _ => 'Compliance Evidence',
      };

  String status(
    DateTime? expiryDate,
  ) {
    if (expiryDate == null) return 'Not Recorded';
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
    DateTime? expiryDate,
  ) {
    if (expiryDate == null) return 0;
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

extension ComplianceDocumentCategory on DocumentCategory {
  bool get isSingleCurrentComplianceCategory =>
      this == DocumentCategory.licence ||
      this == DocumentCategory.cpc ||
      this == DocumentCategory.medical ||
      this == DocumentCategory.dbs ||
      this == DocumentCategory.tachographCard;
}
