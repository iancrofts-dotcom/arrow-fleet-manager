import '../models/inspection_checklist_item.dart';

class ChecklistTemplateService {
  List<InspectionChecklistItem> getDefaultTemplate() {
    return [
      // Vehicle Information
      _item(
        category: 'Vehicle Information',
        title: 'Registration Plate',
      ),
      _item(
        category: 'Vehicle Information',
        title: 'Mileage Recorded',
      ),

      // Engine
      _item(
        category: 'Engine',
        title: 'Engine Oil Level',
      ),
      _item(
        category: 'Engine',
        title: 'Coolant Level',
      ),
      _item(
        category: 'Engine',
        title: 'Leaks',
      ),

      // Brakes
     _item(
  category: 'Brakes',
  title: 'Brake Pads',
  priority: ChecklistPriority.critical,
),
      _item(
  category: 'Brakes',
  title: 'Brake Discs',
  priority: ChecklistPriority.critical,
),
      _item(
        category: 'Brakes',
        title: 'Brake Fluid',
      ),

      // Tyres
_item(
  category: 'Tyres',
  title: 'Front Tyres',
  priority: ChecklistPriority.critical,
),
_item(
  category: 'Tyres',
  title: 'Rear Tyres',
  priority: ChecklistPriority.critical,
),

      // Lights
_item(
  category: 'Lights',
  title: 'Headlights',
  priority: ChecklistPriority.high,
),
      _item(
        category: 'Lights',
        title: 'Indicators',
      ),
      _item(
        category: 'Lights',
        title: 'Brake Lights',
      ),

      // Safety
      _item(
        category: 'Safety',
        title: 'Fire Extinguisher',
      ),
      _item(
        category: 'Safety',
        title: 'First Aid Kit',
      ),
      _item(
        category: 'Safety',
        title: 'Emergency Exit',
      ),
    ];
  }

 InspectionChecklistItem _item({
  required String category,
  required String title,
  bool mandatory = true,
  ChecklistPriority priority = ChecklistPriority.medium,
}) {
    return InspectionChecklistItem(
  id: '${category}_$title',
  category: category,
  title: title,
  mandatory: mandatory,
  priority: priority,
);
  }
}