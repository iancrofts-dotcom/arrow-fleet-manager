class CentralEmergencyOperationCatalog {
  CentralEmergencyOperationCatalog._();

  static const vehicleInsert = 'vehicle.insert';
  static const vehicleUpdate = 'vehicle.update';
  static const driverInsert = 'driver.insert';
  static const driverUpdate = 'driver.update';
  static const driverComplianceSave = 'driver.compliance.save';
  static const assignmentInsert = 'assignment.insert';
  static const assignmentUpdate = 'assignment.update';
  static const workshopCreateInspection = 'workshop.inspection.create';
  static const workshopCreateInspectionFromTemplate =
      'workshop.inspection.create_from_template';
  static const workshopSaveInspectionItem = 'workshop.inspection_item.save';
  static const workshopCreateRepairJob = 'workshop.repair_job.create';
  static const workshopUpdateRepairJob = 'workshop.repair_job.update';
  static const workshopSignOffRepairJob = 'workshop.repair_job.sign_off';
  static const workshopAssignInspectionTechnician =
      'workshop.inspection.assign_technician';
  static const workshopAssignRepairTechnician =
      'workshop.repair_job.assign_technician';
  static const workshopCompleteInspection = 'workshop.inspection.complete';
  static const workshopSignOffInspection = 'workshop.inspection.sign_off';
  static const documentRegister = 'document.register';
  static const documentArchive = 'document.archive';
}
