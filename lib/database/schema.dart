class DbSchema {
  DbSchema._();

  static const databaseName = 'arrow_fleet.db';
  static const databaseVersion = 11;

  // Tables
  static const inspections = 'inspections';
  static const inspectionResults = 'inspection_results';
  static const vehicles = 'vehicles';
  static const drivers = 'drivers';
  static const driverAssignments = 'driver_assignments';
  static const driverCompliance = 'driver_compliance';
  static const maintenanceRecords = 'maintenance_records';
  static const fleetDocuments = 'fleet_documents';

  // Common columns
  static const id = 'id';
  static const active = 'active';
}