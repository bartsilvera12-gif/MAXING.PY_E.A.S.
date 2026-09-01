# Prepara la imagen de una categoria. Las fichas del inicio son 4:3 y la foto
# va con object-fit: contain, asi que solo hace falta normalizar el tamano y
# apoyarla sobre blanco.
# Uso: .\catfoto.ps1 "images.jpg" "perifericos"
param(
  [Parameter(Mandatory = $true)][string]$Origen,
  [Parameter(Mandatory = $true)][string]$Salida
)

Add-Type -AssemblyName System.Drawing

$descargas = "C:\Users\Lujan\Downloads"
$destino = "C:\NEURA\MAXING.PY_E.A.S\categorias"
if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Path $destino | Out-Null }

$rutaOrigen = Join-Path $descargas $Origen
if (-not (Test-Path $rutaOrigen)) { throw "No existe: $rutaOrigen" }

$img = [System.Drawing.Image]::FromFile($rutaOrigen)
$anchoOrig = $img.Width
$altoOrig = $img.Height

$maxLado = 720
$esc = [math]::Min($maxLado / $anchoOrig, $maxLado / $altoOrig)
if ($esc -gt 1) { $esc = 1 }
$ancho = [int]($anchoOrig * $esc)
$alto = [int]($altoOrig * $esc)

$bmp = New-Object System.Drawing.Bitmap($ancho, $alto)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.SmoothingMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::White)
$g.DrawImage($img, 0, 0, $ancho, $alto)
$g.Dispose()
$img.Dispose()

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$par = New-Object System.Drawing.Imaging.EncoderParameters(1)
$par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 86L)

$ruta = Join-Path $destino "$Salida.jpg"
$bmp.Save($ruta, $codec, $par)
$bmp.Dispose()

$kb = [math]::Round((Get-Item $ruta).Length / 1KB, 1)
"$Salida.jpg  origen ${anchoOrig}x${altoOrig}  ->  ${ancho}x${alto}  ${kb} KB"
