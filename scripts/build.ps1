# MAXING.py — arma el paquete para subir a Hostinger.
#
# Deja todo en dist/, igual que el resto de los proyectos. La diferencia es
# que este sitio no tiene bundler: es HTML estático, así que el "build" es
# copiar lo que se publica y resolver las dos cosas que en Vercel hacía la
# plataforma y en Hostinger no existen:
#
#   1. Los rewrites de vercel.json  ->  .htaccess (Apache)
#   2. /api/sitemap, que es una función serverless  ->  sitemap.xml estático
#      generado acá, leyendo el catálogo de Supabase
#
# Uso:  powershell -ExecutionPolicy Bypass -File scripts\build.ps1
#       ...\build.ps1 -Zip        # además arma dist.zip para arrastrar al hPanel

param(
  [switch]$Zip,
  [string]$Sitio = "https://maxingpy.com"
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $raiz 'dist'

Write-Host "MAXING.py -> dist/" -ForegroundColor Green

# ---------------------------------------------------------------------
# 1. Limpiar
# ---------------------------------------------------------------------
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Path $dist | Out-Null

# ---------------------------------------------------------------------
# 2. Copiar lo que se publica
# ---------------------------------------------------------------------
# Lo que NO va: el artboard editable (MAXING Home.dc.html), las migraciones,
# la función serverless de Vercel, su configuración, el README y las
# herramientas de .claude/. Nada de eso lo sirve Hostinger.
$archivos = @(
  'index.html', 'support.js', 'politicadeprivacidad.html', 'politicas-comerciales.html', 'robots.txt',
  'favicon.ico', 'favicon.svg', 'apple-touch-icon.png',
  'hero.jpg', 'setup.jpg', 'nosotros.jpg', 'seccion.jpg'
)
$carpetas = @('js', 'admin', 'productos', 'categorias', 'marcas')

foreach ($a in $archivos) {
  $origen = Join-Path $raiz $a
  if (Test-Path $origen) {
    Copy-Item $origen -Destination $dist
  } else {
    Write-Host "  falta: $a" -ForegroundColor Yellow
  }
}

foreach ($c in $carpetas) {
  $origen = Join-Path $raiz $c
  if (Test-Path $origen) {
    Copy-Item $origen -Destination $dist -Recurse
  } else {
    Write-Host "  falta la carpeta: $c" -ForegroundColor Yellow
  }
}

# ---------------------------------------------------------------------
# 3. sitemap.xml
# ---------------------------------------------------------------------
# En Vercel lo genera api/sitemap.js en cada pedido. Hostinger no ejecuta
# Node, así que se congela acá: hay que volver a correr el build cuando se
# agreguen productos para que aparezcan en el sitemap.
function Escapar([string]$t) {
  return ($t -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;')
}

function Url([string]$loc, [string]$fecha, [string]$frec, [string]$prio) {
  $lm = ''
  if ($fecha) { $lm = "    <lastmod>$($fecha.Substring(0,10))</lastmod>`n" }
  return "  <url>`n    <loc>$(Escapar $loc)</loc>`n$lm    <changefreq>$frec</changefreq>`n    <priority>$prio</priority>`n  </url>"
}

$config = Get-Content (Join-Path $raiz 'js\config.js') -Raw
$api = [regex]::Match($config, 'SUPABASE_URL:\s*"([^"]+)"').Groups[1].Value
$anon = [regex]::Match($config, 'SUPABASE_ANON_KEY:\s*\r?\n?\s*"([^"]+)"').Groups[1].Value

$urls = New-Object System.Collections.Generic.List[string]
$urls.Add((Url "$Sitio/" '' 'daily' '1.0'))
$urls.Add((Url "$Sitio/productos" '' 'daily' '0.9'))
$urls.Add((Url "$Sitio/nosotros" '' 'monthly' '0.5'))

try {
  $cab = @{ apikey = $anon; Authorization = "Bearer $anon"; 'Accept-Profile' = 'maxingpy' }
  $rest = "$api/rest/v1"

  $productos = Invoke-RestMethod -Uri "$rest/products?select=slug,updated_at,brand_id&is_published=eq.true&order=updated_at.desc" -Headers $cab -TimeoutSec 25
  $categorias = Invoke-RestMethod -Uri "$rest/categories?select=id,slug,updated_at&is_active=eq.true&order=sort_order" -Headers $cab -TimeoutSec 25
  $relaciones = Invoke-RestMethod -Uri "$rest/product_categories?select=category_id" -Headers $cab -TimeoutSec 25
  $marcas = Invoke-RestMethod -Uri "$rest/brands?select=id,slug,updated_at&is_active=eq.true&order=sort_order" -Headers $cab -TimeoutSec 25

  # Una categoría sin productos publicados no se muestra en el sitio: mandar
  # al buscador ahí sería mandarlo a una página vacía.
  $conProductos = @{}
  foreach ($r in $relaciones) { $conProductos[$r.category_id] = $true }

  foreach ($c in $categorias) {
    if ($conProductos.ContainsKey($c.id)) {
      $urls.Add((Url "$Sitio/categorias/$($c.slug)" $c.updated_at 'weekly' '0.8'))
    }
  }
  # Lo mismo con las marcas: una sin productos publicados tendría su página
  # vacía, así que no se manda al buscador.
  $conMarca = @{}
  foreach ($p in $productos) { if ($p.brand_id) { $conMarca[$p.brand_id] = $true } }

  foreach ($b in $marcas) {
    if ($conMarca.ContainsKey($b.id)) {
      $urls.Add((Url "$Sitio/marcas/$($b.slug)" $b.updated_at 'weekly' '0.7'))
    }
  }
  foreach ($p in $productos) {
    $urls.Add((Url "$Sitio/productos/$($p.slug)" $p.updated_at 'weekly' '0.7'))
  }

  $nCat = ($categorias | Where-Object { $conProductos.ContainsKey($_.id) }).Count
  $nMar = ($marcas | Where-Object { $conMarca.ContainsKey($_.id) }).Count
  Write-Host "  sitemap: $($urls.Count) URLs ($($productos.Count) productos, $nCat categorias, $nMar marcas)"
} catch {
  # Sin conexión queda el sitemap mínimo. Se avisa fuerte porque subir así
  # deja el catálogo entero fuera del buscador.
  Write-Host "  AVISO: no se pudo leer Supabase, el sitemap sale con 3 URLs" -ForegroundColor Red
  Write-Host "         $($_.Exception.Message)" -ForegroundColor DarkGray
}

$sitemap = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n" +
           ($urls -join "`n") + "`n</urlset>`n"
[System.IO.File]::WriteAllText((Join-Path $dist 'sitemap.xml'), $sitemap, (New-Object System.Text.UTF8Encoding $false))

# pagina.php: la contraparte de api/pagina.js para Apache. Genera la metadata
# de cada ficha y cada categoría del lado del servidor, que es lo único que
# leen WhatsApp y Facebook. Va en la raíz porque busca index.html al lado.
Copy-Item (Join-Path $PSScriptRoot 'pagina.php') (Join-Path $dist 'pagina.php') -Force

# ---------------------------------------------------------------------
# 4. .htaccess
# ---------------------------------------------------------------------
# Traduce a Apache los rewrites de vercel.json. Sin esto, entrar directo a
# /productos/msi-katana-15 da 404: ese archivo no existe, la ruta la resuelve
# index.html leyendo la URL.
$htaccess = @'
# MAXING.py — sitio estático sobre Apache (Hostinger).
#
# Traduce los rewrites de vercel.json. El catálogo lo sirve Supabase desde el
# navegador. Lo único que corre del lado del servidor es pagina.php, que arma
# la metadata de cada ficha y cada categoría para los lectores de vista previa
# de WhatsApp y Facebook, que no ejecutan JavaScript.

# Que el indice de una carpeta sea index.html. Panel Hito lo dejo anotado
# despues de pelearse con esto: algunos Hostinger sirven index.txt si no se
# les dice.
DirectoryIndex index.html

# Sin listados de carpeta: entrar a /categorias mostraba los archivos.
Options -Indexes

<IfModule mod_rewrite.c>
  RewriteEngine On

  # Un archivo que existe se sirve tal cual: las fotos de /productos y de
  # /categorias tienen que ganarle a las rutas de más abajo.
  RewriteCond %{REQUEST_FILENAME} -f
  RewriteRule ^ - [L]

  # Páginas sueltas con ruta amigable.
  RewriteRule ^politicadeprivacidad/?$ /politicadeprivacidad.html [L]
  RewriteRule ^politicas-comerciales/?$ /politicas-comerciales.html [L]
  RewriteRule ^admin/login/?$ /admin/login.html [L]
  RewriteRule ^admin/?$ /admin/index.html [L]

  # Fichas y categorías: pasan por pagina.php, que arma la metadata de esa
  # página antes de mandar el HTML. Es lo que hace que compartir un producto
  # por WhatsApp muestre su foto y su nombre y no la tarjeta genérica del
  # sitio: los lectores de vista previa no ejecutan JavaScript.
  RewriteRule ^productos/([^/]+)/?$ /pagina.php?tipo=producto&slug=$1 [L,QSA]
  RewriteRule ^categorias/([^/]+)/?$ /pagina.php?tipo=categoria&slug=$1 [L,QSA]
  RewriteRule ^marcas/([^/]+)/?$ /pagina.php?tipo=marca&slug=$1 [L,QSA]

  # El resto de las rutas las resuelve index.html leyendo la URL. Van ANTES
  # del corte por carpeta: /productos y /categorias son además las carpetas
  # donde viven las fotos, así que sin esto Apache servía la carpeta en vez
  # de la página y el catálogo daba 404.
  RewriteRule ^(productos|categorias|marcas)/?$ /index.html [L]
  RewriteRule ^(nosotros|favoritos|lista-de-consulta)/?$ /index.html [L]

  # Cualquier otra carpeta real se sirve tal cual.
  RewriteCond %{REQUEST_FILENAME} -d
  RewriteRule ^ - [L]
</IfModule>

# El panel no se indexa nunca.
<IfModule mod_headers.c>
  <FilesMatch "^(index|login)\.html$">
    Header set Referrer-Policy "same-origin"
  </FilesMatch>
</IfModule>

# Cacheo: el HTML se revalida siempre, para que un cambio se vea al recargar.
<IfModule mod_headers.c>
  <FilesMatch "\.html$">
    Header set Cache-Control "no-cache, must-revalidate"
  </FilesMatch>

  <FilesMatch "\.(js|css|woff2)$">
    Header set Cache-Control "public, max-age=604800"
  </FilesMatch>

  # Las imágenes se reemplazan desde el panel conservando el nombre, así que
  # no se cachean a ciegas. 'no-cache' no significa "no guardar": el navegador
  # la guarda igual pero pregunta antes de usarla, así una foto sin cambios no
  # se vuelve a descargar y una reemplazada se ve al instante.
  <FilesMatch "\.(jpg|jpeg|png|webp|svg|ico)$">
    Header set Cache-Control "no-cache"
  </FilesMatch>

  <FilesMatch "^sitemap\.xml$">
    Header set Cache-Control "no-cache"
  </FilesMatch>
</IfModule>

# Compresión de texto. Las imágenes y las woff2 no se listan: ya vienen
# comprimidas y volver a comprimirlas solo gasta CPU.
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/css text/javascript
  AddOutputFilterByType DEFLATE application/javascript application/json
  AddOutputFilterByType DEFLATE application/xml image/svg+xml
</IfModule>
'@

[System.IO.File]::WriteAllText((Join-Path $dist '.htaccess'), $htaccess, (New-Object System.Text.UTF8Encoding $false))

# El panel no se indexa: se refuerza con su propio .htaccess, porque el
# X-Robots-Tag de vercel.json no viaja al paquete.
$htAdmin = @'
# El panel de administracion no se indexa nunca.
<IfModule mod_headers.c>
  Header set X-Robots-Tag "noindex, nofollow"
  Header set X-Frame-Options "DENY"

  # El .htaccess de la raiz cachea el JS una semana, que esta bien para la
  # vidriera pero no para el panel: un arreglo se subia y el administrador
  # seguia viendo el codigo viejo. Aca se pisa esa regla. "no-cache" no es
  # "no guardar": el navegador guarda igual pero pregunta antes de usarlo.
  <FilesMatch "\.(js|css|html)$">
    Header set Cache-Control "no-cache"
  </FilesMatch>
</IfModule>
'@
[System.IO.File]::WriteAllText((Join-Path $dist 'admin\.htaccess'), $htAdmin, (New-Object System.Text.UTF8Encoding $false))

# ---------------------------------------------------------------------
# 5. Resumen
# ---------------------------------------------------------------------
$total = (Get-ChildItem $dist -Recurse -File).Count
$peso = [math]::Round(((Get-ChildItem $dist -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 2)
Write-Host "  $total archivos, $peso MB" -ForegroundColor Green

if ($Zip) {
  $zipPath = Join-Path $raiz 'dist.zip'
  if (Test-Path $zipPath) { Remove-Item $zipPath }
  # -Force para que entren los archivos que empiezan con punto (.htaccess).
  Compress-Archive -Path (Join-Path $dist '*') -DestinationPath $zipPath -Force
  $mb = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
  Write-Host "  dist.zip listo ($mb MB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Subir el CONTENIDO de dist/ a public_html en Hostinger." -ForegroundColor Cyan
Write-Host "Importante: incluir los .htaccess, que el explorador suele ocultar." -ForegroundColor Cyan
