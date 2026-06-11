# Renders a 1280x800 Chrome Web Store listing screenshot: before/after
# panels showing pillarboxed vs fit-to-screen video on an ultrawide.
Add-Type -AssemblyName System.Drawing

$W = 1280; $H = 800
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

function RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function DrawVideo([float]$x, [float]$y, [float]$w, [float]$h) {
    # Abstract "video": blue-purple gradient with a soft play triangle
    $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 63, 81, 181),
        [System.Drawing.Color]::FromArgb(255, 0, 150, 199),
        45.0)
    $g.FillRectangle($grad, $rect)
    $cx = $x + $w / 2; $cy = $y + $h / 2; $r = [Math]::Min($w, $h) * 0.18
    $tri = @(
        (New-Object System.Drawing.PointF(($cx - $r * 0.6), ($cy - $r))),
        (New-Object System.Drawing.PointF(($cx + $r), $cy)),
        (New-Object System.Drawing.PointF(($cx - $r * 0.6), ($cy + $r)))
    )
    $playBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(190, 255, 255, 255))
    $g.FillPolygon($playBrush, $tri)
}

# Background
$g.Clear([System.Drawing.Color]::FromArgb(255, 15, 15, 15))

# Title + subtitle
$white = [System.Drawing.Brushes]::White
$gray  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 170, 170, 170))
$center = New-Object System.Drawing.StringFormat
$center.Alignment = [System.Drawing.StringAlignment]::Center

$titleFont = New-Object System.Drawing.Font('Segoe UI', 40, [System.Drawing.FontStyle]::Bold)
$subFont   = New-Object System.Drawing.Font('Segoe UI', 20)
$labelFont = New-Object System.Drawing.Font('Segoe UI', 17, [System.Drawing.FontStyle]::Bold)
$bodyFont  = New-Object System.Drawing.Font('Segoe UI', 19)

$g.DrawString('Fill your ultrawide screen', $titleFont, $white, (New-Object System.Drawing.RectangleF(0, 48, $W, 70)), $center)
$g.DrawString('One button on the YouTube player. Crop, not stretch.', $subFont, $gray, (New-Object System.Drawing.RectangleF(0, 125, $W, 40)), $center)

# Panels: 21:9 screens
$panelW = 520.0; $panelH = 223.0; $panelY = 230.0
$bezel = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 70, 70, 70), 5)

# BEFORE: pillarboxed 16:9 video inside the ultrawide screen
$bx = 85.0
$g.FillPath([System.Drawing.Brushes]::Black, (RoundedPath $bx $panelY $panelW $panelH 8))
$videoW = $panelH * 16.0 / 9.0
DrawVideo ($bx + ($panelW - $videoW) / 2) $panelY $videoW $panelH
$g.DrawPath($bezel, (RoundedPath $bx $panelY $panelW $panelH 8))
$g.DrawString('BEFORE  -  black bars', $labelFont, $gray, (New-Object System.Drawing.RectangleF($bx, ($panelY + $panelH + 18), $panelW, 30)), $center)

# AFTER: video fills the whole screen
$ax = 675.0
DrawVideo $ax $panelY $panelW $panelH
$g.DrawPath($bezel, (RoundedPath $ax $panelY $panelW $panelH 8))
$redBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 60, 80))
$g.DrawString('AFTER  -  fit to screen', $labelFont, $redBrush, (New-Object System.Drawing.RectangleF($ax, ($panelY + $panelH + 18), $panelW, 30)), $center)

# Arrow between panels
$arrowFont = New-Object System.Drawing.Font('Segoe UI', 34, [System.Drawing.FontStyle]::Bold)
$g.DrawString([char]0x2192, $arrowFont, $white, (New-Object System.Drawing.RectangleF(605, ($panelY + $panelH / 2 - 32), 70, 60)), $center)

# Bottom: extension icon + pitch line, centered as a block
$icon = [System.Drawing.Image]::FromFile("$PSScriptRoot\icons\icon128.png")
$iconSize = 92
$text1 = 'Adds one button next to fullscreen'
$text2 = 'Click again or press Esc to go back to normal'
$textSize = $g.MeasureString($text1, $bodyFont)
$blockW = $iconSize + 28 + $textSize.Width
$blockX = ($W - $blockW) / 2
$blockY = 590.0
$g.DrawImage($icon, [float]$blockX, [float]$blockY, [float]$iconSize, [float]$iconSize)
$g.DrawString($text1, $bodyFont, $white, [float]($blockX + $iconSize + 28), [float]($blockY + 16))
$g.DrawString($text2, $bodyFont, $gray, [float]($blockX + $iconSize + 28), [float]($blockY + 50))
$icon.Dispose()

$g.Dispose()
$bmp.Save("$PSScriptRoot\store-screenshot.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host 'Saved store-screenshot.png'
