/* MAXING.py — carga de datos del sitio publico
 *
 * Una sola funcion, `MaxingData.cargar()`, trae todo lo que la pagina
 * necesita en 8 requests paralelos y devuelve los datos con la MISMA forma
 * que tenian los arrays escritos a mano en index.html:
 *
 *   { brand, name, spec, price, oldPrice, badge, cats, stock, sku,
 *     foto, img, desc, features, id, slug }
 *
 * Mantener la forma es deliberado: permite cambiar el origen de los datos
 * sin tocar el render, que es la parte del sitio que ya esta probada y que
 * el cliente pidio no rediseñar.
 *
 * Se evita el problema N+1 pidiendo las relaciones embebidas en la misma
 * consulta de productos, en vez de una consulta por producto.
 */
(function () {
  "use strict";

  var db = window.MaxingDB;
  if (!db) throw new Error("Falta js/supabase-client.js antes de js/data-api.js");

  // Los productos vienen con marca, categorias y caracteristicas embebidas.
  var SELECT_PRODUCTOS = [
    "id, slug, sku, name, short_spec, description, price, old_price",
    "is_on_sale, discount_percent, stock_status, main_image_url, image_alt",
    // Las columnas og_ no se piden: el sitio tiene sus etiquetas og: fijas en
    // el encabezado y nunca las leyo. Traerlas era peso muerto en cada carga.
    "meta_title, meta_description, canonical_url",
    "is_featured, sort_order",
    "brand:brands(id, slug, name, logo_url)",
    "product_categories(category:categories(slug, name))",
    "product_features(feature, sort_order)",
    "product_images(image_url, alt_text, sort_order)",
    "relaciones:product_relations!product_relations_product_id_fkey(related_product_id, relation_type, sort_order)"
  ].join(", ");

  function porOrden(a, b) {
    return (a.sort_order || 0) - (b.sort_order || 0);
  }

  // De la fila de Postgres a la forma que ya usa el render.
  function armarProducto(f) {
    var cats = (f.product_categories || [])
      .map(function (r) {
        return r.category && r.category.name;
      })
      .filter(Boolean);

    var features = (f.product_features || []).slice().sort(porOrden).map(function (r) {
      return r.feature;
    });

    var galeria = (f.product_images || []).slice().sort(porOrden).map(function (r) {
      return { url: db.imagen(r.image_url), alt: r.alt_text || "" };
    });

    // La descripcion se guarda como un texto con parrafos separados por
    // linea en blanco; el render espera un array de parrafos.
    var desc = (f.description || "")
      .split(/\n\s*\n/)
      .map(function (p) {
        return p.trim();
      })
      .filter(Boolean);

    var precio = Number(f.price) || 0;
    var precioViejo = f.old_price == null ? null : Number(f.old_price);

    return {
      id: f.id,
      slug: f.slug,
      sku: f.sku || "",
      brand: (f.brand && f.brand.name) || "",
      brandSlug: (f.brand && f.brand.slug) || "",
      name: f.name || "",
      spec: f.short_spec || "",
      price: precio,
      oldPrice: precioViejo,
      // La etiqueta de oferta se calcula, no se escribe a mano: sale de
      // discount_percent, que Postgres deriva de old_price y price.
      badge: f.is_on_sale && f.discount_percent ? "-" + f.discount_percent + "%" : "",
      enOferta: !!f.is_on_sale,
      cats: cats,
      stock: f.stock_status || "Disponible",
      foto: f.main_image_url ? db.imagen(f.main_image_url) : "",
      img: f.image_alt || f.name || "",
      galeria: galeria,
      // Solo los ids: los productos completos ya vienen en la misma carga, y
      // se resuelven contra el indice para no pedirlos de nuevo.
      relacionados: (f.relaciones || []).slice().sort(porOrden).map(function (r) {
        return { id: r.related_product_id, tipo: r.relation_type };
      }),
      desc: desc,
      features: features,
      metaTitulo: f.meta_title || "",
      metaDescripcion: f.meta_description || "",
      canonica: f.canonical_url || "",
      destacado: !!f.is_featured,
      orden: f.sort_order || 0
    };
  }

  function armarCategoria(f) {
    return {
      id: f.id,
      slug: f.slug,
      name: f.name,
      count: f.short_description || "",
      foto: f.image_url ? db.imagen(f.image_url) : "",
      icono: f.icon_svg || "",
      color: f.color || "#40DF36",
      ink: f.ink_color || "#24801C",
      seoTitulo: f.seo_title || "",
      seoDescripcion: f.seo_description || "",
      canonica: f.canonical_url || "",
      img: "foto: " + f.name
    };
  }

  // site_settings es clave/valor: se convierte a un objeto con los tipos ya
  // resueltos, para que quien lo use no tenga que parsear "true".
  function armarAjustes(filas) {
    var out = {};
    (filas || []).forEach(function (f) {
      var v = f.value;
      if (f.value_type === "boolean") v = v === "true" || v === "t" || v === "1";
      else if (f.value_type === "number") v = v === null || v === "" ? null : Number(v);
      else if (f.value_type === "json") {
        try {
          v = JSON.parse(v);
        } catch (e) {
          v = null;
        }
      }
      out[f.key] = v;
    });
    return out;
  }

  window.MaxingData = {
    cargar: function () {
      return Promise.all([
        db.from("products").select(SELECT_PRODUCTOS).eq("is_published", true).order("sort_order"),
        db.from("categories").select("id, slug, name, short_description, image_url, icon_svg, color, ink_color, sort_order, seo_title, seo_description, canonical_url").eq("is_active", true).order("sort_order"),
        // Con "*" y no con la lista de columnas a proposito: si el sitio se
        // sube antes de correr la migracion 017, pedir description o seo_title
        // devolveria un error y se caeria la carga entera. Asi, las columnas
        // que todavia no existen simplemente no vienen.
        db.from("brands").select("*").eq("is_active", true).order("sort_order"),
        db.from("collections").select("id, slug, name, description, anchor_id, is_automatic, auto_rule, max_items, sort_order, product_collections(product_id, sort_order)").eq("is_active", true).order("sort_order"),
        db.from("hero_slides").select("*").eq("is_active", true).order("sort_order"),
        db.from("content_sections").select("*").eq("is_visible", true).order("sort_order"),
        db.from("benefits").select("*").eq("is_active", true).order("sort_order"),
        db.from("footer_items").select("*").eq("is_active", true).order("sort_order"),
        db.from("social_links").select("*").eq("is_active", true).order("sort_order"),
        db.from("site_settings").select("key, value, value_type, group_key"),
        db.from("seo_pages").select("*"),
        db.from("faqs").select("id, faq_category_id, question, answer, sort_order, faq_product_categories(category_id), faq_products(product_id)").eq("is_active", true).order("sort_order")
      ]).then(function (r) {
        // Si falla la consulta de productos no hay sitio que mostrar; el
        // resto degrada a vacio sin romper la pagina.
        var fallo = r.find(function (x) {
          return x.error;
        });
        if (r[0].error) {
          return { ok: false, error: r[0].error };
        }

        var secciones = {};
        (r[5].data || []).forEach(function (s) {
          secciones[s.section_key] = s;
        });

        var seo = {};
        (r[10].data || []).forEach(function (s) {
          seo[s.page_key] = s;
        });

        var redes = {};
        (r[8].data || []).forEach(function (s) {
          redes[s.platform] = s;
        });

        var pie = { operativo: [], columnas: {} };
        (r[7].data || []).forEach(function (f) {
          if (f.group_key === "operativo") pie.operativo.push(f);
          else {
            if (!pie.columnas[f.group_key]) {
              pie.columnas[f.group_key] = { label: f.group_label, items: [] };
            }
            pie.columnas[f.group_key].items.push(f);
          }
        });

        return {
          ok: true,
          // `fallo` no bloquea, pero se reporta: sirve para ver en consola
          // que una tabla secundaria no cargo.
          aviso: fallo && !r[0].error ? fallo.error : null,
          productos: (r[0].data || []).map(armarProducto),
          categorias: (r[1].data || []).map(armarCategoria),
          marcas: (r[2].data || []).map(function (f) {
            return {
              id: f.id,
              slug: f.slug,
              name: f.name,
              logo: f.logo_url ? db.imagen(f.logo_url) : "",
              // La marca tiene pagina propia (/marcas/<slug>): necesita su
              // texto y su SEO, no solo el logo del carrusel.
              descripcion: f.description || "",
              seoTitulo: f.seo_title || "",
              seoDescripcion: f.seo_description || "",
              canonica: f.canonical_url || "",
              ogImagen: f.og_image_url ? db.imagen(f.og_image_url) : ""
            };
          }),
          colecciones: r[3].data || [],
          hero: (r[4].data || [])[0] || null,
          secciones: secciones,
          beneficios: r[6].data || [],
          pie: pie,
          redes: redes,
          ajustes: armarAjustes(r[9].data),
          seo: seo,
          // Los temas agrupan las preguntas dentro del panel; el sitio las
          // muestra juntas, asi que no hace falta traerlos.
          //
          // Una pregunta sin respuesta no se muestra: RLS ya las filtra, esto
          // cubre el caso de un espacio en blanco.
          faqs: (r[11].data || []).filter(function (f) {
            return f.answer && f.answer.trim();
          }).map(function (f) {
            return {
              id: f.id,
              tema: f.faq_category_id,
              question: f.question,
              answer: f.answer,
              categorias: (f.faq_product_categories || []).map(function (x) { return x.category_id; }),
              productos: (f.faq_products || []).map(function (x) { return x.product_id; })
            };
          })
        };
      });
    },

    // Hash del estado del contenido. Sirve para saber si el panel cambió
    // algo sin volver a bajar todo el catalogo. Devuelve null si la funcion
    // todavia no existe en la base (migracion 007 sin correr), y en ese caso
    // el sitio se limita a recargar cuando el visitante vuelve a la pestaña.
    version: function () {
      return db.rpc("contenido_version").then(function (r) {
        return r.error ? null : r.data;
      });
    },

    // Resuelve una coleccion a la lista de productos que le toca, ya sea
    // por regla automatica o por el curado manual del panel.
    productosDe: function (coleccion, productos) {
      if (!coleccion) return [];
      var tope = coleccion.max_items || 8;

      if (coleccion.is_automatic) {
        var lista = productos.slice();
        if (coleccion.auto_rule === "on_sale") {
          lista = lista.filter(function (p) {
            return p.enOferta;
          });
        } else if (coleccion.auto_rule === "newest") {
          // `sort_order` mas alto = cargado despues.
          lista = lista.slice().sort(function (a, b) {
            return b.orden - a.orden;
          });
        } else if (coleccion.auto_rule === "featured") {
          lista = lista.filter(function (p) {
            return p.destacado;
          });
        }
        return lista.slice(0, tope);
      }

      // Curada: se respeta el orden que fijo el panel.
      var enlaces = (coleccion.product_collections || []).slice().sort(porOrden);
      var porId = {};
      productos.forEach(function (p) {
        porId[p.id] = p;
      });
      return enlaces
        .map(function (e) {
          return porId[e.product_id];
        })
        .filter(Boolean)
        .slice(0, tope);
    }
  };
})();
