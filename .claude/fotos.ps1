# Normaliza fotos de producto: cuadrado blanco de 900px, sin recortar el producto.
# Uso: .\fotos.ps1 "archivo-origen.jpeg" "salida.jpg"
param(
  [Parameter(Mandatory = $true)][string]$Origen,
  [Parameter(Mandatory = $true)][string]$Salida
)

Add-Type -AssemblyName System.Drawing

$descargas = "C:\Users\Lujan\Downloads"
$destino = "C:\NEURA\MAXING.PY_E.A.S\productos"
$lado = 900

$rutaOrigen = Join-Path $descargas $Origen
if (-not (Test-Path $rutaOrigen)) { throw "No existe: $rutaOrigen" }

$img = [System.Drawing.Image]::FromFile($rutaOrigen)
$anchoOrig = $img.Width
$altoOrig = $img.Height

$bmp = New-Object System.Drawing.Bitmap($lado, $lado)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.SmoothingMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::White)

# Encaje completo dentro del cuadrado: el producto nunca se corta.
$escala = [math]::Min(($lado / $anchoOrig), ($lado / $altoOrig))
$ancho = [int]($anchoOrig * $escala)
$alto = [int]($altoOrig * $escala)
$x = [int](($lado - $ancho) / 2)
$y = [int](($lado - $alto) / 2)
$g.DrawImage($img, $x, $y, $ancho, $alto)
$g.Dispose()
$img.Dispose()

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$par = New-Object System.Drawing.Imaging.EncoderParameters(1)
$par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 88L)

$rutaSalida = Join-Path $destino $Salida
$bmp.Save($rutaSalida, $codec, $par)
$bmp.Dispose()

$kb = [math]::Round((Get-Item $rutaSalida).Length / 1KB, 1)
"$Salida  origen ${anchoOrig}x${altoOrig}  ->  ${lado}x${lado}  ${kb} KB"
