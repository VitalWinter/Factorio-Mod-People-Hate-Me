# Builds .dev/screenshots/index.html, one page showing every screenshot the scenarios have taken,
# and opens it in the default browser. Click an image to see it at full size. -NoOpen only builds it.
param([switch]$NoOpen)

. "$PSScriptRoot\common.ps1"

$root = Join-Path $DevRoot "screenshots"
$index = Join-Path $root "index.html"
$encode = { param($value) [System.Net.WebUtility]::HtmlEncode($value) }

$sections = foreach ($folder in Get-ChildItem $root -Directory | Sort-Object Name) {
  # Copies keep the game's write times, so this is the order the scenario took them in.
  $images = Get-ChildItem $folder.FullName -Filter *.png | Sort-Object LastWriteTime
  if (-not $images) { continue }
  $taken = ($images | Measure-Object LastWriteTime -Maximum).Maximum.ToString("yyyy-MM-dd HH:mm")
  $figures = foreach ($image in $images) {
    $src = & $encode "$($folder.Name)/$($image.Name)"
    "<figure><a href=`"$src`"><img src=`"$src`" loading=`"lazy`"></a><figcaption>$(& $encode $image.BaseName)</figcaption></figure>"
  }
  "<section><h2>$(& $encode $folder.Name) <small>taken $taken</small></h2>$($figures -join "`n")</section>"
}

$html = @"
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>People Hate Me screenshots</title>
<style>
  body { background: #1e1e1e; color: #ddd; font-family: Segoe UI, sans-serif; margin: 2rem; }
  h1 { font-weight: 600; }
  h2 { border-bottom: 1px solid #444; padding-bottom: .3rem; margin-top: 2.5rem; }
  small { color: #888; font-weight: normal; font-size: .7em; }
  figure { margin: 1rem 0 2rem; }
  img { max-width: 100%; border: 1px solid #333; }
  figcaption { color: #aaa; margin-top: .3rem; }
</style>
</head>
<body>
<h1>People Hate Me screenshots</h1>
<p>Click an image to open it at full size. Rebuild with tools\view-screenshots.ps1 after taking new ones.</p>
$($sections -join "`n")
</body>
</html>
"@
Set-Content -Path $index -Value $html -Encoding utf8
Write-Host "Built $index"
if (-not $NoOpen) {
  Start-Process $index
}
