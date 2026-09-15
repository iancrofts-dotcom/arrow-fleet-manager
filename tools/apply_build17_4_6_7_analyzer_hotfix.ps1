$ErrorActionPreference = 'Stop'

$navPath = 'lib/core/navigation/dashboard_navigation.dart'
if (-not (Test-Path $navPath)) {
    throw "Missing $navPath"
}

$nav = Get-Content $navPath -Raw

# openWorkshop now uses AppRouter's named /workshop route, so the direct
# Workshop screen import is intentionally no longer required.
$nav = $nav.Replace(
    "import '../../features/workshop/screens/workshop_dashboard_screen.dart';`r`n",
    ''
)
$nav = $nav.Replace(
    "import '../../features/workshop/screens/workshop_dashboard_screen.dart';`n",
    ''
)

# Build 17.4.6.7 routed the legacy /maintenance Dashboard route through a
# helper that was not present in the resulting source. Maintenance belongs to
# the secured Workshop workflow, so route it through the already-defined
# openWorkshop() method instead of adding another alias.
$nav = $nav.Replace(
    "case '/maintenance':`r`n      return openMaintenance(context);",
    "case '/maintenance':`r`n      return openWorkshop(context);"
)
$nav = $nav.Replace(
    "case '/maintenance':`n      return openMaintenance(context);",
    "case '/maintenance':`n      return openWorkshop(context);"
)

# Also normalize any KPI callback produced by the first 17.4.6.7 installer.
$kpiPath = 'lib/features/dashboard/sections/dashboard_kpi_section.dart'
if (Test-Path $kpiPath) {
    $kpi = Get-Content $kpiPath -Raw
    $kpi = $kpi.Replace(
        'DashboardNavigation.openMaintenance(context)',
        'DashboardNavigation.openWorkshop(context)'
    )
    Set-Content -Path $kpiPath -Value $kpi -Encoding UTF8
}

Set-Content -Path $navPath -Value $nav -Encoding UTF8

Write-Host ''
Write-Host 'Build 17.4.6.7 analyzer hotfix applied.'
Write-Host 'Maintenance now routes through the existing secured Workshop destination.'
