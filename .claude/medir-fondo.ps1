# Mide el rango de color del fondo (borde de la imagen) y el del contenido,
# para elegir una tolerancia que separe uno del otro.
param([Parameter(Mandatory = $true)][string]$Ruta)

Add-Type -AssemblyName System.Drawing
$full = Join-Path "C:\NEURA\MAXING.PY_E.A.S" $Ruta
$bmp = [System.Drawing.Bitmap]::new($full)
$w = $bmp.Width
$h = $bmp.Height

$minL = 999; $maxL = -1
$paso = 3
for ($x = 0; $x -lt $w; $x += $paso) {
  foreach ($y in @(1, ($h - 2))) {
    $p = $bmp.GetPixel($x, $y)
    $l = [int](($p.R + $p.G + $p.B) / 3)
    if ($l -lt $minL) { $minL = $l }
    if ($l -gt $maxL) { $maxL = $l }
  }
}
for ($y = 0; $y -lt $h; $y += $paso) {
  foreach ($x in @(1, ($w - 2))) {
    $p = $bmp.GetPixel($x, $y)
    $l = [int](($p.R + $p.G + $p.B) / 3)
    if ($l -lt $minL) { $minL = $l }
    if ($l -gt $maxL) { $maxL = $l }
  }
}

# Histograma de luminancia de toda la imagen, en tramos de 16.
$hist = New-Object int[] 16
for ($y = 0; $y -lt $h; $y += 4) {
  for ($x = 0; $x -lt $w; $x += 4) {
    $p = $bmp.GetPixel($x, $y)
    $l = [int](($p.R + $p.G + $p.B) / 3)
    $hist[[int]($l / 16)]++
  }
}
$bmp.Dispose()

"borde: luminancia de $minL a $maxL  (rango $($maxL - $minL))"
for ($k = 0; $k -lt 16; $k++) {
  if ($hist[$k] -gt 0) { "  {0,3}-{1,3}: {2}" -f ($k * 16), ($k * 16 + 15), $hist[$k] }
}
