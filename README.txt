FleetIQ Build 17.4.5.2 - Final Analyzer Hotfix

Scope:
- Replaces only lib/features/compliance/widgets/compliance_centre_content.dart
- Adds braces around the three single-line filter guard statements in _visibleItems.
- No test files changed.
- No routing, Supabase migration, Dashboard, Calendar, Compliance functionality, Workshop, or data-layer architecture changed.

After overlaying into the FleetIQ project root, run:

dart format lib/features/compliance/widgets/compliance_centre_content.dart
flutter analyze
flutter test

Do not push the pending Supabase migration until flutter analyze reports No issues found and flutter test reports all tests passed.
