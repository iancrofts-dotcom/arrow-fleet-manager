param(
  [Parameter(Mandatory=$true)]
  [string]$AnonKey
)

$ErrorActionPreference = 'Stop'

flutter clean
flutter pub get
flutter build web --release --base-href /app/ --pwa-strategy=none `
  --dart-define=FLEETIQ_BACKEND_MODE=supabase `
  --dart-define=FLEETIQ_SUPABASE_URL=https://qrfhalgtwitwilgqlbkw.supabase.co `
  --dart-define=FLEETIQ_SUPABASE_ANON_KEY=$AnonKey

$bundle = Get-Content -Raw 'build/web/main.dart.js'
$forbidden = @('Central fleet overview', 'Central migration status')
foreach ($text in $forbidden) {
  if ($bundle.Contains($text)) {
    throw "Build 17.3 verification failed: generated main.dart.js still contains legacy dashboard text: $text"
  }
}

Write-Host 'Build 17.3 Web verification passed: legacy Admin dashboard text is absent.' -ForegroundColor Green
Write-Host 'Upload the CONTENTS of build/web to the emptied hosted /app/ directory.'
