param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$Port = 3000
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path $Root).Path

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.htm'  = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.xml'  = 'application/xml; charset=utf-8'
  '.txt'  = 'text/plain; charset=utf-8'
  '.svg'  = 'image/svg+xml'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.gif'  = 'image/gif'
  '.webp' = 'image/webp'
  '.ico'  = 'image/x-icon'
  '.woff' = 'font/woff'
  '.woff2'= 'font/woff2'
  '.ttf'  = 'font/ttf'
  '.map'  = 'application/json; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Sirviendo $Root en http://localhost:$Port/"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  try {
    $ruta = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath)

    # Igual que los rewrites de vercel.json: una ruta sin extension prueba
    # primero con .html (/politicadeprivacidad) y despues como carpeta
    # (/admin -> /admin/index.html).
    $candidatos = @()

    # Rutas de la vidriera: las resuelve el propio index.html leyendo la URL.
    # Sin esto, entrar directo a /productos/msi-katana-15 daria 404 en local
    # y no se podria probar que la ruta funciona al recargar.
    #
    # El candidato real va PRIMERO: /productos/ es a la vez una ruta de la app
    # y la carpeta donde viven las fotos, asi que reescribir sin mirar hacia
    # que apunta devolvia el HTML de la pagina en lugar de la imagen. Apache y
    # Vercel hacen lo mismo: sirven el archivo si existe y recien despues
    # aplican el rewrite.
    $rutasApp = '^/(productos|categorias)(/|$)|^/(nosotros|favoritos|lista-de-consulta)$'
    if ($ruta -match $rutasApp) {
      $candidatos += $ruta
      $candidatos += "/index.html"
    } elseif ($ruta -eq "/" -or $ruta.EndsWith("/")) {
      $candidatos += ($ruta + "index.html")
    } elseif (-not [System.IO.Path]::HasExtension($ruta)) {
      $candidatos += ($ruta + ".html")
      $candidatos += ($ruta + "/index.html")
    } else {
      $candidatos += $ruta
    }

    $resolved = $null
    foreach ($c in $candidatos) {
      $full = Join-Path $Root ($c.TrimStart('/') -replace '/', '\')
      try { $resolved = (Resolve-Path -LiteralPath $full -ErrorAction Stop).Path } catch { $resolved = $null }
      if ($resolved) { break }
    }

    if ($resolved -and $resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved -PathType Leaf)) {
      $bytes = [System.IO.File]::ReadAllBytes($resolved)
      $ext = [System.IO.Path]::GetExtension($resolved).ToLower()
      $ct = $mime[$ext]
      if (-not $ct) { $ct = 'application/octet-stream' }
      $res.ContentType = $ct
      $res.Headers.Add('Cache-Control', 'no-store')
      $res.StatusCode = 200
      $res.ContentLength64 = $bytes.Length
      if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
      Write-Host "200 $($req.Url.AbsolutePath)"
    } else {
      $body = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $res.StatusCode = 404
      $res.ContentType = 'text/plain; charset=utf-8'
      $res.ContentLength64 = $body.Length
      if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($body, 0, $body.Length) }
      Write-Host "404 $($req.Url.AbsolutePath)"
    }
  } catch {
    Write-Host "500 $($_.Exception.Message)"
    try { $res.StatusCode = 500 } catch {}
  } finally {
    try { $res.OutputStream.Close() } catch {}
  }
}
