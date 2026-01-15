param(
  [ValidateSet('windows', 'macos', 'linux', 'all')]
  [string]$Platforms = 'windows',
  [switch]$PatchFilePicker
)

$ErrorActionPreference = 'Stop'

function Assert-Command([string]$name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Missing required command: $name"
  }
}

Assert-Command 'flutter'

Write-Host "Setting up desktop platforms for Writr..."

$platformList =
  if ($Platforms -eq 'all') { @('windows', 'macos', 'linux') }
  else { @($Platforms) }

foreach ($p in $platformList) {
  Write-Host "Enabling $p desktop..."
  flutter config "--enable-$p-desktop"
}

Write-Host "Getting dependencies..."
flutter pub get

if ($PatchFilePicker) {
  Write-Host "Patching file_picker desktop metadata (workaround)..."
  & (Join-Path $PSScriptRoot 'tools\\patch_file_picker_desktop.ps1') -ProjectRoot $PSScriptRoot
}

$platformArg = if ($Platforms -eq 'all') { 'windows,macos,linux' } else { $Platforms }
Write-Host "Creating platform directories ($platformArg)..."
flutter create --project-name=writr "--platforms=$platformArg" .

Write-Host ""
Write-Host "Desktop setup complete!"
Write-Host ""
Write-Host "Build:"
Write-Host "  flutter build windows"
Write-Host "  flutter build macos"
Write-Host "  flutter build linux"

