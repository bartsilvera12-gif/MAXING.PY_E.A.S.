# Prepara el logo de una marca para la tarjeta del sitio.
# Recorta el margen en blanco (o transparente) que casi siempre traen los
# archivos de marca, para que el logo llene la tarjeta de forma pareja, y lo
# guarda como PNG con fondo transparente.
# Uso: .\logo.ps1 "images.png" "apple"
param(
  [Parameter(Mandatory = $true)][string]$Origen,
  [Parameter(Mandatory = $true)][string]$Slug,
  # Para logos que son texto claro sobre un fondo de color: si se pasara el
  # blanco a transparente se borrarian las letras y quedaria solo el recuadro.
  [switch]$SinTransparencia
)

Add-Type -AssemblyName System.Drawing

$descargas = "C:\Users\Lujan\Downloads"
$destino = "C:\NEURA\MAXING.PY_E.A.S\marcas"
if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Path $destino | Out-Null }

$rutaOrigen = Join-Path $descargas $Origen
if (-not (Test-Path $rutaOrigen)) { throw "No existe: $rutaOrigen" }

$img = [System.Drawing.Bitmap]::new($rutaOrigen)
$anchoOrig = $img.Width
$altoOrig = $img.Height

# Limite del recuadro que ocupa el logo. Un pixel cuenta si no es casi blanco
# y no es casi transparente.
$minX = $anchoOrig; $minY = $altoOrig; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $altoOrig; $y++) {
  for ($x = 0; $x -lt $anchoOrig; $x++) {
    $p = $img.GetPixel($x, $y)
    $casiBlanco = ($p.R -gt 244 -and $p.G -gt 244 -and $p.B -gt 244)
    $casiInvisible = ($p.A -lt 12)
    if (-not $casiBlanco -and -not $casiInvisible) {
      if ($x -lt $minX) { $minX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}
if ($maxX -lt 0) { $img.Dispose(); throw "La imagen quedo vacia al recortar: revisar $Origen" }

$margen = [int]([math]::Max(2, ($maxX - $minX) * 0.02))
$cx = [math]::Max(0, $minX - $margen)
$cy = [math]::Max(0, $minY - $margen)
$cw = [math]::Min($anchoOrig - $cx, ($maxX - $minX) + 1 + $margen * 2)
$ch = [math]::Min($altoOrig - $cy, ($maxY - $minY) + 1 + $margen * 2)

# Escala para que el lado mayor quede en 480px: alcanza para la tarjeta en
# pantallas de alta densidad sin inflar el peso.
$lado = 480
$esc = [math]::Min($lado / $cw, $lado / $ch)
if ($esc -gt 1) { $esc = 1 }
$destW = [int]($cw * $esc)
$destH = [int]($ch * $esc)

$bmp = New-Object System.Drawing.Bitmap($destW, $destH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.SmoothingMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::Transparent)
$destRect = New-Object System.Drawing.Rectangle(0, 0, $destW, $destH)
$g.DrawImage($img, $destRect, $cx, $cy, $cw, $ch, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

# El blanco de fondo pasa a transparente, asi el logo se apoya sobre la
# tarjeta sin dejar un recuadro visible.
if (-not $SinTransparencia) {
for ($y = 0; $y -lt $destH; $y++) {
  for ($x = 0; $x -lt $destW; $x++) {
    $p = $bmp.GetPixel($x, $y)
    if ($p.R -gt 246 -and $p.G -gt 246 -and $p.B -gt 246) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $p.R, $p.G, $p.B))
    }
  }
}
}

$ruta = Join-Path $destino "$Slug.png"
$bmp.Save($ruta, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$img.Dispose()

$kb = [math]::Round((Get-Item $ruta).Length / 1KB, 1)
"$Slug.png  origen ${anchoOrig}x${altoOrig}  ->  recorte ${cw}x${ch}  ->  ${destW}x${destH}  ${kb} KB"
