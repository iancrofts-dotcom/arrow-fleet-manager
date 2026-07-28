class Repair {
  final int? id;
  final String repairNumber;
  final String inspectionNumber;
  final String registration;
  final String driver;

  final String defect;
  final String defectNotes;
  final String? photoPath;

  final String mechanic;
  final String priority;
  final String status;

  final DateTime dateRaised;
  final DateTime? dueDate;
  final DateTime? completedDate;

  final String repairNotes;

  const Repair({
    this.id,
    required this.repairNumber,
    required this.inspectionNumber,
    required this.registration,
    required this.driver,
    required this.defect,
    required this.defectNotes,
    this.photoPath,
    required this.mechanic,
    required this.priority,
    required this.status,
    required this.dateRaised,
    this.dueDate,
    this.completedDate,
    required this.repairNotes,
  });

  Repair copyWith({
    int? id,
    String? repairNumber,
    String? inspectionNumber,
    String? registration,
    String? driver,
    String? defect,
    String? defectNotes,
    String? photoPath,
    String? mechanic,
    String? priority,
    String? status,
    DateTime? dateRaised,
    DateTime? dueDate,
    DateTime? completedDate,
    String? repairNotes,
  }) {
    return Repair(
      id: id ?? this.id,
      repairNumber: repairNumber ?? this.repairNumber,
      inspectionNumber:
          inspectionNumber ?? this.inspectionNumber,
      registration:
          registration ?? this.registration,
      driver: driver ?? this.driver,
      defect: defect ?? this.defect,
      defectNotes:
          defectNotes ?? this.defectNotes,
      photoPath: photoPath ?? this.photoPath,
      mechanic: mechanic ?? this.mechanic,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dateRaised: dateRaised ?? this.dateRaised,
      dueDate: dueDate ?? this.dueDate,
      completedDate:
          completedDate ?? this.completedDate,
      repairNotes:
          repairNotes ?? this.repairNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'repairNumber': repairNumber,
      'inspectionNumber': inspectionNumber,
      'registration': registration,
      'driver': driver,
      'defect': defect,
      'defectNotes': defectNotes,
      'photoPath': photoPath,
      'mechanic': mechanic,
      'priority': priority,
      'status': status,
      'dateRaised':
          dateRaised.toIso8601String(),
      'dueDate':
          dueDate?.toIso8601String(),
      'completedDate':
          completedDate?.toIso8601String(),
      'repairNotes': repairNotes,
    };
  }

  factory Repair.fromMap(
    Map<String, dynamic> map,
  ) {
    return Repair(
      id: map['id'] as int?,
      repairNumber:
          map['repairNumber'] as String,
      inspectionNumber:
          map['inspectionNumber'] as String,
      registration:
          map['registration'] as String,
      driver: map['driver'] as String,
      defect: map['defect'] as String,
      defectNotes:
          map['defectNotes'] as String,
      photoPath:
          map['photoPath'] as String?,
      mechanic:
          map['mechanic'] as String,
      priority:
          map['priority'] as String,
      status:
          map['status'] as String,
      dateRaised: DateTime.parse(
        map['dateRaised'] as String,
      ),
      dueDate: map['dueDate'] == null
          ? null
          : DateTime.parse(
              map['dueDate'] as String,
            ),
      completedDate:
          map['completedDate'] == null
              ? null
              : DateTime.parse(
                  map['completedDate']
                      as String,
                ),
      repairNotes:
          map['repairNotes'] as String,
    );
  }
}