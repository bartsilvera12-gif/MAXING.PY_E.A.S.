/* MAXING.py — metadatos server-side para fichas y categorías
 *
 * EL PROBLEMA
 * -----------
 * El sitio es una sola página que arma su contenido con JavaScript. Google
 * ejecuta JavaScript, así que ve bien el título, la descripción y los datos
 * estructurados. Los lectores de vista previa de WhatsApp, Facebook y
 * Telegram NO ejecutan JavaScript: leen el HTML crudo, que hasta ahora era
 * idéntico para todas las páginas. Por eso compartir cualquier producto
 * mostraba siempre la tarjeta genérica del sitio.
 *
 * LA SOLUCIÓN
 * -----------
 * Esta función se pone delante de /productos/<slug> y /categorias/<slug>
 * (ver los rewrites en vercel.json), toma el index.html real —el mismo que
 * se sirve siempre, no una copia— y le reescribe la metadata antes de
 * mandarlo. El HTML sigue siendo el de la aplicación: se carga, arranca y
 * navega igual que antes. Lo único que cambia son las etiquetas del
 * encabezado.
 *
 * DÓNDE VIVE HOY LA METADATA
 * --------------------------
 * No está en el <head> del archivo: está dentro del bloque <helmet> del
 * cuerpo, y el runtime la sube al <head> al arrancar. Eso importa por dos
 * razones:
 *
 *   1. El lector de vista previa la encuentra igual (por eso hoy muestra la
 *      tarjeta genérica), así que no alcanza con agregar etiquetas nuevas:
 *      habría dos títulos y dos og:title compitiendo.
 *   2. El runtime AGREGA lo que encuentra en el helmet, nunca lo reemplaza.
 *      Si dejáramos las genéricas ahí, al cargar la página quedarían
 *      duplicadas en el DOM.
 *
 * Por eso la función hace las dos cosas: saca del helmet las etiquetas que
 * va a reemplazar y pone las nuevas en el <head> de verdad. Queda una sola
 * de cada una, en el lugar que corresponde, sin depender de JavaScript.
 *
 * No se toca support.js ni el diseño: esto es una capa de HTML por encima.
 */

const API = "https://api.neura.com.py/rest/v1";
const ANON =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MTAxNDYxLCJleHAiOjE5MzE3ODE0NjF9.7_wAph8IolPMXtgfpezSwS5XR62IdD__qhqCywLDp3Q";
const SITIO = "https://maxingpy.com";
const BUCKET = "maxingpy";
const STORAGE = "https://api.neura.com.py/storage/v1/object/public/" + BUCKET + "/";

/* ------------------------------------------------------------------ */
/* Utilidades                                                          */
/* ------------------------------------------------------------------ */

// Los textos vienen de la base y los edita el cliente. Sin escapar, una
// comilla en el nombre de un producto cierra el atributo y rompe el HTML.
function esc(t) {
  return String(t == null ? "" : t)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// Dentro de un <script> no vale escapar como HTML: el navegador corta el
// bloque en el primer "</script>" literal. Se neutraliza el "<".
function json(obj) {
  return JSON.stringify(obj).replace(/</g, "\\u003c");
}

// Recorta respetando palabras: una descripción cortada al medio de una
// palabra se ve peor en la tarjeta que una un poco más corta.
function recortar(t, max) {
  const s = String(t == null ? "" : t).replace(/\s+/g, " ").trim();
  if (s.length <= max) return s;
  const corte = s.slice(0, max);
  const espacio = corte.lastIndexOf(" ");
  return (espacio > max * 0.6 ? corte.slice(0, espacio) : corte).trim() + "…";
}

// og:image tiene que ser absoluta y pública: WhatsApp la pide desde sus
// propios servidores, no desde el navegador del que comparte. Se replica la
// misma resolución que usa el sitio (js/supabase-client.js).
function imagenAbsoluta(ruta) {
  if (!ruta) return "";
  const r = String(ruta);
  if (/^https?:\/\//i.test(r)) return r;
  if (r.indexOf("storage/") === 0) return STORAGE + r.slice("storage/".length);
  return SITIO + "/" + r.replace(/^\.?\//, "");
}

async function traer(ruta) {
  const r = await fetch(API + ruta, {
    headers: {
      apikey: ANON,
      Authorization: "Bearer " + ANON,
      "Accept-Profile": "maxingpy"
    }
  });
  if (!r.ok) throw new Error("Supabase respondió " + r.status);
  return r.json();
}

/* ------------------------------------------------------------------ */
/* El HTML base                                                        */
/* ------------------------------------------------------------------ */

// Se lee una sola vez por instancia: el archivo no cambia entre pedidos.
let htmlCache = null;

async function htmlBase(req) {
  if (htmlCache) return htmlCache;

  // En Vercel el archivo viaja junto a la función (ver "functions" en
  // vercel.json). Si por lo que sea no estuviera, se lo pide al propio
  // despliegue: /index.html tiene extensión, así que no entra en los
  // rewrites y no puede armar un bucle.
  try {
    const fs = await import("node:fs");
    const path = await import("node:path");
    const candidatos = [
      path.join(process.cwd(), "index.html"),
      path.join(process.cwd(), "public", "index.html")
    ];
    for (const c of candidatos) {
      if (fs.existsSync(c)) {
        htmlCache = fs.readFileSync(c, "utf8");
        return htmlCache;
      }
    }
  } catch (e) {
    /* se prueba por HTTP */
  }

  const host = (req && req.headers && (req.headers["x-forwarded-host"] || req.headers.host)) || "maxingpy.com";
  const proto = host.indexOf("localhost") === 0 ? "http" : "https";
  const r = await fetch(proto + "://" + host + "/index.html");
  if (!r.ok) throw new Error("No se pudo leer index.html (" + r.status + ")");
  htmlCache = await r.text();
  return htmlCache;
}

/* ------------------------------------------------------------------ */
/* Reescritura del HTML                                                */
/* ------------------------------------------------------------------ */

// Saca del bloque <helmet> las etiquetas que la función va a reemplazar.
// Se toca solo ese bloque, no el documento entero: el <head> real tiene sus
// propios <script> y no hay que rozarlos.
function limpiarHelmet(html) {
  return html.replace(/<helmet>[\s\S]*?<\/helmet>/i, (bloque) =>
    bloque
      .replace(/[ \t]*<title>[\s\S]*?<\/title>\s*\n?/gi, "")
      .replace(/[ \t]*<meta\s+name="description"[^>]*>\s*\n?/gi, "")
      .replace(/[ \t]*<link\s+rel="canonical"[^>]*>\s*\n?/gi, "")
      .replace(/[ \t]*<meta\s+property="og:[^"]*"[^>]*>\s*\n?/gi, "")
      .replace(/[ \t]*<meta\s+name="twitter:[^"]*"[^>]*>\s*\n?/gi, "")
  );
}

function bloqueMeta(d) {
  const lineas = [
    "<title>" + esc(d.titulo) + "</title>",
    '<meta name="description" content="' + esc(d.descripcion) + '">',
    '<link rel="canonical" href="' + esc(d.canonica) + '">',
    '<meta property="og:type" content="' + esc(d.tipo) + '">',
    '<meta property="og:site_name" content="MAXING.py">',
    '<meta property="og:locale" content="es_PY">',
    '<meta property="og:title" content="' + esc(d.titulo) + '">',
    '<meta property="og:description" content="' + esc(d.descripcion) + '">',
    '<meta property="og:url" content="' + esc(d.canonica) + '">'
  ];

  if (d.imagen) {
    lineas.push('<meta property="og:image" content="' + esc(d.imagen) + '">');
    lineas.push('<meta property="og:image:alt" content="' + esc(d.imagenAlt || d.titulo) + '">');
  }

  // summary_large_image muestra la foto grande; sin imagen, una tarjeta
  // grande vacía se ve peor que la chica.
  lineas.push('<meta name="twitter:card" content="' + (d.imagen ? "summary_large_image" : "summary") + '">');
  lineas.push('<meta name="twitter:title" content="' + esc(d.titulo) + '">');
  lineas.push('<meta name="twitter:description" content="' + esc(d.descripcion) + '">');
  if (d.imagen) lineas.push('<meta name="twitter:image" content="' + esc(d.imagen) + '">');

  // El id es el mismo que usa el sitio al navegar: así el JavaScript
  // reemplaza el contenido de ESTE nodo en vez de agregar un segundo.
  if (d.grafo && d.grafo.length) {
    lineas.push(
      '<script type="application/ld+json" id="ld-pagina">' +
        json({ "@context": "https://schema.org", "@graph": d.grafo }) +
        "</script>"
    );
  }

  return "\n<!-- Metadata de esta página, puesta por api/pagina.js. -->\n" + lineas.join("\n") + "\n";
}

function armar(html, d) {
  const limpio = limpiarHelmet(html);
  // El </head> siempre existe en index.html; si alguna vez no estuviera, se
  // devuelve el HTML sin tocar antes que uno roto.
  if (limpio.indexOf("</head>") === -1) return html;
  return limpio.replace("</head>", bloqueMeta(d) + "</head>");
}

/* ------------------------------------------------------------------ */
/* Datos de cada tipo de página                                        */
/* ------------------------------------------------------------------ */

const MIGA_INICIO = { "@type": "ListItem", position: 1, name: "Inicio", item: SITIO + "/" };
const MIGA_PRODUCTOS = { "@type": "ListItem", position: 2, name: "Productos", item: SITIO + "/productos" };

async function producto(slug) {
  const campos = [
    "slug,name,sku,short_spec,description,price,stock_status,main_image_url,image_alt",
    "meta_title,meta_description,canonical_url",
    "brand:brands(name)",
    "product_images(image_url,alt_text,sort_order)",
    "product_categories(is_primary,category:categories(slug,name))"
  ].join(",");

  const filas = await traer(
    "/products?select=" + encodeURIComponent(campos) +
    "&slug=eq." + encodeURIComponent(slug) +
    "&is_published=eq.true&limit=1"
  );
  const p = filas && filas[0];
  if (!p) return null;

  const marca = (p.brand && p.brand.name) || "";
  const nombre = [marca, p.name].filter(Boolean).join(" ");
  const url = p.canonical_url || SITIO + "/productos/" + p.slug;

  const parrafos = String(p.description || "")
    .split(/\n\s*\n/)
    .map((x) => x.trim())
    .filter(Boolean);

  const fotos = (p.product_images || [])
    .slice()
    .sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0))
    .map((r) => imagenAbsoluta(r.image_url))
    .filter(Boolean);
  const principal = imagenAbsoluta(p.main_image_url) || fotos[0] || "";

  // "Sin stock" no es lo mismo que "a pedido": el segundo se consigue, y
  // decirle al buscador que no hay espanta una consulta real. Es el mismo
  // criterio que aplica el sitio.
  const disponibilidad =
    p.stock_status === "Sin stock"
      ? "https://schema.org/OutOfStock"
      : p.stock_status === "Bajo pedido"
      ? "https://schema.org/BackOrder"
      : "https://schema.org/InStock";

  const cats = (p.product_categories || [])
    .slice()
    .sort((a, b) => (b.is_primary ? 1 : 0) - (a.is_primary ? 1 : 0));
  const cat = cats.length && cats[0].category ? cats[0].category : null;

  const migas = [MIGA_INICIO, MIGA_PRODUCTOS];
  if (cat) migas.push({ "@type": "ListItem", position: 3, name: cat.name, item: SITIO + "/categorias/" + cat.slug });
  migas.push({ "@type": "ListItem", position: cat ? 4 : 3, name: p.name, item: SITIO + "/productos/" + p.slug });

  const descripcion = recortar(
    p.meta_description || p.short_spec || parrafos[0] || nombre,
    200
  );

  const ficha = {
    "@type": "Product",
    "@id": SITIO + "/productos/" + p.slug + "#product",
    name: nombre,
    description: recortar(parrafos[0] || p.short_spec || nombre, 500),
    image: fotos.length ? fotos : principal ? [principal] : undefined,
    brand: marca ? { "@type": "Brand", name: marca } : undefined,
    offers: {
      "@type": "Offer",
      url: SITIO + "/productos/" + p.slug,
      priceCurrency: "PYG",
      price: String(p.price == null ? 0 : p.price),
      availability: disponibilidad,
      seller: { "@id": SITIO + "/#org" }
    }
  };
  // Sin SKU es mejor omitir la clave que mandarla vacía. No se inventan
  // valoraciones ni reseñas: declarar estrellas que nadie dejó es
  // exactamente lo que Google penaliza.
  if (p.sku) ficha.sku = p.sku;

  return {
    tipo: "product",
    titulo: p.meta_title || nombre + " — MAXING.py",
    descripcion,
    canonica: url,
    imagen: principal,
    // El texto alternativo guardado arranca con "foto: ", que sirve dentro
    // del panel pero se lee raro en una tarjeta compartida. Se describe la
    // imagen con el nombre del producto, igual que hace el sitio.
    imagenAlt: nombre,
    grafo: [
      { "@type": "BreadcrumbList", "@id": SITIO + "/productos/" + p.slug + "#breadcrumb", itemListElement: migas },
      ficha
    ]
  };
}

async function categoria(slug) {
  const campos = "slug,name,short_description,image_url,seo_title,seo_description,canonical_url";
  const filas = await traer(
    "/categories?select=" + encodeURIComponent(campos) +
    "&slug=eq." + encodeURIComponent(slug) +
    "&is_active=eq.true&limit=1"
  );
  const c = filas && filas[0];
  if (!c) return null;

  const url = c.canonical_url || SITIO + "/categorias/" + c.slug;
  const imagen = imagenAbsoluta(c.image_url);

  return {
    tipo: "website",
    titulo: c.seo_title || c.name + " — MAXING.py",
    descripcion: recortar(
      c.seo_description || c.short_description || c.name + " en MAXING.py.",
      200
    ),
    canonica: url,
    imagen,
    imagenAlt: c.name,
    grafo: [
      {
        "@type": "BreadcrumbList",
        "@id": SITIO + "/categorias/" + c.slug + "#breadcrumb",
        itemListElement: [
          MIGA_INICIO,
          MIGA_PRODUCTOS,
          { "@type": "ListItem", position: 3, name: c.name, item: SITIO + "/categorias/" + c.slug }
        ]
      }
    ]
  };
}

async function marca(slug) {
  // "*" en vez de la lista de columnas: si esto se despliega antes de correr
  // la migracion 017, pedir una columna que no existe devuelve un error y la
  // ficha se quedaria sin metadata.
  const filas = await traer(
    "/brands?select=*&slug=eq." + encodeURIComponent(slug) +
    "&is_active=eq.true&limit=1"
  );
  const b = filas && filas[0];
  if (!b) return null;

  const url = b.canonical_url || SITIO + "/marcas/" + b.slug;

  return {
    tipo: "website",
    // "Productos MSI — MAXING.py" dice de qué es la página sin repetir la
    // palabra tres veces, que es lo que un buscador penaliza.
    titulo: b.seo_title || "Productos " + b.name + " — MAXING.py",
    descripcion: recortar(
      b.seo_description || b.description ||
        "Conocé los productos " + b.name + " disponibles en MAXING.py. Consultanos por WhatsApp.",
      200
    ),
    canonica: url,
    // El logo suele ser un PNG chico con fondo transparente: sirve, pero si
    // la marca tiene una imagen propia para compartir, se prefiere esa.
    imagen: imagenAbsoluta(b.og_image_url) || imagenAbsoluta(b.logo_url),
    imagenAlt: b.name,
    grafo: [
      {
        "@type": "BreadcrumbList",
        "@id": SITIO + "/marcas/" + b.slug + "#breadcrumb",
        itemListElement: [
          MIGA_INICIO,
          MIGA_PRODUCTOS,
          { "@type": "ListItem", position: 3, name: b.name, item: SITIO + "/marcas/" + b.slug }
        ]
      }
    ]
  };
}

/* ------------------------------------------------------------------ */

export default async function handler(req, res) {
  const url = new URL(req.url, "http://localhost");
  const tipo = url.searchParams.get("tipo");
  const slug = (url.searchParams.get("slug") || "").trim();

  let html;
  try {
    html = await htmlBase(req);
  } catch (e) {
    // Sin el HTML base no hay nada que servir. Es la única falla que
    // justifica un error: cualquier otra se resuelve con la página genérica.
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.status(500).send("No se pudo leer la página.");
    return;
  }

  let datos = null;
  try {
    if (slug) {
      datos =
        tipo === "categoria" ? await categoria(slug)
        : tipo === "marca" ? await marca(slug)
        : await producto(slug);
    }
  } catch (e) {
    // Si Supabase no responde se sirve la página genérica: el visitante ve
    // el sitio igual y el JavaScript reintenta por su cuenta. Un 500 acá
    // dejaría la ficha inaccesible por un problema de metadatos.
    datos = null;
  }

  if (!datos) {
    // No existe, está despublicado o la categoría está inactiva. Se manda la
    // página tal cual, con su metadata genérica —nunca la del producto
    // oculto— y estado 404 para que el buscador no indexe la dirección. El
    // navegador igual dibuja el sitio y muestra su propio "no encontrado".
    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.setHeader("Cache-Control", "public, max-age=0, s-maxage=60, stale-while-revalidate=600");
    res.setHeader("X-Robots-Tag", "noindex");
    res.status(404).send(html);
    return;
  }

  res.setHeader("Content-Type", "text/html; charset=utf-8");
  // Cinco minutos frescos en el CDN y hasta una hora sirviendo la copia
  // vieja mientras se regenera por detrás. El navegador no la guarda
  // (max-age=0), así que un cambio del panel se ve enseguida al recargar; lo
  // que espera esos minutos es solo la tarjeta de WhatsApp, que igual
  // cachean los propios servidores de Meta durante mucho más tiempo.
  res.setHeader("Cache-Control", "public, max-age=0, s-maxage=300, stale-while-revalidate=3600");
  res.status(200).send(armar(html, datos));
}
