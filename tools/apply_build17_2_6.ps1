$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "test\platform\web_compatibility_test.dart"
if (-not (Test-Path $path)) {
    throw "Could not find $path. Run this from the FleetIQ project root."
}

$content = Get-Content -Path $path -Raw

# Remove only the stale direct-router repository expectation, allowing Dart formatting,
# indentation and multiline expect() layout to vary.
$pattern = "(?ms)^\s*expect\(\s*webScreens\s*,\s*contains\(\s*'BackendDriverAssignmentRepository'\s*\)\s*\)\s*;\s*"
$matches = [regex]::Matches($content, $pattern)
if ($matches.Count -ne 1) {
    throw "Expected exactly one stale BackendDriverAssignmentRepository assertion, found $($matches.Count). No files changed."
}

$content = [regex]::Replace($content, $pattern, "", 1)

# Ensure the test actually verifies the delegated Web dashboard boundary.
if ($content -notmatch "CentralDashboardParityService\(\)\.loadSummary") {
    $anchor = "expect\(\s*webScreens\s*,\s*contains\(\s*'CentralDashboardParityService'\s*\)\s*\)\s*;"
    $anchorMatch = [regex]::Match($content, $anchor, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $anchorMatch.Success) {
        throw "CentralDashboardParityService assertion anchor not found. No files changed."
    }
    $insert = @"
$($anchorMatch.Value)
    expect(
      webScreens,
      contains('CentralDashboardParityService().loadSummary'),
    );
    expect(
      webScreens,
      contains('CentralDashboardParityService().getFleetHealth'),
    );
"@
    $content = $content.Substring(0, $anchorMatch.Index) + $insert + $content.Substring($anchorMatch.Index + $anchorMatch.Length)
}

Set-Content -Path $path -Value $content -NoNewline
Write-Host "Build 17.2.6 robust Web compatibility fix applied."
