$ErrorActionPreference = 'Stop'

function Replace-DartFunction {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Signature,
        [Parameter(Mandatory=$true)][string]$Replacement
    )

    $start = $Source.IndexOf($Signature)
    if ($start -lt 0) {
        throw "Could not find Dart function signature: $Signature"
    }

    $brace = $Source.IndexOf('{', $start)
    if ($brace -lt 0) {
        throw "Could not find opening brace for: $Signature"
    }

    $depth = 0
    $end = -1
    for ($i = $brace; $i -lt $Source.Length; $i++) {
        $ch = $Source[$i]
        if ($ch -eq '{') {
            $depth++
        } elseif ($ch -eq '}') {
            $depth--
            if ($depth -eq 0) {
                $end = $i
                break
            }
        }
    }

    if ($end -lt 0) {
        throw "Could not find closing brace for: $Signature"
    }

    return $Source.Substring(0, $start) +
        $Replacement +
        $Source.Substring($end + 1)
}

# ---------------------------------------------------------------------------
# 1. Fix the central Dashboard navigation boundary.
# ---------------------------------------------------------------------------
$navPath = 'lib/core/navigation/dashboard_navigation.dart'
if (-not (Test-Path $navPath)) {
    throw "Missing $navPath"
}

$nav = Get-Content $navPath -Raw

$workshopReplacement = @"
  static Future<void> openWorkshop(BuildContext context) async {
    await Navigator.pushNamed(context, '/workshop');
  }
"@

$nav = Replace-DartFunction `
    -Source $nav `
    -Signature 'static Future<void> openWorkshop(BuildContext context) async' `
    -Replacement $workshopReplacement

if (-not $nav.Contains('static Future<void> openCompliance(BuildContext context) async')) {
    $anchor = 'static Future<void> openRoute'
    $pos = $nav.IndexOf($anchor)
    if ($pos -lt 0) {
        throw 'Could not locate openRoute insertion point.'
    }

    $methods = @"

  static Future<void> openCompliance(BuildContext context) async {
    await Navigator.pushNamed(context, '/compliance');
  }

  /// Maintenance operations are owned by the secured Workshop workflow.
  /// Do not use the legacy /maintenance placeholder route.
  static Future<void> openMaintenance(BuildContext context) async {
    await Navigator.pushNamed(context, '/workshop');
  }

"@

    $nav = $nav.Substring(0, $pos) + $methods + $nav.Substring($pos)
}

$routeReplacement = @"
static Future<void> openRoute(
  BuildContext context,
  String? route,
) async {
  if (route == null) {
    return;
  }

  switch (route) {
    case '/vehicles':
      return openFleet(context);
    case '/drivers':
      return openDrivers(context);
    case '/maintenance':
      return openMaintenance(context);
    case '/workshop':
      return openWorkshop(context);
    case '/compliance':
    case '/driver-compliance':
      return openCompliance(context);
    case '/reports':
      return openReports(context);
    default:
      // Preserve legitimate named routes owned by AppRouter rather than
      // silently sending the user to a stale local screen.
      await Navigator.pushNamed(context, route);
  }
}
"@

$nav = Replace-DartFunction `
    -Source $nav `
    -Signature 'static Future<void> openRoute' `
    -Replacement $routeReplacement

Set-Content -Path $navPath -Value $nav -Encoding UTF8

# ---------------------------------------------------------------------------
# 2. Make the four-primary-KPI Compliance card actionable.
#    Existing Fleet/Drivers/Maintenance behavior is preserved except that
#    Maintenance is normalised to the secured Workshop destination.
# ---------------------------------------------------------------------------
$kpiPath = 'lib/features/dashboard/sections/dashboard_kpi_section.dart'
if (-not (Test-Path $kpiPath)) {
    throw "Missing $kpiPath"
}

$kpi = Get-Content $kpiPath -Raw

# Ensure DashboardNavigation is available when the modern section uses it.
$navImport = "import '../../../core/navigation/dashboard_navigation.dart';"
if (-not $kpi.Contains($navImport)) {
    $materialImport = "import 'package:flutter/material.dart';"
    if (-not $kpi.Contains($materialImport)) {
        throw 'Could not locate Dashboard KPI import anchor.'
    }
    $kpi = $kpi.Replace(
        $materialImport,
        "$materialImport`r`n`r`n$navImport"
    )
}

# Current Dashboard V2 deliberately left Compliance as the only primary KPI
# with onTap: null. Replace that deliberate release boundary.
if ($kpi.Contains('onTap: null,')) {
    $index = $kpi.IndexOf('onTap: null,')
    $kpi = $kpi.Remove($index, 'onTap: null,'.Length).Insert(
        $index,
        'onTap: () => DashboardNavigation.openCompliance(context),'
    )
} elseif (
    -not $kpi.Contains('DashboardNavigation.openCompliance(context)') -and
    -not $kpi.Contains("Navigator.pushNamed(context, '/compliance')")
) {
    throw 'Compliance KPI callback was not recognised. No unsafe guess was applied.'
}

# Normalise any primary Maintenance callback that still opens a Service-Due
# vehicle filter instead of the Workshop operational workflow.
$kpi = $kpi.Replace(
    'DashboardNavigation.openServiceDue(context)',
    'DashboardNavigation.openMaintenance(context)'
)

# If the current build already used openWorkshop, leave it intact; openWorkshop
# itself is now corrected above.
if (
    -not $kpi.Contains('DashboardNavigation.openMaintenance(context)') -and
    -not $kpi.Contains('DashboardNavigation.openWorkshop(context)') -and
    -not $kpi.Contains("Navigator.pushNamed(context, '/workshop')")
) {
    throw 'Maintenance KPI Workshop callback was not found. Patch stopped for review.'
}

Set-Content -Path $kpiPath -Value $kpi -Encoding UTF8

Write-Host ''
Write-Host 'Build 17.4.6.7 Dashboard navigation fix applied.'
Write-Host 'Compliance -> /compliance'
Write-Host 'Workshop   -> /workshop'
Write-Host 'Maintenance-> /workshop'
