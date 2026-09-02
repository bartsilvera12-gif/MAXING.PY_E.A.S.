/* MAXING.py — modulos Categorias y Marcas */
(function () {
  "use strict";

  var h = UI.h;

  // Cuántos productos PUBLICADOS tiene cada categoría. Se calcula al entrar a
  // la pantalla porque es el dato que decide si la categoría se ve o no en el
  // sitio, y desde la lista no había forma de saberlo.
  var conteo = {};

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "categorias",
    titulo: "Categorías",
    sub: "Las secciones en las que se agrupa el catálogo",
    grupo: "Catálogo",
    singular: "Categoría",
    contadorSingular: "categoría",
    contadorPlural: "categorías",
    icono: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
    tabla: "categories",
    nota:
      "En el sitio solo aparecen las categorías activas que además tengan al menos un producto publicado. " +
      "Una categoría vacía se oculta sola, no hace falta desactivarla.",
    vacio: "Creá la primera categoría para poder agrupar los productos.",

    preparar: async function () {
      var r = await sb
        .from("products")
        .select("id, product_categories(category_id)")
        .eq("is_published", true);
      conteo = {};
      (r.data || []).forEach(function (p) {
        (p.product_categories || []).forEach(function (x) {
          conteo[x.category_id] = (conteo[x.category_id] || 0) + 1;
        });
      });
    },

    columnas: [
      { label: "", clase: null, render: celda.imagen("image_url") },
      { label: "Categoría", render: celda.principal("name", "short_description") },
      { label: "Slug", render: celda.texto("slug") },
      // La columna que faltaba: sin ella no había forma de ver desde la lista
      // cuál está vacía, que es justo la que no se muestra en el sitio.
      {
        label: "Productos",
        clase: "num",
        render: function (c) {
          var n = conteo[c.id] || 0;
          if (n) return h("span", { style: "font-variant-numeric:tabular-nums", text: String(n) });
          return h("span", { class: "insignia pendiente", text: "Sin productos" });
        }
      },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Activa", "Oculta") }
    ],

    campos: [
      { k: "name", label: "Nombre", grupo: "Identificación", placeholder: "Notebooks" },
      {
        k: "slug", label: "Slug", grupo: "Identificación",
        desde: "name",
        pista: "Se escribe solo desde el nombre. En una categoría que ya existe no se toca: es su URL.",
        placeholder: "notebooks"
      },
      {
        k: "short_description", label: "Bajada", grupo: "Identificación",
        pista: "La línea corta que se ve en la ficha de la categoría.",
        placeholder: "Trabajo, estudio y gaming"
      },

      { k: "image_url", label: "Foto", tipo: "imagen", carpeta: "categories", grupo: "Apariencia" },
      {
        k: "icon_svg", label: "Ícono (path SVG)", grupo: "Apariencia",
        pista: "Se usa solo cuando la categoría no tiene foto."
      },
      { k: "color", label: "Color de fondo", tipo: "color", grupo: "Apariencia" },
      { k: "ink_color", label: "Color del texto", tipo: "color", grupo: "Apariencia" },

      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Categoría activa", tipo: "switch", grupo: "Publicación" },

      {
        k: "seo_title", label: "Título SEO", grupo: "SEO",
        pista: "Vacío: se usa “<nombre> — MAXING.py”."
      },
      { k: "seo_description", label: "Descripción SEO", tipo: "textarea", filas: 3, grupo: "SEO" },
      {
        k: "canonical_url", label: "URL canónica", tipo: "url", grupo: "SEO",
        pista: "Vacío: se usa https://maxing.py/categorias/<slug>"
      }
    ],

    validar: function (d) {
      if (!d.name) return "Falta el nombre.";
      if (!d.slug) return "Falta el slug.";
      if (!/^[a-z0-9-]+$/.test(d.slug)) return "El slug solo puede tener minúsculas, números y guiones.";
      return null;
    }
  });

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "marcas",
    titulo: "Marcas",
    sub: "Los fabricantes que se muestran en el sitio",
    grupo: "Catálogo",
    singular: "Marca",
    contadorSingular: "marca",
    contadorPlural: "marcas",
    icono: '<path d="M12 2 3 7v6c0 5 3.8 8.4 9 9 5.2-.6 9-4 9-9V7l-9-5Z"/>',
    tabla: "brands",
    nota: "En el sitio se muestran las marcas activas que tengan al menos un producto publicado.",
    vacio: "Creá la primera marca.",

    columnas: [
      { label: "", render: celda.imagen("logo_url") },
      { label: "Marca", render: celda.principal("name", "slug") },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Activa", "Oculta") }
    ],

    campos: [
      { k: "name", label: "Nombre", grupo: "Identificación", placeholder: "MSI" },
      {
        k: "slug", label: "Slug", grupo: "Identificación",
        desde: "name",
        pista: "Se escribe solo desde el nombre.",
        placeholder: "msi"
      },
      { k: "logo_url", label: "Logo", tipo: "imagen", carpeta: "brands", grupo: "Identificación" },
      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Marca activa", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.name) return "Falta el nombre.";
      if (!d.slug) return "Falta el slug.";
      if (!/^[a-z0-9-]+$/.test(d.slug)) return "El slug solo puede tener minúsculas, números y guiones.";
      return null;
    }
  });
})();
