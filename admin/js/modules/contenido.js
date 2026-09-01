/* MAXING.py — modulos de contenido: hero, secciones, beneficios, pie y redes */
(function () {
  "use strict";

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "hero",
    titulo: "Hero",
    sub: "El bloque grande de arriba de todo",
    grupo: "Contenido",
    singular: "Slide",
    contadorSingular: "slide",
    contadorPlural: "slides",
    icono: '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 21h8"/><path d="M12 17v4"/>',
    tabla: "hero_slides",
    nota: "El sitio muestra el primer slide activo. Los demás quedan guardados para poder alternarlos.",
    vacio: "Creá el contenido del hero.",

    columnas: [
      { label: "", render: celda.imagen("image_url") },
      { label: "Título", render: celda.principal("title", "eyebrow") },
      { label: "Botón", render: celda.texto("cta_label") },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Activo", "Oculto") }
    ],

    campos: [
      {
        k: "eyebrow", label: "Línea superior", grupo: "Textos",
        placeholder: "Tecnología · Informática · Gaming"
      },
      { k: "title", label: "Título", grupo: "Textos", placeholder: "Tecnología que mejora tu día." },
      { k: "subtitle", label: "Bajada", tipo: "textarea", filas: 3, grupo: "Textos" },

      { k: "image_url", label: "Imagen de fondo", tipo: "imagen", carpeta: "hero", grupo: "Imagen" },
      { k: "image_alt", label: "Texto alternativo", grupo: "Imagen" },

      { k: "cta_label", label: "Botón principal", grupo: "Botones", placeholder: "Explorar productos" },
      {
        k: "cta_target", label: "Destino del botón principal", grupo: "Botones",
        pista: "catalog, nosotros, whatsapp, #ancla o una URL completa.",
        placeholder: "catalog"
      },
      { k: "cta_secondary_label", label: "Botón secundario", grupo: "Botones" },
      { k: "cta_secondary_target", label: "Destino del secundario", grupo: "Botones", placeholder: "whatsapp" },

      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Slide activo", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.title) return "Falta el título.";
      return null;
    }
  });

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "secciones",
    titulo: "Secciones",
    sub: "“Quiénes somos”, el bloque de setup y el texto editorial",
    grupo: "Contenido",
    singular: "Sección",
    contadorSingular: "sección",
    contadorPlural: "secciones",
    icono: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 10h18"/><path d="M9 10v10"/>',
    tabla: "content_sections",
    // Borrar una seccion dejaria un hueco en el sitio que el panel no puede
    // volver a crear, porque el frontend la busca por section_key. Se puede
    // ocultar, que es lo que se necesita en la practica.
    sinBorrado: true,
    nota:
      "Cada sección tiene una clave fija con la que el sitio la busca. Se pueden editar u ocultar, " +
      "pero no eliminar: el sitio dejaría un hueco que el panel no puede volver a llenar.",
    vacio: "Las secciones se crean con la migración inicial.",

    columnas: [
      { label: "", render: celda.imagen("image_url") },
      { label: "Sección", render: celda.principal("title", "section_key") },
      { label: "Imagen", render: celda.texto("image_side") },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_visible", "Visible", "Oculta") }
    ],

    campos: [
      {
        k: "section_key", label: "Clave", grupo: "Identificación",
        pista: "Con esta clave la busca el sitio. No conviene cambiarla."
      },
      { k: "subtitle", label: "Línea superior", grupo: "Textos", placeholder: "La empresa" },
      { k: "title", label: "Título", grupo: "Textos", placeholder: "¿Quiénes somos?" },
      {
        k: "body", label: "Texto", tipo: "textarea", filas: 9, grupo: "Textos",
        pista: "Separá los párrafos con una línea en blanco."
      },

      { k: "image_url", label: "Imagen", tipo: "imagen", carpeta: "sections", grupo: "Imagen" },
      { k: "image_alt", label: "Texto alternativo", grupo: "Imagen" },
      {
        k: "image_side", label: "Lado de la imagen", tipo: "select", grupo: "Imagen",
        opciones: [
          { valor: "right", label: "Derecha" },
          { valor: "left", label: "Izquierda" },
          { valor: "none", label: "Sin imagen" }
        ]
      },

      { k: "cta_label", label: "Botón", grupo: "Botón" },
      { k: "cta_target", label: "Destino del botón", grupo: "Botón", placeholder: "catalog" },

      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_visible", label: "Sección visible", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.section_key) return "Falta la clave de la sección.";
      return null;
    }
  });

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "beneficios",
    titulo: "Beneficios",
    sub: "Las cuatro razones para comprar acá",
    grupo: "Contenido",
    singular: "Beneficio",
    contadorSingular: "beneficio",
    contadorPlural: "beneficios",
    icono: '<path d="m9 12 2 2 4-4"/><circle cx="12" cy="12" r="9"/>',
    tabla: "benefits",
    vacio: "Creá el primer beneficio.",

    columnas: [
      { label: "Beneficio", render: celda.principal("title", "text") },
      { label: "Ícono", render: celda.texto("icon_key") },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Activo", "Oculto") }
    ],

    campos: [
      { k: "title", label: "Título", grupo: "Textos", placeholder: "Productos seleccionados" },
      { k: "text", label: "Texto", tipo: "textarea", filas: 3, grupo: "Textos" },
      {
        k: "icon_key", label: "Ícono", tipo: "select", grupo: "Apariencia",
        opciones: [
          { valor: "check", label: "Tilde" },
          { valor: "chat", label: "Conversación" },
          { valor: "shield", label: "Escudo" },
          { valor: "clock", label: "Reloj" }
        ]
      },
      { k: "icon_color", label: "Color del ícono", tipo: "color", grupo: "Apariencia" },
      { k: "tint_color", label: "Color de fondo", tipo: "color", grupo: "Apariencia" },
      { k: "line_color", label: "Color del borde", tipo: "color", grupo: "Apariencia" },
      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Beneficio activo", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.title) return "Falta el título.";
      return null;
    }
  });

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "pie",
    titulo: "Pie de página",
    sub: "Tarjetas operativas y columna de ayuda",
    grupo: "Contenido",
    singular: "Ítem",
    contadorSingular: "ítem",
    contadorPlural: "ítems",
    icono: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 15h18"/>',
    tabla: "footer_items",
    orden: ["group_key", "sort_order"],
    nota:
      "Las columnas “Productos” y “Marcas” del pie se arman solas con las categorías y marcas activas. " +
      "Acá se administran las tarjetas de envíos, retiro, garantía y atención, y la columna de ayuda.",
    vacio: "Creá el primer ítem del pie.",

    columnas: [
      { label: "Ítem", render: celda.principal("title", "text") },
      { label: "Grupo", render: celda.texto("group_key") },
      {
        label: "Dato",
        render: function (f) {
          return f.is_pending
            ? UI.h("span", { class: "insignia pendiente", text: f.pending_note || "Falta el dato" })
            : UI.h("span", { class: "insignia publicado", text: "Completo" });
        }
      },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Visible", "Oculto") }
    ],

    campos: [
      {
        k: "group_key", label: "Grupo", tipo: "select", grupo: "Ubicación",
        opciones: [
          { valor: "operativo", label: "Tarjetas operativas" },
          { valor: "col_ayuda", label: "Columna: Ayuda" }
        ]
      },
      { k: "group_label", label: "Título del grupo", grupo: "Ubicación", placeholder: "Cómo trabajamos" },
      { k: "title", label: "Título", grupo: "Contenido", placeholder: "Envíos" },
      { k: "text", label: "Texto", tipo: "textarea", filas: 3, grupo: "Contenido" },
      {
        k: "link_target", label: "Destino", grupo: "Contenido",
        pista: "catalog, nosotros, #ancla o una ruta del sitio. Vacío si no es un enlace."
      },
      { k: "color", label: "Color de fondo", tipo: "color", grupo: "Apariencia" },
      { k: "ink_color", label: "Color del texto", tipo: "color", grupo: "Apariencia" },
      {
        k: "is_pending", label: "Falta el dato definitivo", tipo: "switch", pordefecto: false,
        grupo: "Estado del dato"
      },
      {
        k: "pending_note", label: "Qué falta", grupo: "Estado del dato",
        pista: "Solo para el panel: no se muestra en el sitio.",
        placeholder: "Falta: dirección y cómo llegar"
      },
      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Ítem visible", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.title) return "Falta el título.";
      if (!d.group_key) return "Elegí en qué grupo va.";
      return null;
    }
  });

  /* ---------------------------------------------------------------- */
  crudSimple({
    clave: "redes",
    titulo: "Redes y contacto",
    sub: "WhatsApp, Instagram y TikTok",
    grupo: "Contenido",
    singular: "Red",
    contadorSingular: "red",
    contadorPlural: "redes",
    icono: '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m8.6 13.5 6.8 4"/><path d="m15.4 6.5-6.8 4"/>',
    tabla: "social_links",
    nota:
      "El número de WhatsApp que usan los botones de consulta se configura en Ajustes; " +
      "acá se administra el enlace que aparece en el pie y en la sección de redes.",
    vacio: "Agregá la primera red.",

    columnas: [
      { label: "Red", render: celda.principal("label", "handle") },
      { label: "Enlace", render: celda.texto("url", 40) },
      { label: "Orden", clase: "num", render: celda.texto("sort_order") },
      { label: "Estado", render: celda.estado("is_active", "Visible", "Oculta") }
    ],

    campos: [
      {
        k: "platform", label: "Plataforma", tipo: "select", grupo: "Identificación",
        opciones: [
          { valor: "whatsapp", label: "WhatsApp" },
          { valor: "instagram", label: "Instagram" },
          { valor: "tiktok", label: "TikTok" },
          { valor: "facebook", label: "Facebook" },
          { valor: "x", label: "X" },
          { valor: "youtube", label: "YouTube" },
          { valor: "linkedin", label: "LinkedIn" }
        ]
      },
      { k: "label", label: "Nombre visible", grupo: "Identificación", placeholder: "Instagram" },
      { k: "handle", label: "Usuario", grupo: "Identificación", placeholder: "@maxing.py" },
      { k: "url", label: "Enlace", tipo: "url", grupo: "Identificación", placeholder: "https://instagram.com/maxing.py" },
      { k: "sort_order", label: "Orden", tipo: "number", min: 0, pordefecto: 0, grupo: "Publicación" },
      { k: "is_active", label: "Visible en el sitio", tipo: "switch", grupo: "Publicación" }
    ],

    validar: function (d) {
      if (!d.platform) return "Elegí la plataforma.";
      if (!d.url) return "Falta el enlace.";
      if (!/^https?:\/\//i.test(d.url)) return "El enlace tiene que empezar con http:// o https://";
      return null;
    }
  });
})();
