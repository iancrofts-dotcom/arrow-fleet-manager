import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import 'central_new_workshop_inspection_screen.dart';

Future<String?> openCentralWorkshopNewInspection(
  BuildContext context,
  BackendWorkshopRepository repository,
) async {
  final created = await Navigator.of(context).push<BackendWorkshopInspection>(
    MaterialPageRoute(
      builder: (_) =>
          CentralNewWorkshopInspectionScreen(repository: repository),
    ),
  );
  return created?.id;
}
