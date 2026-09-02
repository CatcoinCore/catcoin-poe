Add-Type -AssemblyName System.Drawing
$sourcePath = "C:\Users\nkpat\.gemini\antigravity\brain\949d1b1c-a7d3-4d0c-a102-39c5d8363178\catcoin_feature_graphic_v4_source_image_1774969162308.png"
$destPath = "d:\source\shelf\agentic\catcoin2\catcoin_feature_graphic.png"

# Wait for the file to be present
while (-not (Test-Path $sourcePath)) { Start-Sleep -Seconds 1 }

$img = [System.Drawing.Image]::FromFile($sourcePath)
$sourceWidth = $img.Width
$sourceHeight = $img.Height

# Calculate crop to maintain aspect ratio (1024:500)
# We want to fill 1024x500.
# If the image is square (e.g. 1024x1024), we crop the top and bottom.
$targetWidth = 1024
$targetHeight = 500

$newImg = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
$graph = [System.Drawing.Graphics]::FromImage($newImg)

$graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graph.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

# Center crop logic
$cropY = ($sourceHeight - ($sourceWidth * ($targetHeight / $targetWidth))) / 2
$srcRect = New-Object System.Drawing.RectangleF(0, $cropY, $sourceWidth, ($sourceWidth * ($targetHeight / $targetWidth)))
$destRect = New-Object System.Drawing.RectangleF(0, 0, $targetWidth, $targetHeight)

$graph.DrawImage($img, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

$newImg.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graph.Dispose()
$newImg.Dispose()
$img.Dispose()
Write-Host "Cropped to 1024x500 (Center Crop)"
