# Opens the gallery scenario with graphics, waits for the screenshots it takes, then closes the game.
# The images are copied to .dev/screenshots.
param([int]$TimeoutSeconds = 240)

. "$PSScriptRoot\common.ps1"

Assert-FactorioNotRunning
Initialize-DevMods
$exe = Get-FactorioExe

$names = @("overview.png", "standing.png", "fighting.png", "fallen.png", "aftermath.png")
$outputDir = Join-Path $UserData "script-output\people-hate-me"
$destination = Join-Path $DevRoot "screenshots"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
foreach ($name in $names) {
  Remove-Item (Join-Path $outputDir $name) -ErrorAction SilentlyContinue
}

$arguments = @("--mod-directory", "`"$DevMods`"", "--load-scenario", "$ModName/gallery", "--disable-audio", "--window-size", "1280x720")
$launchedAt = Get-Date
Start-Process -FilePath $exe -ArgumentList $arguments | Out-Null
Write-Host "Waiting for the gallery screenshots. If Steam asks to confirm the launch arguments, click Continue."

function Get-ScreenshotSizes {
  $names | ForEach-Object {
    $file = Join-Path $outputDir $_
    if (Test-Path $file) { (Get-Item $file).Length } else { 0 }
  }
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$previous = $null
$done = $false
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 2
  $sizes = Get-ScreenshotSizes
  $complete = -not ($sizes -contains 0)
  if ($complete -and $previous -and (($sizes -join ",") -eq ($previous -join ","))) {
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

foreach ($name in $names) {
  Copy-Item (Join-Path $outputDir $name) (Join-Path $destination $name) -Force
}
Write-Host "Screenshots saved to $destination"
