# Recorta el margen blanco de una foto de categoria para que el producto ocupe
# la ficha en vez de flotar chico en el centro. Deja un margen parejo del 4%.
# Uso: .\recortar-cat.ps1 "tablets"
param([Parameter(Mandatory = $true)][string]$Slug)

Add-Type -AssemblyName System.Drawing

$ruta = Join-Path "C:\NEURA\MAXING.PY_E.A.S\categorias" "$Slug.jpg"
if (-not (Test-Path $ruta)) { throw "No existe: $ruta" }

$img = [System.Drawing.Bitmap]::new($ruta)
$w = $img.Width
$h = $img.Height

# Recuadro que ocupa el contenido: un pixel cuenta si no es casi blanco.
$minX = $w; $minY = $h; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $h; $y++) {
  for ($x = 0; $x -lt $w; $x++) {
    $p = $img.GetPixel($x, $y)
    if ($p.R -lt 243 -or $p.G -lt 243 -or $p.B -lt 243) {
      if ($x -lt $minX) { $minX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}
if ($maxX -lt 0) { $img.Dispose(); throw "Quedo vacia al recortar: $Slug" }

$cw = ($maxX - $minX) + 1
$ch = ($maxY - $minY) + 1
$margen = [int]([math]::Max(6, [math]::Max($cw, $ch) * 0.04))
$cx = [math]::Max(0, $minX - $margen)
$cy = [math]::Max(0, $minY - $margen)
$cw = [math]::Min($w - $cx, $cw + $margen * 2)
$ch = [math]::Min($h - $cy, $ch + $margen * 2)

$maxLado = 720
$esc = [math]::Min($maxLado / $cw, $maxLado / $ch)
if ($esc -gt 1) { $esc = 1 }
$destW = [int]($cw * $esc)
$destH = [int]($ch * $esc)

$bmp = New-Object System.Drawing.Bitmap($destW, $destH)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.SmoothingMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::White)
$destRect = New-Object System.Drawing.Rectangle(0, 0, $destW, $destH)
$g.DrawImage($img, $destRect, $cx, $cy, $cw, $ch, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$img.Dispose()

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$par = New-Object System.Drawing.Imaging.EncoderParameters(1)
$par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 88L)
$bmp.Save($ruta, $codec, $par)
$bmp.Dispose()

$kb = [math]::Round((Get-Item $ruta).Length / 1KB, 1)
"$Slug.jpg  ${w}x${h}  ->  ${destW}x${destH}  ${kb} KB"
