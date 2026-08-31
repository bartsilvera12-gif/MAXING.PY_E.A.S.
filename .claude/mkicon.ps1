param([string]$OutDir)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Geometria identica a favicon.svg (espacio 64x64)
$M = @(
  @(10,46),@(10,18),@(17,18),@(26,34),@(35,18),@(42,18),
  @(42,46),@(35,46),@(35,27),@(26,43),@(17,27),@(17,46)
)

function New-Icon([int]$size) {
  $s = $size / 64.0
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  # cuadrado redondeado negro (rx = 14)
  $r = 14.0 * $s; $d = $r * 2; $w = [float]$size
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc(0, 0, $d, $d, 180, 90)
  $path.AddArc($w - $d, 0, $d, $d, 270, 90)
  $path.AddArc($w - $d, $w - $d, $d, $d, 0, 90)
  $path.AddArc(0, $w - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $black = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 0, 0))
  $g.FillPath($black, $path)

  # M blanca
  $pts = $M | ForEach-Object { New-Object System.Drawing.PointF([float]($_[0] * $s), [float]($_[1] * $s)) }
  $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
  $g.FillPolygon($white, [System.Drawing.PointF[]]$pts)

  # punto verde (#40DF36), cx 50 cy 41.5 r 4.5
  $green = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 64, 223, 54))
  $g.FillEllipse($green, [float]((50 - 4.5) * $s), [float]((41.5 - 4.5) * $s), [float](9 * $s), [float](9 * $s))

  $g.Dispose(); $black.Dispose(); $white.Dispose(); $green.Dispose(); $path.Dispose()
  return $bmp
}

function Get-PngBytes($bmp) {
  $ms = New-Object System.IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $bytes = $ms.ToArray()
  $ms.Dispose()
  return ,$bytes
}

# PNG sueltos
foreach ($sz in 180, 512) {
  $b = New-Icon $sz
  $name = if ($sz -eq 180) { 'apple-touch-icon.png' } else { 'icon-512.png' }
  $b.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "$name  $sz x $sz"
  $b.Dispose()
}

# favicon.ico con 16/32/48 embebidos como PNG
$sizes = 16, 32, 48
$blobs = @()
foreach ($sz in $sizes) { $b = New-Icon $sz; $blobs += ,(Get-PngBytes $b); $b.Dispose() }

$ico = Join-Path $OutDir 'favicon.ico'
$fs = [System.IO.File]::Create($ico)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)   # ICONDIR
$offset = 6 + (16 * $sizes.Count)
for ($i = 0; $i -lt $sizes.Count; $i++) {
  $sz = $sizes[$i]; $len = $blobs[$i].Length
  $bw.Write([byte]$(if ($sz -ge 256) { 0 } else { $sz }))   # width
  $bw.Write([byte]$(if ($sz -ge 256) { 0 } else { $sz }))   # height
  $bw.Write([byte]0); $bw.Write([byte]0)                    # colores / reservado
  $bw.Write([uint16]1); $bw.Write([uint16]32)               # planes / bpp
  $bw.Write([uint32]$len); $bw.Write([uint32]$offset)
  $offset += $len
}
foreach ($b in $blobs) { $bw.Write($b) }
$bw.Flush(); $bw.Close(); $fs.Close()
Write-Host "favicon.ico  $($sizes -join '/')  $((Get-Item $ico).Length) bytes"
