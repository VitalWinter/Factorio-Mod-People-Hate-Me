# Opens a scenario from one of the repo's mods with graphics and sound, to watch it live, and leaves
# the game open. Usage: tools\play.ps1 [scenario], by default the showroom.
param([Parameter(Position = 0)][string]$Scenario = "showroom")

. "$PSScriptRoot\common.ps1"

$owner = Get-ScenarioOwner $Scenario
Assert-FactorioNotRunning
Initialize-DevMods
$exe = Get-FactorioExe

Start-Process -FilePath $exe -ArgumentList @("--mod-directory", "`"$DevMods`"", "--load-scenario", "$owner/$Scenario") | Out-Null
Write-Host "Opening $Scenario. If Steam asks to confirm the launch arguments, click Continue."
