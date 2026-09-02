Add-Type -AssemblyName System.Drawing
$sourcePath = "C:\Users\nkpat\.gemini\antigravity\brain\949d1b1c-a7d3-4d0c-a102-39c5d8363178\catcoin_feature_graphic_1024x500_v3_1774968988283.png"
$destPath = "d:\source\shelf\agentic\catcoin2\catcoin_feature_graphic.png"

$img = [System.Drawing.Image]::FromFile($sourcePath)
$newImg = New-Object System.Drawing.Bitmap(1024, 500)
$graph = [System.Drawing.Graphics]::FromImage($newImg)

$graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graph.DrawImage($img, 0, 0, 1024, 500)

$newImg.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graph.Dispose()
$newImg.Dispose()
$img.Dispose()
Write-Host "Resized to 1024x500"
