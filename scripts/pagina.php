<?php
/* MAXING.py — metadatos server-side para fichas y categorías (Hostinger)
 *
 * Es la misma idea que api/pagina.js, que corre en Vercel, pero en PHP,
 * porque Hostinger es Apache y no ejecuta funciones de Vercel. Las dos
 * versiones producen el mismo HTML; si se toca una, hay que tocar la otra.
 *
 * EL PROBLEMA
 * -----------
 * El sitio arma su contenido con JavaScript. Google lo ejecuta y ve bien
 * todo. WhatsApp, Facebook y Telegram NO: leen el HTML crudo, que era
 * idéntico para todas las páginas. Por eso compartir cualquier producto
 * mostraba siempre la tarjeta genérica del sitio.
 *
 * CÓMO FUNCIONA
 * -------------
 * El .htaccess manda acá /productos/<slug> y /categorias/<slug>. Este
 * archivo toma el index.html real —el mismo que se sirve siempre—, le
 * reescribe la metadata y lo devuelve. El cuerpo no se toca: la aplicación
 * arranca y navega igual que antes.
 *
 * La metadata no vive en el <head> del archivo sino dentro del bloque
 * <helmet>, y el runtime la sube al <head> al arrancar AGREGÁNDOLA, nunca
 * reemplazándola. Por eso no alcanza con sumar etiquetas: hay que sacar del
 * helmet las que se van a reemplazar y poner las nuevas en el <head> de
 * verdad. Así queda una sola de cada una, antes y después del JavaScript.
 *
 * A PRUEBA DE FALLOS
 * ------------------
 * Ante cualquier problema —Supabase caído, PHP viejo, un error inesperado—
 * se devuelve el index.html tal cual. En el peor caso la vista previa vuelve
 * a ser genérica, pero el sitio nunca queda roto.
 */

$RUTA_HTML = __DIR__ . '/index.html';
$API   = 'https://api.neura.com.py/rest/v1';
$ANON  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MTAxNDYxLCJleHAiOjE5MzE3ODE0NjF9.7_wAph8IolPMXtgfpezSwS5XR62IdD__qhqCywLDp3Q';
$SITIO = 'https://maxing.py';
$STORAGE = 'https://api.neura.com.py/storage/v1/object/public/maxingpy/';

/* ------------------------------------------------------------------ */

// Los textos vienen de la base y los edita el cliente. Sin escapar, una
// comilla en el nombre de un producto cierra el atributo y rompe el HTML.
function mx_esc($t) {
    return htmlspecialchars((string)$t, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

// Dentro de un <script> no vale escapar como HTML: el navegador corta el
// bloque en el primer "</script>" literal. Se neutraliza el "<".
function mx_json($v) {
    $s = json_encode($v, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($s === false) return '{}';
    return str_replace('<', '\\u003c', $s);
}

// Recorta respetando palabras, con acentos: mb_* para no partir un carácter
// de dos bytes al medio.
function mx_recortar($t, $max) {
    $s = trim(preg_replace('/\s+/u', ' ', (string)$t));
    if (function_exists('mb_strlen')) {
        if (mb_strlen($s, 'UTF-8') <= $max) return $s;
        $corte = mb_substr($s, 0, $max, 'UTF-8');
    } else {
        if (strlen($s) <= $max) return $s;
        $corte = substr($s, 0, $max);
    }
    $espacio = strrpos($corte, ' ');
    if ($espacio !== false && $espacio > $max * 0.6) $corte = substr($corte, 0, $espacio);
    return rtrim($corte) . '…';
}

// og:image tiene que ser absoluta y pública: WhatsApp la pide desde sus
// propios servidores, no desde el navegador del que comparte.
function mx_imagen($ruta) {
    global $SITIO, $STORAGE;
    if (!$ruta) return '';
    $r = (string)$ruta;
    if (preg_match('#^https?://#i', $r)) return $r;
    if (strpos($r, 'storage/') === 0) return $STORAGE . substr($r, strlen('storage/'));
    return $SITIO . '/' . preg_replace('#^\./?#', '', $r);
}

function mx_traer($ruta) {
    global $API, $ANON;
    $url = $API . $ruta;
    $cabeceras = array(
        'apikey: ' . $ANON,
        'Authorization: Bearer ' . $ANON,
        'Accept-Profile: maxingpy',
        'Accept: application/json'
    );

    if (function_exists('curl_init')) {
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $cabeceras);
        // Si Supabase tarda, es preferible servir la página genérica a dejar
        // colgado a quien entró desde un enlace.
        curl_setopt($ch, CURLOPT_TIMEOUT, 6);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
        $cuerpo = curl_exec($ch);
        $codigo = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($cuerpo === false || $codigo < 200 || $codigo >= 300) return null;
    } else {
        $ctx = stream_context_create(array('http' => array(
            'method'  => 'GET',
            'header'  => implode("\r\n", $cabeceras),
            'timeout' => 6
        )));
        $cuerpo = @file_get_contents($url, false, $ctx);
        if ($cuerpo === false) return null;
    }

    $datos = json_decode($cuerpo, true);
    return is_array($datos) ? $datos : null;
}

/* ------------------------------------------------------------------ */

function mx_limpiar_helmet($html) {
    return preg_replace_callback('#<helmet>.*?</helmet>#is', function ($m) {
        $b = $m[0];
        $b = preg_replace('#[ \t]*<title>.*?</title>\s*\r?\n?#is', '', $b);
        $b = preg_replace('#[ \t]*<meta\s+name="description"[^>]*>\s*\r?\n?#i', '', $b);
        $b = preg_replace('#[ \t]*<link\s+rel="canonical"[^>]*>\s*\r?\n?#i', '', $b);
        $b = preg_replace('#[ \t]*<meta\s+property="og:[^"]*"[^>]*>\s*\r?\n?#i', '', $b);
        $b = preg_replace('#[ \t]*<meta\s+name="twitter:[^"]*"[^>]*>\s*\r?\n?#i', '', $b);
        return $b;
    }, $html, 1);
}

function mx_bloque($d) {
    $l = array();
    $l[] = '<title>' . mx_esc($d['titulo']) . '</title>';
    $l[] = '<meta name="description" content="' . mx_esc($d['descripcion']) . '">';
    $l[] = '<link rel="canonical" href="' . mx_esc($d['canonica']) . '">';
    $l[] = '<meta property="og:type" content="' . mx_esc($d['tipo']) . '">';
    $l[] = '<meta property="og:site_name" content="MAXING.py">';
    $l[] = '<meta property="og:locale" content="es_PY">';
    $l[] = '<meta property="og:title" content="' . mx_esc($d['titulo']) . '">';
    $l[] = '<meta property="og:description" content="' . mx_esc($d['descripcion']) . '">';
    $l[] = '<meta property="og:url" content="' . mx_esc($d['canonica']) . '">';

    $hayImagen = !empty($d['imagen']);
    if ($hayImagen) {
        $l[] = '<meta property="og:image" content="' . mx_esc($d['imagen']) . '">';
        $l[] = '<meta property="og:image:alt" content="' . mx_esc($d['imagenAlt']) . '">';
    }

    // summary_large_image muestra la foto grande; sin imagen, una tarjeta
    // grande vacía se ve peor que la chica.
    $l[] = '<meta name="twitter:card" content="' . ($hayImagen ? 'summary_large_image' : 'summary') . '">';
    $l[] = '<meta name="twitter:title" content="' . mx_esc($d['titulo']) . '">';
    $l[] = '<meta name="twitter:description" content="' . mx_esc($d['descripcion']) . '">';
    if ($hayImagen) $l[] = '<meta name="twitter:image" content="' . mx_esc($d['imagen']) . '">';

    // El id es el mismo que usa el sitio al navegar: así el JavaScript
    // reemplaza el contenido de ESTE nodo en vez de agregar un segundo.
    if (!empty($d['grafo'])) {
        $l[] = '<script type="application/ld+json" id="ld-pagina">'
             . mx_json(array('@context' => 'https://schema.org', '@graph' => $d['grafo']))
             . '</script>';
    }

    return "\n<!-- Metadata de esta página, puesta por pagina.php. -->\n" . implode("\n", $l) . "\n";
}

/* ------------------------------------------------------------------ */

function mx_producto($slug) {
    global $SITIO;
    $campos = 'slug,name,sku,short_spec,description,price,stock_status,main_image_url,image_alt,'
            . 'meta_title,meta_description,canonical_url,'
            . 'brand:brands(name),'
            . 'product_images(image_url,alt_text,sort_order),'
            . 'product_categories(is_primary,category:categories(slug,name))';

    $filas = mx_traer('/products?select=' . rawurlencode($campos)
        . '&slug=eq.' . rawurlencode($slug) . '&is_published=eq.true&limit=1');
    if (!$filas || !isset($filas[0])) return null;
    $p = $filas[0];

    $marca  = isset($p['brand']['name']) ? $p['brand']['name'] : '';
    $nombre = trim($marca . ' ' . $p['name']);
    $url    = !empty($p['canonical_url']) ? $p['canonical_url'] : $SITIO . '/productos/' . $p['slug'];

    $parrafos = preg_split('/\n\s*\n/', (string)$p['description']);
    $primero  = '';
    foreach ($parrafos as $x) { $x = trim($x); if ($x !== '') { $primero = $x; break; } }

    $fotos = array();
    if (!empty($p['product_images'])) {
        $ims = $p['product_images'];
        usort($ims, function ($a, $b) {
            $x = isset($a['sort_order']) ? $a['sort_order'] : 0;
            $y = isset($b['sort_order']) ? $b['sort_order'] : 0;
            return $x - $y;
        });
        foreach ($ims as $im) {
            $u = mx_imagen($im['image_url']);
            if ($u !== '') $fotos[] = $u;
        }
    }
    $principal = mx_imagen($p['main_image_url']);
    if ($principal === '' && count($fotos)) $principal = $fotos[0];

    // "Sin stock" no es lo mismo que "a pedido": el segundo se consigue, y
    // decirle al buscador que no hay espanta una consulta real. Es el mismo
    // criterio que aplica el sitio.
    if ($p['stock_status'] === 'Sin stock')        $disp = 'https://schema.org/OutOfStock';
    elseif ($p['stock_status'] === 'Bajo pedido')  $disp = 'https://schema.org/BackOrder';
    else                                           $disp = 'https://schema.org/InStock';

    $cat = null;
    if (!empty($p['product_categories'])) {
        foreach ($p['product_categories'] as $pc) {
            if (!empty($pc['category'])) {
                if ($cat === null || !empty($pc['is_primary'])) $cat = $pc['category'];
                if (!empty($pc['is_primary'])) break;
            }
        }
    }

    $migas = array(
        array('@type' => 'ListItem', 'position' => 1, 'name' => 'Inicio',    'item' => $SITIO . '/'),
        array('@type' => 'ListItem', 'position' => 2, 'name' => 'Productos', 'item' => $SITIO . '/productos')
    );
    if ($cat) {
        $migas[] = array('@type' => 'ListItem', 'position' => 3, 'name' => $cat['name'],
                         'item' => $SITIO . '/categorias/' . $cat['slug']);
    }
    $migas[] = array('@type' => 'ListItem', 'position' => $cat ? 4 : 3, 'name' => $p['name'],
                     'item' => $SITIO . '/productos/' . $p['slug']);

    $ficha = array(
        '@type'       => 'Product',
        '@id'         => $SITIO . '/productos/' . $p['slug'] . '#product',
        'name'        => $nombre,
        'description' => mx_recortar($primero !== '' ? $primero : (!empty($p['short_spec']) ? $p['short_spec'] : $nombre), 500),
        'offers'      => array(
            '@type'         => 'Offer',
            'url'           => $SITIO . '/productos/' . $p['slug'],
            'priceCurrency' => 'PYG',
            'price'         => (string)(isset($p['price']) ? $p['price'] : 0),
            'availability'  => $disp,
            'seller'        => array('@id' => $SITIO . '/#org')
        )
    );
    if (count($fotos))          $ficha['image'] = $fotos;
    elseif ($principal !== '')  $ficha['image'] = array($principal);
    if ($marca !== '')          $ficha['brand'] = array('@type' => 'Brand', 'name' => $marca);
    // Sin SKU es mejor omitir la clave que mandarla vacía. No se inventan
    // valoraciones ni reseñas.
    if (!empty($p['sku']))      $ficha['sku'] = $p['sku'];

    $desc = !empty($p['meta_description']) ? $p['meta_description']
          : (!empty($p['short_spec']) ? $p['short_spec'] : ($primero !== '' ? $primero : $nombre));

    return array(
        'tipo'        => 'product',
        'titulo'      => !empty($p['meta_title']) ? $p['meta_title'] : $nombre . ' — MAXING.py',
        'descripcion' => mx_recortar($desc, 200),
        'canonica'    => $url,
        'imagen'      => $principal,
        // El texto alternativo guardado arranca con "foto: ", que sirve dentro
        // del panel pero se lee raro en una tarjeta compartida.
        'imagenAlt'   => $nombre,
        'grafo'       => array(
            array('@type' => 'BreadcrumbList',
                  '@id'   => $SITIO . '/productos/' . $p['slug'] . '#breadcrumb',
                  'itemListElement' => $migas),
            $ficha
        )
    );
}

function mx_categoria($slug) {
    global $SITIO;
    $campos = 'slug,name,short_description,image_url,seo_title,seo_description,canonical_url';
    $filas = mx_traer('/categories?select=' . rawurlencode($campos)
        . '&slug=eq.' . rawurlencode($slug) . '&is_active=eq.true&limit=1');
    if (!$filas || !isset($filas[0])) return null;
    $c = $filas[0];

    $url  = !empty($c['canonical_url']) ? $c['canonical_url'] : $SITIO . '/categorias/' . $c['slug'];
    $desc = !empty($c['seo_description']) ? $c['seo_description']
          : (!empty($c['short_description']) ? $c['short_description'] : $c['name'] . ' en MAXING.py.');

    return array(
        'tipo'        => 'website',
        'titulo'      => !empty($c['seo_title']) ? $c['seo_title'] : $c['name'] . ' — MAXING.py',
        'descripcion' => mx_recortar($desc, 200),
        'canonica'    => $url,
        'imagen'      => mx_imagen($c['image_url']),
        'imagenAlt'   => $c['name'],
        'grafo'       => array(
            array('@type' => 'BreadcrumbList',
                  '@id'   => $SITIO . '/categorias/' . $c['slug'] . '#breadcrumb',
                  'itemListElement' => array(
                      array('@type' => 'ListItem', 'position' => 1, 'name' => 'Inicio',    'item' => $SITIO . '/'),
                      array('@type' => 'ListItem', 'position' => 2, 'name' => 'Productos', 'item' => $SITIO . '/productos'),
                      array('@type' => 'ListItem', 'position' => 3, 'name' => $c['name'],  'item' => $SITIO . '/categorias/' . $c['slug'])
                  ))
        )
    );
}

/* ------------------------------------------------------------------ */

$html = @file_get_contents($RUTA_HTML);
if ($html === false) {
    // Sin el HTML base no hay nada que servir.
    header('Content-Type: text/plain; charset=utf-8');
    http_response_code(500);
    echo 'No se pudo leer la página.';
    exit;
}

$tipo = isset($_GET['tipo']) ? $_GET['tipo'] : '';
$slug = isset($_GET['slug']) ? trim($_GET['slug']) : '';

$datos = null;
try {
    if ($slug !== '') {
        $datos = ($tipo === 'categoria') ? mx_categoria($slug) : mx_producto($slug);
    }
} catch (Throwable $e) {
    // Si algo falla se sirve la página genérica: el visitante ve el sitio
    // igual y el JavaScript trae los datos por su cuenta.
    $datos = null;
}

header('Content-Type: text/html; charset=utf-8');

if ($datos === null) {
    // No existe, está despublicado o la categoría está inactiva. Se manda la
    // página tal cual, con su metadata genérica —nunca la del producto
    // oculto— y estado 404 para que el buscador no indexe la dirección.
    header('Cache-Control: public, max-age=0, s-maxage=60');
    header('X-Robots-Tag: noindex');
    http_response_code(404);
    echo $html;
    exit;
}

// Cinco minutos frescos en cualquier caché intermedia. El navegador no la
// guarda (max-age=0), así que un cambio del panel se ve al recargar.
header('Cache-Control: public, max-age=0, s-maxage=300, stale-while-revalidate=3600');

$limpio = mx_limpiar_helmet($html);
$pos = strpos($limpio, '</head>');
if ($limpio === null || $pos === false) {
    // Si el reemplazo no salió como se esperaba, se manda el original antes
    // que un HTML a medio armar.
    echo $html;
    exit;
}
echo substr($limpio, 0, $pos) . mx_bloque($datos) . substr($limpio, $pos);
