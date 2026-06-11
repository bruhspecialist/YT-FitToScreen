# Renders the extension icon (dark rounded square, white screen frame with
# outward arrows, red underline) at the sizes the Chrome Web Store needs.
# Geometry mirrors content.js's 24-grid button art, scaled to a 128 canvas.
Add-Type -AssemblyName System.Drawing

function New-Icon([int]$size, [string]$outPath) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $s = $size / 128.0

    # Background: dark rounded square
    $bg = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [float](48 * $s)
    $w = [float]$size
    $bg.AddArc(0, 0, $d, $d, 180, 90)
    $bg.AddArc($w - $d, 0, $d, $d, 270, 90)
    $bg.AddArc($w - $d, $w - $d, $d, $d, 0, 90)
    $bg.AddArc(0, $w - $d, $d, $d, 90, 90)
    $bg.CloseFigure()
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 33, 33, 33))
    $g.FillPath($bgBrush, $bg)

    # Screen frame (stroke-centered, like the 24-grid art scaled by 128/24)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [float](10.7 * $s))
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawRectangle($pen, [float](16 * $s), [float](26 * $s), [float](96 * $s), [float](64 * $s))

    # Outward arrows
    $white = [System.Drawing.Brushes]::White
    $left = @(
        (New-Object System.Drawing.PointF([float](50 * $s), [float](42 * $s))),
        (New-Object System.Drawing.PointF([float](30 * $s), [float](58 * $s))),
        (New-Object System.Drawing.PointF([float](50 * $s), [float](74 * $s)))
    )
    $right = @(
        (New-Object System.Drawing.PointF([float](78 * $s), [float](42 * $s))),
        (New-Object System.Drawing.PointF([float](98 * $s), [float](58 * $s))),
        (New-Object System.Drawing.PointF([float](78 * $s), [float](74 * $s)))
    )
    $g.FillPolygon($white, $left)
    $g.FillPolygon($white, $right)

    # Red underline
    $red = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 0, 51))
    $g.FillRectangle($red, [float](32 * $s), [float](104 * $s), [float](64 * $s), [float](10 * $s))

    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$iconDir = Join-Path $PSScriptRoot 'icons'
New-Item -ItemType Directory -Force $iconDir | Out-Null
foreach ($size in 16, 48, 128) {
    New-Icon $size (Join-Path $iconDir "icon$size.png")
}
Write-Host "Icons written to $iconDir"
