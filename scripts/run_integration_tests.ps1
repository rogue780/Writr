# PowerShell script to run integration tests
# Usage: .\scripts\run_integration_tests.ps1 [-Platform windows] [-SaveScreenshots] [-SaveLogs]
# Platforms: windows, chrome, android, ios

param(
    [string]$Platform = "windows",
    [switch]$SaveScreenshots,
    [switch]$SaveLogs,
    [string]$TestFile = "integration_test/app_test.dart"
)

# Force UTF-8 output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$ErrorActionPreference = "Continue"  # Don't stop on stderr messages

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Writr Integration Tests Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we're in the project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

Write-Host "Project root: $(Get-Location)" -ForegroundColor Gray
Write-Host "Platform: $Platform" -ForegroundColor Gray
Write-Host "Test file: $TestFile" -ForegroundColor Gray
Write-Host ""

# Create output directory
$OutputDir = "test_output"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
if (-not (Test-Path "$OutputDir/screenshots")) {
    New-Item -ItemType Directory -Path "$OutputDir/screenshots" | Out-Null
}

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = "$OutputDir/test_log_$Timestamp.txt"

Write-Host ""

if ($SaveScreenshots) {
    # Use flutter drive for screenshots
    Write-Host "Running with flutter drive (screenshots enabled)..." -ForegroundColor Green
    Write-Host "Screenshots will be saved to: $OutputDir/screenshots/" -ForegroundColor Gray
    Write-Host ""

    if ($SaveLogs) {
        Write-Host "Logs will be saved to: $LogFile" -ForegroundColor Gray
        Write-Host ""
        # Run and capture output
        $output = & flutter drive --driver=test_driver/integration_test.dart --target=$TestFile -d $Platform 2>&1
        $output | Out-File -FilePath $LogFile -Encoding utf8
        $output | ForEach-Object { Write-Host $_ }
    } else {
        & flutter drive --driver=test_driver/integration_test.dart --target=$TestFile -d $Platform
    }
} else {
    # Use flutter test (faster, no screenshots)
    Write-Host "Running with flutter test..." -ForegroundColor Green
    Write-Host ""

    if ($SaveLogs) {
        Write-Host "Logs will be saved to: $LogFile" -ForegroundColor Gray
        Write-Host ""
        # Run and capture output
        $output = & flutter test $TestFile -d $Platform --reporter expanded 2>&1
        $output | Out-File -FilePath $LogFile -Encoding utf8
        $output | ForEach-Object { Write-Host $_ }
    } else {
        & flutter test $TestFile -d $Platform --reporter expanded
    }
}

$TestResult = $LASTEXITCODE

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($TestResult -eq 0) {
    Write-Host "  Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "  Tests FAILED (exit code: $TestResult)" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output directory: $OutputDir" -ForegroundColor Gray
if ($SaveLogs) {
    Write-Host "Log file: $LogFile" -ForegroundColor Gray
}
if ($SaveScreenshots) {
    Write-Host "Screenshots: $OutputDir/screenshots/" -ForegroundColor Gray
}

exit $TestResult
