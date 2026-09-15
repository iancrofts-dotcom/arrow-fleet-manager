
$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "test\platform\web_compatibility_test.dart"

if (-not (Test-Path $path)) {
    throw "Could not find $path. Run this from the FleetIQ project root."
}

$content = Get-Content -Path $path -Raw

$old = @"
    expect(webScreens, contains('CentralDashboardParityService'));
    expect(webScreens, contains('BackendDriverAssignmentRepository'));
"@

$new = @"
    expect(webScreens, contains('CentralDashboardParityService'));
    expect(
      webScreens,
      contains('CentralDashboardParityService().loadSummary'),
    );
    expect(
      webScreens,
      contains('CentralDashboardParityService().getFleetHealth'),
    );
"@

if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
} elseif ($content.Contains("expect(webScreens, contains('BackendDriverAssignmentRepository'));")) {
    $content = $content.Replace(
        "    expect(webScreens, contains('BackendDriverAssignmentRepository'));",
        @"
    expect(
      webScreens,
      contains('CentralDashboardParityService().loadSummary'),
    );
    expect(
      webScreens,
      contains('CentralDashboardParityService().getFleetHealth'),
    );
"@
    )
} else {
    throw "Expected stale BackendDriverAssignmentRepository assertion was not found. No files changed."
}

Set-Content -Path $path -Value $content -NoNewline
Write-Host "Build 17.2.5 final Web compatibility assertion fix applied."
