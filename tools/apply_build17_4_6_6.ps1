$ErrorActionPreference = 'Stop'

$dashboard = 'lib/features/dashboard/dashboard_screen.dart'
if (-not (Test-Path $dashboard)) {
    throw "Missing $dashboard"
}

$source = Get-Content $dashboard -Raw
$import = "import 'widgets/dashboard_polish_scope.dart';"

if (-not $source.Contains($import)) {
    $anchor = "import 'widgets/dashboard_hero_header.dart';"
    if (-not $source.Contains($anchor)) {
        throw 'Could not locate Dashboard hero-header import. No changes written.'
    }
    $source = $source.Replace($anchor, "$anchor`r`n$import")
}

$old = @"
    return DashboardRouter.build(
      role: dashboardRole,
      context: dashboardContext,
    );
"@

$new = @"
    return DashboardPolishScope(
      child: DashboardRouter.build(
        role: dashboardRole,
        context: dashboardContext,
      ),
    );
"@

if ($source.Contains($old)) {
    $source = $source.Replace($old, $new)
} elseif (-not $source.Contains('return DashboardPolishScope(')) {
    throw 'Expected current DashboardRouter return block was not found. No partial Dashboard patch was written.'
}

Set-Content -Path $dashboard -Value $source -Encoding UTF8
Write-Host 'Build 17.4.6.6 Dashboard polish applied.'
