import '../models/inspection_item.dart';

final List<InspectionItem> defaultInspectionTemplate = [
  // =========================
  // Exterior
  // =========================

  InspectionItem(
    id: 'ext_lights',
    title: 'Lights',
    category: 'Exterior',
  ),

  InspectionItem(
    id: 'ext_indicators',
    title: 'Indicators',
    category: 'Exterior',
  ),

  InspectionItem(
    id: 'ext_tyres',
    title: 'Tyres',
    category: 'Exterior',
  ),

  InspectionItem(
    id: 'ext_mirrors',
    title: 'Mirrors',
    category: 'Exterior',
  ),

  InspectionItem(
    id: 'ext_windscreen',
    title: 'Windscreen',
    category: 'Exterior',
  ),

  InspectionItem(
    id: 'ext_wipers',
    title: 'Wipers',
    category: 'Exterior',
  ),

  // =========================
  // Safety
  // =========================

  InspectionItem(
    id: 'safe_brakes',
    title: 'Brakes',
    category: 'Safety',
  ),

  InspectionItem(
    id: 'safe_steering',
    title: 'Steering',
    category: 'Safety',
  ),

  InspectionItem(
    id: 'safe_horn',
    title: 'Horn',
    category: 'Safety',
  ),

  InspectionItem(
    id: 'safe_fire_extinguisher',
    title: 'Fire Extinguisher',
    category: 'Safety',
  ),

  InspectionItem(
    id: 'safe_first_aid',
    title: 'First Aid Kit',
    category: 'Safety',
  ),

  // =========================
  // Accessibility
  // =========================

  InspectionItem(
    id: 'access_lift',
    title: 'Wheelchair Lift',
    category: 'Accessibility',
  ),

  InspectionItem(
    id: 'access_restraints',
    title: 'Wheelchair Restraints',
    category: 'Accessibility',
  ),

  InspectionItem(
    id: 'access_emergency_exit',
    title: 'Emergency Exit',
    category: 'Accessibility',
  ),
];