$ErrorActionPreference = 'Stop'

function Replace-DartFunction {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Signature,
        [Parameter(Mandatory=$true)][string]$Replacement
    )

    $start = $Source.IndexOf($Signature)
    if ($start -lt 0) { throw "Could not find Dart function: $Signature" }

    $brace = $Source.IndexOf('{', $start)
    if ($brace -lt 0) { throw "Could not find opening brace: $Signature" }

    $depth = 0
    $end = -1
    for ($i = $brace; $i -lt $Source.Length; $i++) {
        if ($Source[$i] -eq '{') { $depth++ }
        elseif ($Source[$i] -eq '}') {
            $depth--
            if ($depth -eq 0) { $end = $i; break }
        }
    }
    if ($end -lt 0) { throw "Could not find closing brace: $Signature" }

    return $Source.Substring(0, $start) + $Replacement + $Source.Substring($end + 1)
}

$path = 'lib/core/navigation/dashboard_navigation.dart'
if (-not (Test-Path $path)) { throw "Missing $path" }

$src = Get-Content $path -Raw

# 1. Platform-aware central named routes.
$src = Replace-DartFunction -Source $src `
    -Signature 'static Future<void> openWorkshop(BuildContext context) async' `
    -Replacement @"
  static Future<void> openWorkshop(BuildContext context) async {
    await Navigator.pushNamed(context, '/workshop');
  }
"@

$src = Replace-DartFunction -Source $src `
    -Signature 'static Future<void> openCompliance(BuildContext context) async' `
    -Replacement @"
  static Future<void> openCompliance(BuildContext context) async {
    await Navigator.pushNamed(context, '/compliance');
  }
"@

# 2. Remove direct feature imports that these named routes make obsolete.
$src = $src -replace "(?m)^\s*import '../../features/workshop/screens/workshop_dashboard_screen\.dart';\r?\n", ""
$src = $src -replace "(?m)^\s*import '../../features/compliance/screens/compliance_centre_screen\.dart';\r?\n", ""

# 3. Normalize any accidental helper references.
$src = $src -replace '\bopenMaintenance\(context\)', 'openWorkshop(context)'

# 4. Rebuild canOpenRoute as a whole instead of fragile text insertion.
$src = Replace-DartFunction -Source $src `
    -Signature 'static bool canOpenRoute(String? route)' `
    -Replacement @"
  static bool canOpenRoute(String? route) {
    final permissions = PermissionService.instance;

    switch (route) {
      case '/vehicles':
        return permissions.canViewVehicles;
      case '/drivers':
        return permissions.canViewDrivers;
      case '/reports':
        return permissions.canViewReports;
      case '/compliance':
      case '/driver-compliance':
        return permissions.canViewCompliance;
      case '/maintenance':
      case '/workshop':
        return permissions.canAccessWorkshop;
      case '/documents':
        return permissions.canViewVehicles;
      default:
        return false;
    }
  }
"@

# 5. Rebuild openRoute as a whole.
$src = Replace-DartFunction -Source $src `
    -Signature 'static Future<void> openRoute(BuildContext context, String? route) async' `
    -Replacement @"
  static Future<void> openRoute(BuildContext context, String? route) async {
    if (route == null) {
      return;
    }

    switch (route) {
      case '/vehicles':
        return openFleet(context);
      case '/drivers':
        return openDrivers(context);
      case '/maintenance':
      case '/workshop':
        return openWorkshop(context);
      case '/compliance':
      case '/driver-compliance':
        return openCompliance(context);
      case '/reports':
        return openReports(context);
      case '/documents':
        return openDocuments(context);
      default:
        return;
    }
  }
"@

Set-Content -Path $path -Value $src -Encoding UTF8

$kpiPath = 'lib/features/dashboard/sections/dashboard_kpi_section.dart'
if (Test-Path $kpiPath) {
    $kpi = Get-Content $kpiPath -Raw
    $kpi = $kpi -replace '\bDashboardNavigation\.openMaintenance\(context\)', 'DashboardNavigation.openWorkshop(context)'
    Set-Content -Path $kpiPath -Value $kpi -Encoding UTF8
}

Write-Host ''
Write-Host 'Build 17.4.6.7 navigation hotfix v4 applied successfully.'
Write-Host 'Compliance  -> /compliance'
Write-Host 'Workshop    -> /workshop'
Write-Host 'Maintenance -> /workshop'
