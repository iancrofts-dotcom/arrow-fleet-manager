$ErrorActionPreference = 'Stop'

$web = 'lib/features/vehicles/screens/vehicle_details_web_screen.dart'
$native = 'lib/features/vehicles/screens/vehicle_details_screen.dart'

if (-not (Test-Path $web)) {
    throw "Missing $web"
}

$webSource = Get-Content $web -Raw

$docImport = "import '../../documents/screens/central_document_list_screen.dart';"
$historyImport = "import 'central_vehicle_history_screen.dart';"

if (-not $webSource.Contains($docImport)) {
    $anchor = "import 'package:flutter/material.dart';"
    if (-not $webSource.Contains($anchor)) {
        throw 'Could not locate Web import anchor.'
    }
    $webSource = $webSource.Replace(
        $anchor,
        "$anchor`r`n`r`n$docImport"
    )
}

if (-not $webSource.Contains($historyImport)) {
    $anchor = "import 'edit_vehicle_screen.dart';"
    if (-not $webSource.Contains($anchor)) {
        throw 'Could not locate edit_vehicle_screen.dart import.'
    }
    $webSource = $webSource.Replace(
        $anchor,
        "$historyImport`r`n$anchor"
    )
}

$stale = @"
          const Text(
            'Documents, maintenance and workshop history are still being migrated to the central backend.',
          ),
"@

$replacement = @"
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('Vehicle Documents'),
                  subtitle: const Text(
                    'View and manage central documents linked to this Vehicle.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CentralDocumentListScreen(
                        initialFilter: 'Vehicle',
                        entityType: 'vehicle',
                        entityId: centralId,
                        ownerLabel: _vehicle.registration,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Maintenance & Workshop History'),
                  subtitle: const Text(
                    'View central inspections, scheduled-service activity and repair jobs.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CentralVehicleHistoryScreen(
                        vehicleId: centralId,
                        registration: _vehicle.registration,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
"@

if ($webSource.Contains($stale)) {
    $webSource = $webSource.Replace($stale, $replacement)
} elseif (-not $webSource.Contains('CentralVehicleHistoryScreen(')) {
    throw 'The expected stale Web related-records block was not found. No partial Web patch was written.'
}

Set-Content -Path $web -Value $webSource -Encoding UTF8

# Native/Android/Windows central Vehicle Details already has the central Documents
# route in current FleetIQ builds. Add the same history entry when the known
# related-records marker is present, but do not fail the build if that screen has
# legitimately evolved.
if (Test-Path $native) {
    $nativeSource = Get-Content $native -Raw

    if (-not $nativeSource.Contains($historyImport)) {
        $anchor = "import 'edit_vehicle_screen.dart';"
        if ($nativeSource.Contains($anchor)) {
            $nativeSource = $nativeSource.Replace(
                $anchor,
                "$historyImport`r`n$anchor"
            )
        }
    }

    $marker = @"
                  const Divider(),
                  const Text(
                    'Central Driver assignment and history are managed above. Workshop '
                    'history continues to use the central Workshop records.',
                  ),
"@

    $nativeHistory = @"
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Maintenance & Workshop History'),
                    subtitle: const Text(
                      'View central inspections, scheduled-service activity and repair jobs.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => CentralVehicleHistoryScreen(
                          vehicleId: _vehicle.identity!.centralIdOrNull!,
                          registration: _vehicle.registration,
                        ),
                      ),
                    ),
                  ),
"@

    if ($nativeSource.Contains($marker)) {
        $nativeSource = $nativeSource.Replace($marker, $nativeHistory)
        Set-Content -Path $native -Value $nativeSource -Encoding UTF8
    }
}

Write-Host 'Build 17.4.6.5 Vehicle Related Records patch applied.'
