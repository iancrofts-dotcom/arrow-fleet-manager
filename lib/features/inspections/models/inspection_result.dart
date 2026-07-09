import 'inspection_item.dart';

class InspectionResult {
  final int? id;
  final String inspectionNumber;
  final InspectionItem item;

  const InspectionResult({
    this.id,
    required this.inspectionNumber,
    required this.item,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionNumber': inspectionNumber,
      'itemId': item.id,
      'title': item.title,
      'category': item.category,
      'status': item.status.name,
      'notes': item.notes,
    };
  }

  factory InspectionResult.fromMap(
    Map<String, dynamic> map,
  ) {
    return InspectionResult(
      id: map['id'] as int?,
      inspectionNumber: map['inspectionNumber'] as String,
      item: InspectionItem(
        id: map['itemId'] as String,
        title: map['title'] as String,
        category: map['category'] as String,
        status: InspectionStatus.values.firstWhere(
          (e) => e.name == map['status'],
        ),
        notes: map['notes'] as String? ?? '',
      ),
    );
  }
}