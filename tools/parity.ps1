# Checks that the mod only changes how the game looks and sounds. Dumps every prototype with
# --dump-data three times (base game only, with the mod, and with the mod's settings flipped), then
# tools\parity.py strips pictures and sounds from each and compares what's left. Any difference
# not reviewed in tools\parity-allowlist.txt fails the check. Headless; takes about a minute.
# -Reuse compares the dumps from the last run again without starting Factorio.
param([switch]$Reuse)
. "$PSScriptRoot\common.ps1"

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  throw "tools\parity.py needs Python 3 on the PATH."
}

$ParityRoot = Join-Path $DevRoot "parity"
$ParityMods = Join-Path $ParityRoot "mods"
$FlippedName = "People-Hate-Me-Flipped-Settings"
$runs = [ordered]@{
  "base" = @()
  "mod" = @($ModName)
  "mod-flipped-settings" = @($ModName, $FlippedName)
}

# A mod that loads after this one and flips the default of each of its startup settings, so the
# settings' other values are checked too.
function Initialize-FlippedSettingsMod {
  $dir = Join-Path $ParityMods $FlippedName
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $info = [ordered]@{ name = $FlippedName; version = "0.0.1"; title = $FlippedName; author = "parity check"; factorio_version = "2.1"; dependencies = @($ModName) }
  [IO.File]::WriteAllText((Join-Path $dir "info.json"), ($info | ConvertTo-Json))
  $lua = @"
for name, setting in pairs(data.raw["bool-setting"]) do
  if name:find("^people%-hate%-me%-") then
    setting.default_value = not setting.default_value
  end
end
"@
  [IO.File]::WriteAllText((Join-Path $dir "settings-updates.lua"), $lua)
}

function Invoke-Dump([string]$Label, [string[]]$Enabled) {
  $mods = @([pscustomobject]@{ name = "base"; enabled = $true })
  foreach ($name in @($ModName, $FlippedName)) {
    $mods += [pscustomobject]@{ name = $name; enabled = ($Enabled -contains $name) }
  }
  [pscustomobject]@{ mods = $mods } | ConvertTo-Json -Depth 4 | Set-Content -Encoding ascii (Join-Path $ParityMods "mod-list.json")
  Remove-Item (Join-Path $ParityMods "mod-settings.dat") -ErrorAction SilentlyContinue

  $dump = Join-Path $UserData "script-output\data-raw-dump.json"
  Remove-Item $dump -ErrorAction SilentlyContinue
  $log = Join-Path $ParityRoot "$Label.log"
  $arguments = @("--mod-directory", "`"$ParityMods`"", "--dump-data", "--disable-audio")
  Write-Host "Dumping prototypes: $Label"
  $game = Start-Process -FilePath $exe -ArgumentList $arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log
  if ($game.ExitCode -ne 0 -or -not (Test-Path $dump)) {
    throw "Factorio couldn't dump the prototypes for '$Label' (exit code $($game.ExitCode)). See $log"
  }
  Move-Item $dump (Join-Path $ParityRoot "$Label.json") -Force
}

if (-not $Reuse) {
  Assert-FactorioNotRunning
  $exe = Get-FactorioExe
  New-Item -ItemType Directory -Force -Path $ParityMods | Out-Null
  New-ModLink $ParityMods
  Initialize-FlippedSettingsMod
  foreach ($label in $runs.Keys) {
    Invoke-Dump $label $runs[$label]
  }
}

$dumps = @($runs.Keys | ForEach-Object { Join-Path $ParityRoot "$_.json" })
& $python.Source (Join-Path $PSScriptRoot "parity.py") (Join-Path $PSScriptRoot "parity-allowlist.txt") @dumps
$code = $LASTEXITCODE
if ($code -eq 0) {
  Write-Host "Parity check PASSED" -ForegroundColor Green
} else {
  Write-Host "Parity check FAILED" -ForegroundColor Red
}
exit $code
