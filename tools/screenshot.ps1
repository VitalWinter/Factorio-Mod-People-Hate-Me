# Opens a scenario from one of the repo's mods with graphics, waits for the screenshots it takes,
# then closes the game. Usage: tools\screenshot.ps1 [scenario], for example "gallery" or "asset-catalog".
# Each scenario saves its screenshots to script-output/people-hate-me/<scenario>/ and writes done.txt
# there after the last one. The images are copied to .dev/screenshots/<scenario>.
param([Parameter(Position = 0)][string]$Scenario = "gallery", [int]$TimeoutSeconds = 240)

. "$PSScriptRoot\common.ps1"

$owner = @($ModName, $SketchModName) |
  Where-Object { Test-Path (Join-Path $RepoRoot "$_\scenarios\$Scenario\control.lua") } |
  Select-Object -First 1
if (-not $owner) {
  throw "Neither $ModName nor $SketchModName has a scenario called '$Scenario'."
}

Assert-FactorioNotRunning
Initialize-DevMods
$exe = Get-FactorioExe

$outputDir = Join-Path $UserData "script-output\people-hate-me\$Scenario"
$marker = Join-Path $outputDir "done.txt"
$destination = Join-Path $DevRoot "screenshots\$Scenario"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
if (Test-Path $outputDir) {
  Get-ChildItem $outputDir -File | Remove-Item
}

$arguments = @("--mod-directory", "`"$DevMods`"", "--load-scenario", "$owner/$Scenario", "--disable-audio", "--window-size", "1280x720")
$launchedAt = Get-Date
Start-Process -FilePath $exe -ArgumentList $arguments | Out-Null
Write-Host "Waiting for the $Scenario screenshots. If Steam asks to confirm the launch arguments, click Continue."

function Get-ScreenshotSizes {
  Get-ChildItem $outputDir -Filter *.png -ErrorAction SilentlyContinue | ForEach-Object { "$($_.Name)=$($_.Length)" }
}

# Screenshots are written in the background, so wait for the marker and then for the files to stop growing.
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$previous = $null
$done = $false
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 2
  if (-not (Test-Path $marker)) { continue }
  $sizes = (Get-ScreenshotSizes) -join ","
  if ($sizes -and $sizes -eq $previous) {
    $done = $true
    break
  }
  $previous = $sizes
}

# The Steam build hands graphical launches to Steam, which starts a new process,
# so close whichever Factorio started after this script launched it.
Get-Process -Name "factorio" -ErrorAction SilentlyContinue |
  Where-Object { $_.StartTime -ge $launchedAt } |
  Stop-Process -Force

if (-not $done) {
  throw "Timed out waiting for screenshots in $outputDir. Check $UserData\factorio-current.log"
}

Get-ChildItem $outputDir -Filter *.png | Copy-Item -Destination $destination -Force
Write-Host "Screenshots saved to $destination"
