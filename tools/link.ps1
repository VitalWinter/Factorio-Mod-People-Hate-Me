# Links the mod and its sketches into your normal Factorio mods folder and enables them, so you
# can play the mod and find the showroom and sketches under Mod scenarios. The sketches only add
# hidden copies, so they don't change the game. Edits in the repo show up the next time Factorio
# starts.
. "$PSScriptRoot\common.ps1"

$modsDir = Join-Path $UserData "mods"
foreach ($name in $ModName, $SketchModName) {
  New-ModLink $modsDir $name
  Enable-Mod $modsDir $name
  Write-Host "$name is linked and enabled in $modsDir"
}
