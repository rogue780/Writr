param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Get-FilePickerVersionFromLock([string]$lockPath) {
  $lines = Get-Content $lockPath

  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s{2}file_picker:\s*$') {
      for ($j = $i; $j -lt [Math]::Min($i + 80, $lines.Count); $j++) {
        if ($lines[$j] -match '^\s{4}version:\s+"([^"]+)"\s*$') {
          return $Matches[1]
        }
      }
    }
  }

  return $null
}

function Remove-DesktopDefaultPackageSelf([string]$pubspecPath) {
  $lines = Get-Content $pubspecPath
  $output = New-Object System.Collections.Generic.List[string]

  $skipIndent = $null
  foreach ($line in $lines) {
    if ($null -ne $skipIndent) {
      $indent = ($line -replace '^(\\s*).*$', '$1').Length
      if ($indent -le $skipIndent) {
        $skipIndent = $null
      } else {
        continue
      }
    }

    if ($line -match '^\s{6}(macos|windows|linux):\s*$') {
      $skipIndent = 6
      continue
    }

    $output.Add($line)
  }

  if ($output.Count -eq $lines.Count) {
    Write-Host "No desktop default_package entries found in $pubspecPath"
    return $false
  }

  Copy-Item $pubspecPath "$pubspecPath.bak" -Force
  Set-Content -Path $pubspecPath -Value $output -Encoding UTF8
  Write-Host "Patched: $pubspecPath (backup: $pubspecPath.bak)"
  return $true
}

$lockPath = Join-Path $ProjectRoot 'pubspec.lock'
if (!(Test-Path $lockPath)) {
  throw "Missing pubspec.lock at $lockPath. Run 'flutter pub get' first."
}

$version = Get-FilePickerVersionFromLock $lockPath
if ([string]::IsNullOrWhiteSpace($version)) {
  throw "Could not determine file_picker version from $lockPath"
}

$pubspecPath = Join-Path $env:LOCALAPPDATA "Pub\\Cache\\hosted\\pub.dev\\file_picker-$version\\pubspec.yaml"
if (!(Test-Path $pubspecPath)) {
  throw "file_picker pubspec not found at $pubspecPath. Ensure dependencies are downloaded."
}

Remove-DesktopDefaultPackageSelf $pubspecPath | Out-Null

