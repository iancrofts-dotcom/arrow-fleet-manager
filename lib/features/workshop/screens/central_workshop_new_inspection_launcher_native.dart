import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_repository.dart';
import 'inspection_wizard/central_inspection_wizard_screen.dart';

Future<String?> openCentralWorkshopNewInspection(
  BuildContext context,
  BackendWorkshopRepository repository,
) => Navigator.of(context).push<String?>(
  MaterialPageRoute(
    builder: (_) => CentralInspectionWizardScreen(repository: repository),
  ),
);
