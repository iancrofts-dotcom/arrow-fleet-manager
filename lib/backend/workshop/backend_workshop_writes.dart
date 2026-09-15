class BackendWorkshopInspectionCreate {
  const BackendWorkshopInspectionCreate({
    required this.vehicleId,
    required this.inspectionType,
    required this.mileage,
    this.notes = '',
    this.technicianProfileId,
  });
  final String vehicleId;
  final String inspectionType;
  final int mileage;
  final String notes;
  final String? technicianProfileId;
}

class BackendWorkshopInspectionItemWrite {
  const BackendWorkshopInspectionItemWrite({
    this.id,
    required this.inspectionId,
    required this.category,
    required this.title,
    required this.status,
    this.sectionTitle,
    this.notes = '',
    this.responseType = 'passFailNotApplicable',
    this.responseValue,
    this.mandatory = true,
    this.repairRequired = false,
    this.displayOrder = 0,
  });
  final String? id;
  final String inspectionId;
  final String category;
  final String? sectionTitle;
  final String title;
  final String responseType;
  final String? responseValue;
  final String status;
  final bool mandatory;
  final bool repairRequired;
  final String notes;
  final int displayOrder;
}

class BackendWorkshopRepairJobCreate {
  const BackendWorkshopRepairJobCreate({
    required this.inspectionId,
    required this.title,
    this.inspectionItemId,
    this.description = '',
    this.priority = 'medium',
    this.technicianProfileId,
    this.partsRequired = false,
    this.estimatedHours = 0,
    this.estimatedCost = 0,
  });
  final String inspectionId;
  final String? inspectionItemId;
  final String title;
  final String description;
  final String priority;
  final String? technicianProfileId;
  final bool partsRequired;
  final double estimatedHours;
  final double estimatedCost;
}

class BackendWorkshopRepairJobUpdate {
  const BackendWorkshopRepairJobUpdate({
    required this.status,
    required this.partsRequired,
    required this.actualHours,
    required this.actualCost,
    required this.roadworthy,
    this.workNotes = '',
    this.partsNotes = '',
    this.technicianMileage,
  });
  final String status;
  final bool partsRequired;
  final double actualHours;
  final double actualCost;
  final bool roadworthy;
  final String workNotes;
  final String partsNotes;
  final int? technicianMileage;
}

class BackendWorkshopTemplateItemWrite {
  const BackendWorkshopTemplateItemWrite({
    required this.sectionTitle,
    required this.category,
    required this.title,
    this.description = '',
    this.responseType = 'passFailNotApplicable',
    this.mandatory = true,
    this.criticalSafetyItem = false,
    this.autoCreateRepair = true,
    this.repairPriority = 'medium',
    this.roadworthyImpact = 'none',
    this.photoRequiredOnFail = false,
    this.allowNotes = true,
    this.defaultStatus = 'notApplicable',
    required this.displayOrder,
  });
  final String sectionTitle;
  final String category;
  final String title;
  final String description;
  final String responseType;
  final bool mandatory;
  final bool criticalSafetyItem;
  final bool autoCreateRepair;
  final String repairPriority;
  final String roadworthyImpact;
  final bool photoRequiredOnFail;
  final bool allowNotes;
  final String defaultStatus;
  final int displayOrder;
}

class BackendWorkshopTemplateWrite {
  const BackendWorkshopTemplateWrite({
    this.id,
    required this.name,
    this.description = '',
    this.inspectionType,
    this.isActive = true,
    required this.items,
  });
  final String? id;
  final String name;
  final String description;
  final String? inspectionType;
  final bool isActive;
  final List<BackendWorkshopTemplateItemWrite> items;
}

class BackendWorkshopTechnician {
  const BackendWorkshopTechnician({required this.id, required this.username});
  final String id;
  final String username;
  factory BackendWorkshopTechnician.fromJson(Map<String, dynamic> json) =>
      BackendWorkshopTechnician(
        id: json['id'] as String,
        username: json['username'] as String,
      );
}

class BackendWorkshopTemplateInspectionCreate {
  const BackendWorkshopTemplateInspectionCreate({
    required this.vehicleId,
    required this.templateId,
    required this.inspectionType,
    required this.mileage,
    this.notes = '',
    this.technicianProfileId,
  });

  final String vehicleId;
  final String templateId;
  final String inspectionType;
  final int mileage;
  final String notes;
  final String? technicianProfileId;
}
