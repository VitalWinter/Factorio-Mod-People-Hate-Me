# Links the mod into your normal Factorio mods folder and enables it, so you can play it.
# Edits in the repo show up the next time Factorio starts.
. "$PSScriptRoot\common.ps1"

$modsDir = Join-Path $UserData "mods"
New-ModLink $modsDir
Enable-Mod $modsDir
Write-Host "$ModName is linked and enabled in $modsDir"
