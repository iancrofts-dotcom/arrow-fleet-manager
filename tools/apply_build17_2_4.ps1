$ErrorActionPreference = 'Stop'
$path = Join-Path (Get-Location) 'test/platform/web_compatibility_test.dart'
if (-not (Test-Path $path)) { throw "Could not find $path. Run this script from the FleetIQ project root." }
$text = Get-Content -Raw -Path $path
$oldName = 'Web Dashboard assignment metrics use only central gateways'
$newName = 'Web Dashboard delegates central metrics through the parity service'
$oldExpectation = "expect(source, contains('SupabaseDriverAssignmentGateway'));"
$newExpectation = "expect(source, contains('CentralDashboardParityService'));"
if (-not $text.Contains($oldExpectation)) { throw "Expected legacy gateway assertion was not found; no file was changed." }
$text = $text.Replace($oldName, $newName)
$text = $text.Replace($oldExpectation, $newExpectation)
Set-Content -Path $path -Value $text -NoNewline
Write-Host 'Build 17.2.4 compatibility assertion applied.'
