/* MAXING.py — sitemap.xml generado desde la base
 *
 * Es una función serverless de Vercel: /sitemap.xml se reescribe hacia acá
 * (ver vercel.json). Se genera en cada pedido en vez de ser un archivo fijo
 * porque el catálogo lo administra el cliente: un sitemap escrito a mano
 * queda desactualizado el primer día que carga un producto.
 *
 * Incluye:
 *   - el inicio y las páginas fijas
 *   - las categorías activas que tengan al menos un producto publicado
 *   - todos los productos publicados
 *
 * Usa la anon key, que solo ve lo publicado. Es exactamente lo que un
 * buscador debería encontrar, así que no hace falta nada con más permisos.
 */

const API = "https://api.neura.com.py/rest/v1";
const ANON =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MTAxNDYxLCJleHAiOjE5MzE3ODE0NjF9.7_wAph8IolPMXtgfpezSwS5XR62IdD__qhqCywLDp3Q";
const SITIO = "https://maxing.py";

async function traer(ruta) {
  const r = await fetch(API + ruta, {
    headers: {
      apikey: ANON,
      Authorization: "Bearer " + ANON,
      "Accept-Profile": "maxingpy"
    }
  });
  if (!r.ok) throw new Error("Supabase respondió " + r.status + " en " + ruta);
  return r.json();
}

// Un & o un < sin escapar rompe el XML entero.
function xml(t) {
  return String(t || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function url(loc, fecha, frecuencia, prioridad) {
  return (
    "  <url>\n" +
    "    <loc>" + xml(loc) + "</loc>\n" +
    (fecha ? "    <lastmod>" + fecha.slice(0, 10) + "</lastmod>\n" : "") +
    "    <changefreq>" + frecuencia + "</changefreq>\n" +
    "    <priority>" + prioridad + "</priority>\n" +
    "  </url>"
  );
}

export default async function handler(req, res) {
  try {
    const [productos, categorias, relaciones] = await Promise.all([
      traer("/products?select=slug,updated_at&is_published=eq.true&order=updated_at.desc"),
      traer("/categories?select=id,slug,updated_at&is_active=eq.true&order=sort_order"),
      traer("/product_categories?select=category_id")
    ]);

    // Una categoría sin productos publicados no se muestra en el sitio, así
    // que tampoco va al sitemap: mandaría al buscador a una página vacía.
    const conProductos = new Set(relaciones.map((r) => r.category_id));

    const partes = [
      url(SITIO + "/", null, "daily", "1.0"),
      url(SITIO + "/productos", null, "daily", "0.9"),
      url(SITIO + "/nosotros", null, "monthly", "0.5")
    ];

    categorias
      .filter((c) => conProductos.has(c.id))
      .forEach((c) => partes.push(url(SITIO + "/categorias/" + c.slug, c.updated_at, "weekly", "0.8")));

    productos.forEach((p) =>
      partes.push(url(SITIO + "/productos/" + p.slug, p.updated_at, "weekly", "0.7"))
    );

    const cuerpo =
      '<?xml version="1.0" encoding="UTF-8"?>\n' +
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
      partes.join("\n") +
      "\n</urlset>\n";

    res.setHeader("Content-Type", "application/xml; charset=utf-8");
    // Una hora en el CDN: el catálogo no cambia tan seguido, y así una
    // ráfaga de rastreo no golpea Supabase en cada pedido.
    res.setHeader("Cache-Control", "public, max-age=0, s-maxage=3600");
    res.status(200).send(cuerpo);
  } catch (e) {
    // Si la base no responde, se devuelve un sitemap mínimo válido en vez de
    // un error: es preferible que el buscador encuentre el inicio a que se
    // lleve un 500 y deje de pedirlo.
    res.setHeader("Content-Type", "application/xml; charset=utf-8");
    res.status(200).send(
      '<?xml version="1.0" encoding="UTF-8"?>\n' +
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
        url(SITIO + "/", null, "daily", "1.0") +
        "\n</urlset>\n"
    );
  }
}
