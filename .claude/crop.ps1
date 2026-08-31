param([string]$Src, [string]$Dst, [double]$FracAncho = 0.57, [double]$FracTop = 0.06, [int]$AnchoSalida = 1000)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$original = [System.Drawing.Image]::FromFile($Src)
$espejo = New-Object System.Drawing.Bitmap($original)
$espejo.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
Write-Host "espejada: $($espejo.Width)x$($espejo.Height)"

$py = [int]($espejo.Height * $FracTop)
$pw = [int]($espejo.Width * $FracAncho)
$ph = $espejo.Height - $py
$region = New-Object System.Drawing.Rectangle(0, $py, $pw, $ph)
$recorte = $espejo.Clone($region, $espejo.PixelFormat)
Write-Host "recorte:  $($recorte.Width)x$($recorte.Height)"

$ah = [int]([math]::Round($recorte.Height * ($AnchoSalida / $recorte.Width)))
$final = New-Object System.Drawing.Bitmap($AnchoSalida, $ah)
$lienzo = [System.Drawing.Graphics]::FromImage($final)
$lienzo.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$lienzo.DrawImage($recorte, 0, 0, $AnchoSalida, $ah)
$lienzo.Dispose()

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$par = New-Object System.Drawing.Imaging.EncoderParameters(1)
$par.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]86)
$final.Save($Dst, $codec, $par)
$final.Dispose(); $recorte.Dispose(); $espejo.Dispose(); $original.Dispose()
Write-Host "salida:   ${AnchoSalida}x${ah} · $([math]::Round((Get-Item $Dst).Length/1KB,0)) KB"
