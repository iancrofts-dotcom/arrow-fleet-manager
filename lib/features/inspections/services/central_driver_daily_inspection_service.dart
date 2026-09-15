import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../backend/backend_client.dart';
import '../../../backend/organisation/central_organisation_service.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/inspection.dart';
import '../models/inspection_item.dart';

class CentralDriverDailyInspectionSaveException implements Exception {
  const CentralDriverDailyInspectionSaveException({
    required this.stage,
    required this.cause,
    this.inspectionId,
  });

  final String stage;
  final Object cause;
  final String? inspectionId;

  String get diagnosticMessage {
    final saved = inspectionId == null
        ? ''
        : ' Inspection #$inspectionId was created.';
    return '$stage failed.$saved ${_describeCause(cause)}';
  }

  @override
  String toString() => diagnosticMessage;

  static String _describeCause(Object error) {
    final text = error.toString().trim();
    return text.isEmpty ? error.runtimeType.toString() : text;
  }
}

class CentralDriverDailyInspectionService {
  const CentralDriverDailyInspectionService();

  Future<int?> latestMileage(Vehicle vehicle) async {
    final vehicleId = vehicle.identity?.centralIdOrNull;
    if (vehicleId == null) return null;
    final rows = await BackendClient.client
        .from('workshop_inspections')
        .select('mileage,date_started')
        .eq('vehicle_id', vehicleId)
        .order('date_started', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final value = rows.first['mileage'];
    return value is num && value > 0 ? value.toInt() : null;
  }

  Future<String> save({
    required Inspection inspection,
    required List<InspectionItem> items,
    required Vehicle vehicle,
  }) async {
    final vehicleId = vehicle.identity?.centralIdOrNull;
    if (vehicleId == null) {
      throw const CentralDriverDailyInspectionSaveException(
        stage: 'Vehicle identity validation',
        cause: 'Driver daily inspection requires a central vehicle.',
      );
    }

    Object? result;
    try {
      result = await BackendClient.client.rpc(
        'workshop_save_driver_daily_inspection',
        params: {
          'p_vehicle_id': vehicleId,
          'p_mileage': inspection.mileage,
          'p_notes': _notes(inspection),
          'p_items': [
            for (var index = 0; index < items.length; index++)
              {
                'category': items[index].category,
                'title': items[index].title,
                'status': _status(items[index].status),
                'repair_required': items[index].hasFailed,
                'notes': items[index].notes,
                'display_order': index,
              },
          ],
        },
      );
    } catch (error) {
      throw CentralDriverDailyInspectionSaveException(
        stage: 'Inspection save RPC',
        cause: error,
      );
    }

    if (result is! String || result.isEmpty) {
      throw CentralDriverDailyInspectionSaveException(
        stage: 'Inspection save response',
        cause: StateError('Central daily inspection did not return an ID.'),
      );
    }

    try {
      await _uploadEvidence(result, items);
    } on CentralDriverDailyInspectionSaveException {
      rethrow;
    } catch (error) {
      throw CentralDriverDailyInspectionSaveException(
        stage: 'Photo evidence processing',
        cause: error,
        inspectionId: result,
      );
    }
    return result;
  }

  Future<void> _uploadEvidence(
    String inspectionId,
    List<InspectionItem> items,
  ) async {
    List<Map<String, dynamic>> rows;
    try {
      final result = await BackendClient.client
          .from('workshop_inspection_items')
          .select('id,title,display_order')
          .eq('inspection_id', inspectionId)
          .order('display_order');
      rows = List<Map<String, dynamic>>.from(result);
    } catch (error) {
      throw CentralDriverDailyInspectionSaveException(
        stage: 'Saved checklist lookup',
        cause: error,
        inspectionId: inspectionId,
      );
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final bytes = item.photoBytes;
      if (bytes == null || bytes.isEmpty) continue;

      Map<String, dynamic>? row;
      for (final candidate in rows) {
        if (candidate['display_order'] == index &&
            candidate['title'] == item.title) {
          row = candidate;
          break;
        }
      }
      if (row == null) {
        throw CentralDriverDailyInspectionSaveException(
          stage: 'Photo checklist matching',
          cause: StateError(
            'Saved checklist item could not be matched for "${item.title}".',
          ),
          inspectionId: inspectionId,
        );
      }

      await _uploadOne(
        inspectionId: inspectionId,
        inspectionItemId: row['id'] as String,
        fileName: item.photoFileName ?? 'inspection-photo.jpg',
        bytes: bytes,
        contentType: item.photoContentType ?? 'image/jpeg',
        caption: item.notes,
      );
    }
  }

  Future<void> _uploadOne({
    required String inspectionId,
    required String inspectionItemId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    required String caption,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final organisationId = await CentralOrganisationService.instance
        .currentOrganisationId();
    final storagePath =
        '$organisationId/workshop/$inspectionId/$inspectionItemId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final storage = BackendClient.client.storage.from('fleet-documents');

    try {
      await storage.uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
    } catch (error) {
      throw CentralDriverDailyInspectionSaveException(
        stage: 'Photo storage upload',
        cause: error,
        inspectionId: inspectionId,
      );
    }

    try {
      await BackendClient.client.rpc(
        'workshop_register_evidence',
        params: {
          'p_inspection_id': inspectionId,
          'p_inspection_item_id': inspectionItemId,
          'p_file_name': fileName,
          'p_storage_path': storagePath,
          'p_content_type': contentType,
          'p_size_bytes': bytes.length,
          'p_caption': caption,
        },
      );
    } catch (error) {
      try {
        await storage.remove([storagePath]);
      } catch (_) {
        // Keep the original evidence registration error as the diagnostic cause.
      }
      throw CentralDriverDailyInspectionSaveException(
        stage: 'Photo evidence registration',
        cause: error,
        inspectionId: inspectionId,
      );
    }
  }

  String _status(InspectionStatus status) => switch (status) {
    InspectionStatus.pass => 'pass',
    InspectionStatus.fail => 'fail',
    InspectionStatus.notApplicable => 'notApplicable',
  };

  String _notes(Inspection inspection) {
    final notes = <String>['Fuel level: ${inspection.fuelLevel}'];
    final comments = inspection.comments.trim();
    if (comments.isNotEmpty) notes.add(comments);
    return notes.join('\n\n');
  }
}
