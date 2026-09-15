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

$navPath = 'lib/core/navigation/dashboard_navigation.dart'
if (-not (Test-Path $navPath)) {
    throw "Missing $navPath"
}

$nav = Get-Content $navPath -Raw

# Compliance must go through AppRouter so Web resolves the platform-aware
# central Compliance screen rather than directly constructing a feature screen.
$complianceReplacement = @"
  static Future<void> openCompliance(BuildContext context) async {
    await Navigator.pushNamed(context, '/compliance');
  }
"@

$nav = Replace-DartFunction `
    -Source $nav `
    -Signature 'static Future<void> openCompliance(BuildContext context) async' `
    -Replacement $complianceReplacement

# The direct Compliance screen import is no longer needed.
$nav = $nav -replace "(?m)^\s*import '../../features/compliance/screens/compliance_centre_screen\.dart';\r?\n", ""

# Ensure route availability checks agree with the actual Dashboard destinations.
if (-not $nav.Contains("case '/workshop':")) {
    throw "Expected /workshop route case is missing from openRoute."
}

# Add Workshop/Maintenance permission cases to canOpenRoute if absent.
$canOpenStart = $nav.IndexOf('static bool canOpenRoute')
$openRouteStart = $nav.IndexOf('static Future<void> openRoute', $canOpenStart)
if ($canOpenStart -ge 0 -and $openRouteStart -gt $canOpenStart) {
    $canBlock = $nav.Substring($canOpenStart, $openRouteStart - $canOpenStart)

    if (-not $canBlock.Contains("case '/workshop':")) {
        $needle = @"
      case '/compliance':
        return permissions.canViewCompliance;
"@
        $replacement = @"
      case '/compliance':
        return permissions.canViewCompliance;
      case '/maintenance':
      case '/workshop':
        return permissions.canAccessWorkshop;
"@
        if (-not $canBlock.Contains($needle)) {
            throw "Could not locate canOpenRoute compliance case for safe insertion."
        }
        $nav = $nav.Replace($needle, $replacement)
    }
}

Set-Content -Path $navPath -Value $nav -Encoding UTF8

Write-Host ''
Write-Host 'Build 17.4.6.7 navigation hotfix v3 applied.'
Write-Host 'Compliance  -> protected named /compliance route'
Write-Host 'Workshop    -> protected named /workshop route'
Write-Host 'Maintenance -> Workshop via openWorkshop()'
