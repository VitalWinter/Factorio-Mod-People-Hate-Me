# Builds dist/<name>_<version>.zip in the layout the Factorio mod portal expects.
. "$PSScriptRoot\common.ps1"

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$info = Get-Content (Join-Path $ModSource "info.json") -Raw | ConvertFrom-Json
$folder = "$($info.name)_$($info.version)"
$dist = Join-Path $RepoRoot "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zipPath = Join-Path $dist "$folder.zip"
Remove-Item $zipPath -ErrorAction SilentlyContinue

# Entries are added by hand because Compress-Archive on Windows PowerShell writes
# backslash separators, which Factorio does not accept.
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")
try {
  Get-ChildItem $ModSource -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($ModSource.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, "$folder/$relative") | Out-Null
  }
} finally {
  $zip.Dispose()
}
Write-Host "Built $zipPath"
