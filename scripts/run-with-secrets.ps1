# run-with-secrets.ps1
# Runs Flutter with cloud API keys from env.json
#
# Usage:
#   .\scripts\run-with-secrets.ps1              # Run debug
#   .\scripts\run-with-secrets.ps1 -Build       # Build release APK
#   .\scripts\run-with-secrets.ps1 -BuildDebug  # Build debug APK

param(
    [switch]$Build,
    [switch]$BuildDebug,
    [string]$Device
)

$ErrorActionPreference = "Stop"

# Find env.json
$envFile = Join-Path $PSScriptRoot "..\env.json"
if (-not (Test-Path $envFile)) {
    Write-Host "ERROR: env.json not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create env.json from the example:" -ForegroundColor Yellow
    Write-Host "  cp env.json.example env.json" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then fill in your API keys." -ForegroundColor Yellow
    exit 1
}

# Load and parse JSON
$env = Get-Content $envFile | ConvertFrom-Json

$dropboxKey = $env.DROPBOX_APP_KEY
$onedriveId = $env.ONEDRIVE_CLIENT_ID

# Validate keys
if ([string]::IsNullOrWhiteSpace($dropboxKey) -or $dropboxKey -eq "your_dropbox_app_key_here") {
    Write-Host "WARNING: DROPBOX_APP_KEY not configured in env.json" -ForegroundColor Yellow
    $dropboxKey = ""
}

if ([string]::IsNullOrWhiteSpace($onedriveId) -or $onedriveId -eq "your_onedrive_client_id_here") {
    Write-Host "WARNING: ONEDRIVE_CLIENT_ID not configured in env.json" -ForegroundColor Yellow
    $onedriveId = ""
}

# Build the dart-define arguments
$dartDefines = @()
if ($dropboxKey) {
    $dartDefines += "--dart-define=DROPBOX_APP_KEY=$dropboxKey"
}
if ($onedriveId) {
    $dartDefines += "--dart-define=ONEDRIVE_CLIENT_ID=$onedriveId"
}

$dartDefineStr = $dartDefines -join " "

# Change to project root
Push-Location (Join-Path $PSScriptRoot "..")

try {
    if ($Build) {
        Write-Host "Building release APK with cloud credentials..." -ForegroundColor Green
        $cmd = "flutter build apk --release $dartDefineStr"
        Write-Host "> $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd

        Write-Host ""
        Write-Host "Release APK built at:" -ForegroundColor Green
        Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
    }
    elseif ($BuildDebug) {
        Write-Host "Building debug APK with cloud credentials..." -ForegroundColor Green
        $cmd = "flutter build apk --debug $dartDefineStr"
        Write-Host "> $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd

        Write-Host ""
        Write-Host "Debug APK built at:" -ForegroundColor Green
        Write-Host "  build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Cyan
    }
    else {
        Write-Host "Running Flutter with cloud credentials..." -ForegroundColor Green
        $deviceArg = if ($Device) { "-d $Device" } else { "" }
        $cmd = "flutter run $deviceArg $dartDefineStr"
        Write-Host "> $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd
    }
}
finally {
    Pop-Location
}
