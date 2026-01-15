#!/usr/bin/env pwsh
# Quick script to ensure DLLs are in the right place and run the app

$bundlePath = "build\windows\x64\bundle"
$libPath = Join-Path $bundlePath "lib"

if (Test-Path $libPath) {
    Write-Host "Copying DLLs to bundle root..." -ForegroundColor Yellow
    Copy-Item (Join-Path $libPath "*.dll") -Destination $bundlePath -Force
    Write-Host "DLLs copied successfully." -ForegroundColor Green
}

$exePath = Join-Path $bundlePath "writr.exe"
if (Test-Path $exePath) {
    Write-Host "Launching Writr..." -ForegroundColor Cyan
    & $exePath
} else {
    Write-Host "ERROR: Application not found. Please build first with:" -ForegroundColor Red
    Write-Host "  flutter build windows --release" -ForegroundColor Yellow
}
