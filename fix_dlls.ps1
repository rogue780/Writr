#!/usr/bin/env pwsh
# Script to rebuild Flutter Windows app and fix missing DLL issues

$ErrorActionPreference = 'Stop'

Write-Host "=== Flutter Windows DLL Fix Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if flutter is available
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Flutter command not found!" -ForegroundColor Red
    Write-Host "Please ensure Flutter is installed and in your PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Cleaning build artifacts..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Step 3: Building Windows release..." -ForegroundColor Yellow
flutter build windows --release

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Checking for DLL files..." -ForegroundColor Cyan

$bundlePath = "build\windows\x64\bundle"
$requiredDlls = @(
    "flutter_windows.dll",
    "url_launcher_windows_plugin.dll"
)

$allFound = $true
$dllsInRoot = $true
foreach ($dll in $requiredDlls) {
    # Check in bundle root (where they should be)
    $rootDllPath = Join-Path $bundlePath $dll
    $libDllPath = Join-Path $bundlePath "lib\$dll"

    if (Test-Path $rootDllPath) {
        Write-Host "  [OK] $dll (in bundle root)" -ForegroundColor Green
    } elseif (Test-Path $libDllPath) {
        Write-Host "  [WARN] $dll (in lib/ subdirectory - needs to be in root)" -ForegroundColor Yellow
        $dllsInRoot = $false
    } else {
        Write-Host "  [MISSING] $dll" -ForegroundColor Red
        $allFound = $false
    }
}

Write-Host ""
if ($allFound -and $dllsInRoot) {
    Write-Host "SUCCESS: All required DLLs are present in the correct location!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run the application:" -ForegroundColor Cyan
    Write-Host "  $bundlePath\writr.exe" -ForegroundColor White
    Write-Host ""
    Write-Host "Or double-click:" -ForegroundColor Cyan
    $fullPath = Join-Path (Get-Location) "$bundlePath\writr.exe"
    Write-Host "  $fullPath" -ForegroundColor White
} elseif ($allFound -and -not $dllsInRoot) {
    Write-Host "INFO: DLLs found in lib/ subdirectory but need to be in bundle root." -ForegroundColor Yellow
    Write-Host "Copying DLLs to bundle root..." -ForegroundColor Yellow
    foreach ($dll in $requiredDlls) {
        $libDllPath = Join-Path $bundlePath "lib\$dll"
        if (Test-Path $libDllPath) {
            Copy-Item $libDllPath -Destination $bundlePath -Force
            Write-Host "  Copied $dll" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "SUCCESS: DLLs are now in the correct location!" -ForegroundColor Green
    Write-Host "Run: $bundlePath\writr.exe" -ForegroundColor Cyan
} else {
    Write-Host "ERROR: Required DLLs are missing!" -ForegroundColor Red
    Write-Host "The build may have failed. Try running flutter clean and rebuilding." -ForegroundColor Yellow
}