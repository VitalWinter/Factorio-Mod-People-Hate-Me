# Loads the mod headless and runs the gallery scenario's checks. Exits 0 on pass, 1 on failure.
. "$PSScriptRoot\common.ps1"

Assert-FactorioNotRunning
Initialize-DevMods
$exe = Get-FactorioExe

# factorio.exe is a windowed program, so PowerShell only waits for it through Start-Process -Wait.
$arguments = @("--mod-directory", "`"$DevMods`"", "--test-scenario", "$ModName/gallery", "--test-ticks", "900", "--disable-audio")
$game = Start-Process -FilePath $exe -ArgumentList $arguments -NoNewWindow -Wait -PassThru
$code = $game.ExitCode

if ($code -eq 0) {
  Write-Host "PASSED" -ForegroundColor Green
} else {
  Write-Host "FAILED (exit code $code). Full log: $UserData\factorio-current.log" -ForegroundColor Red
}
exit $code
