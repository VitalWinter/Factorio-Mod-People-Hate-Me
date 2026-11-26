# Loads the mod headless and runs the gallery scenario's checks, then tools\parity.ps1 to check
# the mod still plays exactly like the base game. Exits 0 when both pass, 1 otherwise.
. "$PSScriptRoot\common.ps1"

Assert-FactorioNotRunning
Initialize-DevMods
$exe = Get-FactorioExe

# factorio.exe is a windowed program, so PowerShell only waits for it through Start-Process -Wait.
$arguments = @("--mod-directory", "`"$DevMods`"", "--test-scenario", "$ModName/gallery", "--test-ticks", "900", "--disable-audio")
$game = Start-Process -FilePath $exe -ArgumentList $arguments -NoNewWindow -Wait -PassThru
$code = $game.ExitCode

if ($code -eq 0) {
  Write-Host "Gallery checks PASSED" -ForegroundColor Green
} else {
  Write-Host "Gallery checks FAILED (exit code $code). Full log: $UserData\factorio-current.log" -ForegroundColor Red
}

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "parity.ps1")
$parity = $LASTEXITCODE

if ($code -eq 0 -and $parity -eq 0) {
  Write-Host "PASSED" -ForegroundColor Green
  exit 0
}
Write-Host "FAILED" -ForegroundColor Red
exit 1
