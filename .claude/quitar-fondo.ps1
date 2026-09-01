# Quita el fondo de una foto de producto y lo reemplaza por blanco.
#
# No usa un modelo de segmentacion: hace un relleno por inundacion desde los
# bordes. Solo borra el fondo que este CONECTADO al borde de la imagen, asi que
# un objeto oscuro sobre fondo oscuro no se come, siempre que haya un salto de
# color en su contorno. Para fotos de producto sobre fondo parejo alcanza.
#
# Uso: .\quitar-fondo.ps1 "categorias\perifericos.jpg" [tolerancia]
param(
  [Parameter(Mandatory = $true)][string]$Ruta,
  [int]$Tolerancia = 26,
  # Con -Local cada pixel se compara con el vecino desde el que se llego, no
  # con un color fijo. Sirve cuando el fondo tiene degradado o vineteado: uno
  # parejo se resuelve mejor sin esto, porque el modo local puede filtrarse por
  # un borde de bajo contraste.
  [switch]$Local,
  # Con -Umbral N el fondo se define por luminancia: se rellena desde el borde
  # todo lo que sea mas claro que N. Sirve para fondos oscuros con vineteado,
  # donde la distancia a un color fijo no alcanza.
  [int]$Umbral = 0,
  # Techo del umbral: el fondo vive en una banda de luminancia, no en "todo lo
  # mas claro que N". Sin esto un objeto plateado se toma por fondo.
  [int]$UmbralMax = 255,
  # Vueltas de limpieza de sombra alrededor del producto.
  [int]$Sombra = 0,
  # Piso de esa limpieza: por debajo se considera producto y no se toca.
  [int]$SombraMin = 12
)

Add-Type -AssemblyName System.Drawing

$full = Join-Path "C:\NEURA\MAXING.PY_E.A.S" $Ruta
if (-not (Test-Path $full)) { throw "No existe: $full" }

$src = [System.Drawing.Bitmap]::new($full)
$w = $src.Width
$h = $src.Height

# Copia a 24bpp para tener un layout de bytes predecible.
$bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.DrawImage($src, 0, 0, $w, $h)
$g.Dispose()
$src.Dispose()

$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$datos = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$stride = $datos.Stride
$largo = $stride * $h
$bytes = New-Object byte[] $largo
[System.Runtime.InteropServices.Marshal]::Copy($datos.Scan0, $bytes, 0, $largo)

# Color de fondo: promedio de las cuatro esquinas.
function Idx([int]$x, [int]$y) { return $y * $stride + $x * 3 }
$xd = $w - 3
$yd = $h - 3
$ex = @(2, $xd, 2, $xd)
$ey = @(2, 2, $yd, $yd)
$sb = 0; $sg = 0; $sr = 0
for ($k = 0; $k -lt 4; $k++) {
  $i = Idx $ex[$k] $ey[$k]
  $sb += $bytes[$i]; $sg += $bytes[$i + 1]; $sr += $bytes[$i + 2]
}
$fb = [int]($sb / 4); $fg = [int]($sg / 4); $fr = [int]($sr / 4)

# Relleno por inundacion desde todo el borde.
$marca = New-Object bool[] ($w * $h)
$pila = New-Object System.Collections.Generic.Stack[int]
for ($x = 0; $x -lt $w; $x++) { $pila.Push($x); $pila.Push(($h - 1) * $w + $x) }
for ($y = 0; $y -lt $h; $y++) { $pila.Push($y * $w); $pila.Push($y * $w + $w - 1) }

$tol2 = $Tolerancia * $Tolerancia * 3
# En modo local se guarda el color del pixel desde el que se llego a cada uno.
$refB = New-Object byte[] ($w * $h)
$refG = New-Object byte[] ($w * $h)
$refR = New-Object byte[] ($w * $h)
if ($Local) {
  for ($k = 0; $k -lt $w * $h; $k++) { $refB[$k] = $fb; $refG[$k] = $fg; $refR[$k] = $fr }
}
while ($pila.Count -gt 0) {
  $p = $pila.Pop()
  if ($marca[$p]) { continue }
  $px = $p % $w
  $py = [int](($p - $px) / $w)
  $i = Idx $px $py
  if ($Umbral -gt 0) {
    $lum = ($bytes[$i] + $bytes[$i + 1] + $bytes[$i + 2]) / 3
    if ($lum -lt $Umbral -or $lum -gt $UmbralMax) { continue }
  } else {
    if ($Local) {
      $db = $bytes[$i] - $refB[$p]; $dg = $bytes[$i + 1] - $refG[$p]; $dr = $bytes[$i + 2] - $refR[$p]
    } else {
      $db = $bytes[$i] - $fb; $dg = $bytes[$i + 1] - $fg; $dr = $bytes[$i + 2] - $fr
    }
    if (($db * $db + $dg * $dg + $dr * $dr) -gt $tol2) { continue }
  }
  $marca[$p] = $true
  if ($Local) {
    $cb = $bytes[$i]; $cg = $bytes[$i + 1]; $cr = $bytes[$i + 2]
    if ($px -gt 0 -and -not $marca[$p - 1]) { $refB[$p - 1] = $cb; $refG[$p - 1] = $cg; $refR[$p - 1] = $cr }
    if ($px -lt $w - 1 -and -not $marca[$p + 1]) { $refB[$p + 1] = $cb; $refG[$p + 1] = $cg; $refR[$p + 1] = $cr }
    if ($py -gt 0 -and -not $marca[$p - $w]) { $refB[$p - $w] = $cb; $refG[$p - $w] = $cg; $refR[$p - $w] = $cr }
    if ($py -lt $h - 1 -and -not $marca[$p + $w]) { $refB[$p + $w] = $cb; $refG[$p + $w] = $cg; $refR[$p + $w] = $cr }
  }
  if ($px -gt 0) { $pila.Push($p - 1) }
  if ($px -lt $w - 1) { $pila.Push($p + 1) }
  if ($py -gt 0) { $pila.Push($p - $w) }
  if ($py -lt $h - 1) { $pila.Push($p + $w) }
}

# Limpieza de sombra: el contorno de la sombra queda mas oscuro que el fondo,
# asi que el relleno no lo alcanza y sobrevive como un borde sucio. Se come de
# a un pixel por vuelta, solo lo que esta pegado al fondo y no es negro pleno:
# el producto en si es mucho mas oscuro y no se toca.
if ($Sombra -gt 0) {
  for ($vuelta = 0; $vuelta -lt $Sombra; $vuelta++) {
    $nuevos = New-Object System.Collections.Generic.List[int]
    for ($py = 1; $py -lt $h - 1; $py++) {
      for ($px = 1; $px -lt $w - 1; $px++) {
        $p = $py * $w + $px
        if ($marca[$p]) { continue }
        if (-not ($marca[$p - 1] -or $marca[$p + 1] -or $marca[$p - $w] -or $marca[$p + $w])) { continue }
        $i = Idx $px $py
        $lum = ($bytes[$i] + $bytes[$i + 1] + $bytes[$i + 2]) / 3
        if ($lum -gt $SombraMin -and $lum -lt $UmbralMax) { $nuevos.Add($p) }
      }
    }
    if ($nuevos.Count -eq 0) { break }
    foreach ($p in $nuevos) { $marca[$p] = $true }
  }
}

# El fondo pasa a blanco.
$quitados = 0
for ($p = 0; $p -lt $w * $h; $p++) {
  if (-not $marca[$p]) { continue }
  $px = $p % $w
  $py = [int](($p - $px) / $w)
  $i = Idx $px $py
  $bytes[$i] = 255; $bytes[$i + 1] = 255; $bytes[$i + 2] = 255
  $quitados++
}

# Limpieza del halo: un pixel que quedo pegado al fondo y sigue pareciendose a
# el se aclara, para que no sobreviva un borde del color viejo.
for ($py = 1; $py -lt $h - 1; $py++) {
  for ($px = 1; $px -lt $w - 1; $px++) {
    $p = $py * $w + $px
    if ($marca[$p]) { continue }
    if (-not ($marca[$p - 1] -or $marca[$p + 1] -or $marca[$p - $w] -or $marca[$p + $w])) { continue }
    $i = Idx $px $py
    $db = $bytes[$i] - $fb; $dg = $bytes[$i + 1] - $fg; $dr = $bytes[$i + 2] - $fr
    $d2 = $db * $db + $dg * $dg + $dr * $dr
    if ($d2 -lt $tol2 * 4) {
      $bytes[$i] = [byte](($bytes[$i] + 255) / 2)
      $bytes[$i + 1] = [byte](($bytes[$i + 1] + 255) / 2)
      $bytes[$i + 2] = [byte](($bytes[$i + 2] + 255) / 2)
    }
  }
}

[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $datos.Scan0, $largo)
$bmp.UnlockBits($datos)

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$par = New-Object System.Drawing.Imaging.EncoderParameters(1)
$par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 90L)
$bmp.Save($full, $codec, $par)
$bmp.Dispose()

$pct = [math]::Round($quitados * 100.0 / ($w * $h), 1)
$kb = [math]::Round((Get-Item $full).Length / 1KB, 1)
"$Ruta  fondo #$('{0:X2}{1:X2}{2:X2}' -f $fr,$fg,$fb)  quitado $pct% de la imagen  ${kb} KB"
