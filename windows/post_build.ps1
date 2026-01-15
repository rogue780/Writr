#!/usr/bin/env pwsh
# Post-build script to copy DLLs to the same directory as the .exe
# This script is automatically executed by Flutter after each build

param(
    [Parameter(Mandatory=$true)]
    [string]$BuildMode,

    [Parameter(Mandatory=$true)]
    [string]$TargetPlatform
)

$ErrorActionPreference = 'Continue'

Write-Host "Post-build: Copying DLLs (BuildMode: $BuildMode, Platform: $TargetPlatform)..." -ForegroundColor Cyan

# Determine the build configuration directory
$config = if ($BuildMode -eq "debug") { "Debug" } else { "Release" }

# For debug builds, DLLs and .exe are in runner\Debug or runner\Release
# For release builds, they should also be copied to the bundle directory
$runnerPath = "build\windows\x64\runner\$config"

# Function to copy DLLs from lib subdirectory to the same directory as the exe
function Copy-DllsToExeDir {
    param([string]$targetDir)

    $libPath = Join-Path $targetDir "lib"

    if (-not (Test-Path $libPath)) {
        Write-Host "  No lib directory at $libPath" -ForegroundColor Yellow
        return 0
    }

    $dllFiles = Get-ChildItem -Path $libPath -Filter "*.dll" -ErrorAction SilentlyContinue

    if ($dllFiles.Count -eq 0) {
        Write-Host "  No DLL files found in $libPath" -ForegroundColor Yellow
        return 0
    }

    $copiedCount = 0
    foreach ($dll in $dllFiles) {
        $destPath = Join-Path $targetDir $dll.Name
        try {
            Copy-Item $dll.FullName -Destination $destPath -Force
            Write-Host "  Copied $($dll.Name) to $targetDir" -ForegroundColor Green
            $copiedCount++
        } catch {
            Write-Host "  Failed to copy $($dll.Name): $_" -ForegroundColor Red
        }
    }

    return $copiedCount
}

# Copy DLLs to runner directory (where .exe is for debug/release builds)
$count = Copy-DllsToExeDir -targetDir $runnerPath
Write-Host "Copied $count DLL(s) to runner directory" -ForegroundColor Cyan

# For release builds, also copy to bundle directory
if ($BuildMode -ne "debug") {
    $bundlePath = "build\windows\x64\bundle"
    if (Test-Path $bundlePath) {
        $bundleCount = Copy-DllsToExeDir -targetDir $bundlePath
        Write-Host "Copied $bundleCount DLL(s) to bundle directory" -ForegroundColor Cyan
    }
}

Write-Host "Post-build complete!" -ForegroundColor Green
exit 0
