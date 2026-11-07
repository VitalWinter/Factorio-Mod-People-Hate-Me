$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ModName = "People-Hate-Me"
$ModSource = Join-Path $RepoRoot $ModName
$DevRoot = Join-Path $RepoRoot ".dev"
$DevMods = Join-Path $DevRoot "mods"
$UserData = Join-Path $env:APPDATA "Factorio"

function Get-FactorioExe {
  if ($env:FACTORIO_EXE -and (Test-Path $env:FACTORIO_EXE)) {
    return $env:FACTORIO_EXE
  }
  $candidates = @(
    "D:\SteamLibrary\steamapps\common\Factorio\bin\x64\factorio.exe",
    "C:\Program Files (x86)\Steam\steamapps\common\Factorio\bin\x64\factorio.exe",
    "C:\Program Files\Factorio\bin\x64\factorio.exe"
  )
  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }
  throw "Could not find factorio.exe. Set the FACTORIO_EXE environment variable to its full path."
}

function Assert-FactorioNotRunning {
  if (Get-Process -Name "factorio" -ErrorAction SilentlyContinue) {
    throw "Factorio is already running. Close it first."
  }
}

# Factorio loads a mod from <mods>/<mod name>, so a junction lets it read the repo directly.
function New-ModLink([string]$ModsDir) {
  $link = Join-Path $ModsDir $ModName
  if (Test-Path $link) {
    $item = Get-Item $link -Force
    if ($item.LinkType -eq "Junction" -and (@($item.Target) -contains $ModSource)) {
      return
    }
    throw "$link already exists and is not a link to this repo. Move it out of the mods folder first."
  }
  New-Item -ItemType Junction -Path $link -Target $ModSource | Out-Null
  Write-Host "Linked $link -> $ModSource"
}

function Enable-Mod([string]$ModsDir) {
  $listPath = Join-Path $ModsDir "mod-list.json"
  if (Test-Path $listPath) {
    $list = Get-Content $listPath -Raw | ConvertFrom-Json
  } else {
    $list = [pscustomobject]@{ mods = @([pscustomobject]@{ name = "base"; enabled = $true }) }
  }
  $entry = $list.mods | Where-Object { $_.name -eq $ModName }
  if ($entry) {
    $entry.enabled = $true
  } else {
    $list.mods = @($list.mods) + [pscustomobject]@{ name = $ModName; enabled = $true }
  }
  $list | ConvertTo-Json -Depth 4 | Set-Content -Encoding ascii $listPath
}

# An isolated mods folder with only base + this mod, so tests aren't affected by other mods.
function Initialize-DevMods {
  New-Item -ItemType Directory -Force -Path $DevMods | Out-Null
  New-ModLink $DevMods
  $list = [pscustomobject]@{
    mods = @(
      [pscustomobject]@{ name = "base"; enabled = $true },
      [pscustomobject]@{ name = $ModName; enabled = $true }
    )
  }
  $list | ConvertTo-Json -Depth 4 | Set-Content -Encoding ascii (Join-Path $DevMods "mod-list.json")
}
