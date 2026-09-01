# Corta un logo con lockup vertical (icono arriba, palabra abajo) para dejar
# solo el icono. Busca la primera banda horizontal transparente entre ambos.
# Uso: .\recortar-icono.ps1 "xiaomi"
param([Parameter(Mandatory = $true)][string]$Slug)

Add-Type -AssemblyName System.Drawing

$ruta = Join-Path "C:\NEURA\MAXING.PY_E.A.S\marcas" "$Slug.png"
if (-not (Test-Path $ruta)) { throw "No existe: $ruta" }

$img = [System.Drawing.Bitmap]::new($ruta)
$w = $img.Width
$h = $img.Height

$corte = 0
$desde = [int]($h * 0.5)
$hasta = [int]($h * 0.88)
for ($y = $desde; $y -lt $hasta; $y++) {
  $vacia = $true
  for ($x = 0; $x -lt $w; $x++) {
    if ($img.GetPixel($x, $y).A -gt 20) { $vacia = $false; break }
  }
  if ($vacia) { $corte = $y; break }
}
if ($corte -eq 0) { $corte = [int]($h * 0.7) }

$bmp = New-Object System.Drawing.Bitmap($w, $corte, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$destRect = New-Object System.Drawing.Rectangle(0, 0, $w, $corte)
$g.DrawImage($img, $destRect, 0, 0, $w, $corte, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$img.Dispose()

$bmp.Save($ruta, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$kb = [math]::Round((Get-Item $ruta).Length / 1KB, 1)
"$Slug.png  ${w}x${h}  ->  ${w}x${corte}  ${kb} KB"
