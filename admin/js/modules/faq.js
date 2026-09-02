/* MAXING.py — modulo Preguntas frecuentes
 *
 * Dos pantallas: los temas (Envios, Garantias...) y las preguntas.
 *
 * Una pregunta sin respuesta NO se publica: el sitio la filtra y la base
 * tambien. Asi se pueden ir anotando preguntas pendientes sin que aparezcan
 * a medias en la web.
 *
 * Por defecto una pregunta es general y sale en el inicio. Si se le marcan
 * categorias, deja de ser general y aparece solo en esas: una pregunta sobre
 * bateria tiene sentido en Notebooks y no en Monitores.
 */
(function () {
  "use strict";

  var h = UI.h;

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "faq-temas",
    titulo: "Temas de FAQ",
    sub: "Para encontrarlas en el panel, no salen en el sitio",
    grupo: "Contenido",
    singular: "Tema",
    contadorSingular: "tema",
    contadorPlural: "temas",
    icono: '<path d="M3 7h18"/><path d="M3 12h18"/><path d="M3 17h12"/>',
    tabla: "faq_categories",
    nota:
      "Los temas son para ordenar las preguntas acá adentro: en el sitio no aparecen como títulos, " +
      "las preguntas se muestran todas juntas en una sola lista.",
    vacio: "Creá el primer tema.",

    columnas: [
      { label: "Tema", render: celda.principal("name", "slug") },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Activo", "Oculto") }
    ],

    campos: [
      { k: "name", label: "Nombre", grupo: "Identificación", placeholder: "Envíos" },
      {
        k: "slug", label: "Slug", grupo: "Identificación",
        desde: "name",
        pista: "Se escribe solo desde el nombre.",
        placeholder: "envios"
      },
      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Tema activo", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.name) return "Falta el nombre.";
      if (!d.slug) return "Falta el slug.";
      if (!/^[a-z0-9-]+$/.test(d.slug)) return "El slug solo puede tener minúsculas, números y guiones.";
      return null;
    }
  });

  /* ---------------------------------------------------------------- */
  // Se cargan una vez y se reusan para los selectores.
  var temas = [];
  var categorias = [];
  var catalogo = [];

  crudSimple({
    clave: "faqs",
    titulo: "Preguntas frecuentes",
    sub: "Las que se muestran en el sitio",
    grupo: "Contenido",
    singular: "Pregunta",
    contadorSingular: "pregunta",
    contadorPlural: "preguntas",
    icono: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3 2.45V13"/><path d="M12 16.5h.01"/>',
    tabla: "faqs",
    // Los selectores necesitan los temas y las categorias del catalogo.
    preparar: async function (app) {
      temas = (await sb.from("faq_categories").select("id, name").order("sort_order")).data || [];
      categorias = await app.categorias();
      // Catalogo liviano para el buscador: lo justo para reconocer un
      // producto y poder buscarlo por nombre, codigo o marca.
      catalogo = (await sb
        .from("products")
        .select("id, name, sku, price, main_image_url, brand:brands(name)")
        .order("name")).data || [];
    },
    select: "*, faq_product_categories(category_id), faq_products(product_id)",
    orden: ["sort_order"],
    nota:
      "Una pregunta sin respuesta no se publica: podés dejarla anotada y completarla después. " +
      "Sin categorías marcadas la pregunta es general y sale en el inicio.",
    vacio: "Todavía no hay preguntas. Creá la primera y escribí su respuesta.",

    columnas: [
      { label: "Pregunta", render: celda.principal("question", "answer") },
      // El tema elegido no se veia en ninguna parte del panel, que es
      // justamente para lo unico que sirve.
      {
        label: "Tema",
        render: function (f) {
          var t = temas.filter(function (x) { return x.id === f.faq_category_id; })[0];
          if (!t) return h("span", { class: "chip", text: "Sin tema" });
          return h("span", { style: "font-size:12.5px;font-weight:600", text: t.name });
        }
      },
      {
        label: "Dónde se muestra",
        render: function (f) {
          var cats = (f.faq_product_categories || []).length;
          var prods = (f.faq_products || []).length;
          if (!cats && !prods) return h("span", { class: "chip", text: "General" });
          var partes = [];
          if (cats) partes.push(cats + (cats === 1 ? " categoría" : " categorías"));
          if (prods) partes.push(prods + (prods === 1 ? " producto" : " productos"));
          return h("span", { style: "font-size:12.5px;color:var(--gris)", text: partes.join(" · ") });
        }
      },
      {
        label: "Estado",
        render: function (f) {
          var lista = f.is_active && f.answer && f.answer.trim();
          return h("span", {
            class: "insignia " + (lista ? "publicado" : "borrador"),
            text: lista ? "Publicada" : f.answer ? "Oculta" : "Sin respuesta"
          });
        }
      },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") }
    ],

    campos: [
      { k: "question", label: "Pregunta", grupo: "Contenido", placeholder: "¿Qué medios de pago aceptan?" },
      {
        k: "answer", label: "Respuesta", tipo: "textarea", filas: 6, grupo: "Contenido",
        pista: "Mientras esté vacía, la pregunta no se muestra en el sitio."
      },
      {
        k: "faq_category_id", label: "Tema", tipo: "select", grupo: "Contenido",
        // Funcion, no lista: los temas se cargan al entrar a la pantalla.
        opciones: function () {
          return [{ valor: "", label: "— Sin tema —" }].concat(
            temas.map(function (t) { return { valor: t.id, label: t.name }; })
          );
        }
      },
      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Pregunta activa", tipo: "switch", grupo: "Publicación" }
    ],

    // Dónde se muestra la pregunta: en el inicio, en unas categorías o en
    // unos productos concretos.
    extras: function (fila) {
      var elegidas = ((fila && fila.faq_product_categories) || []).map(function (x) {
        return x.category_id;
      });

      var casillas = h("div", { class: "casillas" });
      categorias.forEach(function (c) {
        var input = h("input", { type: "checkbox", value: c.id });
        input.checked = elegidas.indexOf(c.id) !== -1;
        casillas.appendChild(h("label", { class: "casilla" }, [input, c.name]));
      });

      // Productos puntuales. Sin motivo: acá no hay tipos de relación, solo
      // "esta pregunta se muestra en esta ficha".
      var elegidos = ((fila && fila.faq_products) || []).map(function (x) {
        return { id: x.product_id, tipo: "related" };
      });
      var selProductos = UI.selectorProductos({
        valores: elegidos,
        catalogo: catalogo,
        sinTipos: true,
        vacio: "Ningún producto en particular."
      });

      var nodo = h("fieldset", { class: "bloque" }, [
        h("legend", null, "Dónde se muestra"),
        h("span", {
          class: "pista",
          style: "margin:0 0 10px",
          text:
            "Sin marcar nada, la pregunta es general y sale en el inicio. " +
            "Marcando categorías aparece en sus listados y en las fichas de sus productos. " +
            "Eligiendo productos, solo en esas fichas."
        }),
        h("span", { class: "pista", style: "margin:0 0 6px;font-weight:600", text: "Categorías" }),
        casillas,
        h("span", { class: "pista", style: "margin:14px 0 6px;font-weight:600", text: "Productos puntuales" }),
        selProductos
      ]);

      nodo.leer = function () {
        return {
          categorias: Array.prototype.slice
            .call(casillas.querySelectorAll("input:checked"))
            .map(function (x) { return x.value; }),
          productos: selProductos.leer().map(function (r) { return r.id; })
        };
      };
      return nodo;
    },

    alGuardar: async function (fila, datos, extras, r) {
      var id = fila ? fila.id : r.data && r.data.id;
      if (!id || !extras || !extras.leer) return;

      // Se reemplazan las dos listas enteras: son pocas filas y evita calcular
      // altas y bajas por separado.
      var elegido = extras.leer();

      await sb.from("faq_product_categories").delete().eq("faq_id", id);
      if (elegido.categorias.length) {
        var ins = await sb.from("faq_product_categories").insert(
          elegido.categorias.map(function (cid) {
            return { faq_id: id, category_id: cid };
          })
        );
        if (ins.error) throw ins.error;
      }

      await sb.from("faq_products").delete().eq("faq_id", id);
      if (elegido.productos.length) {
        var insP = await sb.from("faq_products").insert(
          elegido.productos.map(function (pid) {
            return { faq_id: id, product_id: pid };
          })
        );
        if (insP.error) throw insP.error;
      }
    },

    validar: function (d) {
      if (!d.question) return "Falta la pregunta.";
      return null;
    }
  });

})();
