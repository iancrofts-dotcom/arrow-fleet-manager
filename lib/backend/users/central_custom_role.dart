class CentralCustomRole {
  const CentralCustomRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final Set<String> permissions;
  final bool isActive;

  factory CentralCustomRole.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    final permissions = rawPermissions is List
        ? rawPermissions.whereType<String>().toSet()
        : <String>{};
    return CentralCustomRole(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      permissions: permissions,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

abstract final class FleetPermissionKey {
  static const viewVehicles = 'view_vehicles';
  static const manageVehicles = 'manage_vehicles';
  static const viewDrivers = 'view_drivers';
  static const manageDrivers = 'manage_drivers';
  static const viewCompliance = 'view_compliance';
  static const manageCompliance = 'manage_compliance';
  static const accessCalendar = 'access_calendar';
  static const accessWorkshop = 'access_workshop';
  static const operateWorkshop = 'operate_workshop';
  static const manageWorkshop = 'manage_workshop';
  static const signOffInspection = 'signoff_inspection';
  static const manageInspectionTemplates = 'manage_inspection_templates';
  static const viewReports = 'view_reports';
  static const viewDocuments = 'view_documents';
  static const manageDocuments = 'manage_documents';
  static const viewKpis = 'view_kpis';

  static const selectable = <String, String>{
    viewVehicles: 'View fleet vehicles',
    manageVehicles: 'Add and edit vehicles',
    viewDrivers: 'View drivers',
    manageDrivers: 'Add and edit drivers',
    viewCompliance: 'View compliance',
    manageCompliance: 'Manage compliance records',
    accessCalendar: 'Access calendar',
    accessWorkshop: 'Access Workshop',
    operateWorkshop: 'Work on Workshop jobs',
    manageWorkshop: 'Manage Workshop',
    signOffInspection: 'Sign off inspections',
    manageInspectionTemplates: 'Manage inspection templates',
    viewReports: 'View and export reports',
    viewDocuments: 'View documents and evidence',
    manageDocuments: 'Manage documents and evidence',
    viewKpis: 'View management KPIs',
  };
}
