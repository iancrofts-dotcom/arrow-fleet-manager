import '../models/inspection_item.dart';

final List<InspectionItem> defaultInspectionTemplate = [
  // Exterior
  InspectionItem(title: 'Lights', category: 'Exterior'),
  InspectionItem(title: 'Indicators', category: 'Exterior'),
  InspectionItem(title: 'Tyres', category: 'Exterior'),
  InspectionItem(title: 'Mirrors', category: 'Exterior'),
  InspectionItem(title: 'Windscreen', category: 'Exterior'),
  InspectionItem(title: 'Wipers', category: 'Exterior'),

  // Safety
  InspectionItem(title: 'Brakes', category: 'Safety'),
  InspectionItem(title: 'Steering', category: 'Safety'),
  InspectionItem(title: 'Horn', category: 'Safety'),
  InspectionItem(title: 'Fire Extinguisher', category: 'Safety'),
  InspectionItem(title: 'First Aid Kit', category: 'Safety'),

  // Accessibility
  InspectionItem(title: 'Wheelchair Lift', category: 'Accessibility'),
  InspectionItem(title: 'Wheelchair Restraints', category: 'Accessibility'),
  InspectionItem(title: 'Emergency Exit', category: 'Accessibility'),
];