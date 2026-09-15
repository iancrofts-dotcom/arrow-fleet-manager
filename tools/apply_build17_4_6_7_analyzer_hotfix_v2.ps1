$ErrorActionPreference = 'Stop'

$navPath = 'lib/core/navigation/dashboard_navigation.dart'
$kpiPath = 'lib/features/dashboard/sections/dashboard_kpi_section.dart'

if (-not (Test-Path $navPath)) {
    throw "Missing $navPath"
}

$nav = Get-Content $navPath -Raw

# Remove obsolete direct Workshop screen import if still present.
$nav = $nav -replace "(?m)^\s*import '../../features/workshop/screens/workshop_dashboard_screen\.dart';\r?\n", ""

# Replace every surviving call to the accidental openMaintenance helper.
$nav = $nav -replace '\bopenMaintenance\(context\)', 'openWorkshop(context)'

# Defensive cleanup: if the accidental helper declaration exists in a partial
# state, rename it consistently rather than leaving a duplicate unresolved symbol.
$nav = $nav -replace 'static Future<void> openMaintenance\(BuildContext context\) async', 'static Future<void> openWorkshop(BuildContext context) async'

Set-Content -Path $navPath -Value $nav -Encoding UTF8

if (Test-Path $kpiPath) {
    $kpi = Get-Content $kpiPath -Raw
    $kpi = $kpi -replace '\bDashboardNavigation\.openMaintenance\(context\)', 'DashboardNavigation.openWorkshop(context)'
    Set-Content -Path $kpiPath -Value $kpi -Encoding UTF8
}

Write-Host ''
Write-Host 'Build 17.4.6.7 analyzer hotfix v2 applied.'
Write-Host 'All surviving openMaintenance(context) references were normalised to openWorkshop(context).'
