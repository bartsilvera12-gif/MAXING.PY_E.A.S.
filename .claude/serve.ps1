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
      # Solo sirve archivos: /productos es a la vez una ruta de la app y la
      # carpeta de las fotos. Sin este filtro la carpeta "ganaba" y la ruta
      # devolvia 404 en local, cosa que en Vercel no pasa porque ahi el
      # rewrite solo cede ante un archivo.
      if ($resolved -and -not (Test-Path -LiteralPath $resolved -PathType Leaf)) { $resolved = $null }
      if ($resolved) { break }
    }

    # Emula lo que hace api/pagina.js en Vercel: cuando /productos/<slug> cae
    # en el index.html, se le saca al bloque <helmet> la metadata generica y
    # se le empalma la de esa pagina antes de </head>. El bloque no se arma
    # aca: se lee de .claude/meta-local/<slug>.html, que se genera con la
    # funcion de verdad. Asi la logica vive en un solo lugar y esto solo
    # prueba el empalme, que es lo que puede romper el frontend.
    $metaLocal = $null
    if ($resolved -and $ruta -match '^/(productos|categorias)/([^/]+)$') {
      $slugPedido = $Matches[2]
      $fixture = Join-Path $Root (".claude\meta-local\" + $slugPedido + ".html")
      if ((Test-Path -LiteralPath $fixture) -and $resolved.EndsWith("index.html", [System.StringComparison]::OrdinalIgnoreCase)) {
        $metaLocal = [System.IO.File]::ReadAllText($fixture, [System.Text.Encoding]::UTF8)
      }
    }

    if ($metaLocal) {
      $html = [System.IO.File]::ReadAllText($resolved, [System.Text.Encoding]::UTF8)
      $html = [regex]::Replace($html, '(?s)<helmet>.*?</helmet>', {
        param($m)
        $b = $m.Value
        $b = [regex]::Replace($b, '(?is)[ \t]*<title>.*?</title>\s*\r?\n?', '')
        $b = [regex]::Replace($b, '(?i)[ \t]*<meta\s+name="description"[^>]*>\s*\r?\n?', '')
        $b = [regex]::Replace($b, '(?i)[ \t]*<link\s+rel="canonical"[^>]*>\s*\r?\n?', '')
        $b = [regex]::Replace($b, '(?i)[ \t]*<meta\s+property="og:[^"]*"[^>]*>\s*\r?\n?', '')
        $b = [regex]::Replace($b, '(?i)[ \t]*<meta\s+name="twitter:[^"]*"[^>]*>\s*\r?\n?', '')
        return $b
      })
      $html = $html.Replace("</head>", "`n" + $metaLocal + "</head>")
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
      $res.ContentType = 'text/html; charset=utf-8'
      $res.Headers.Add('Cache-Control', 'no-store')
      $res.StatusCode = 200
      $res.ContentLength64 = $bytes.Length
      if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
      Write-Host "200 $($req.Url.AbsolutePath) (metadata local)"
    }
    elseif ($resolved -and $resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved -PathType Leaf)) {
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
