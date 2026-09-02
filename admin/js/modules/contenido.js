/* MAXING.py — modulos de contenido: hero, secciones, beneficios, pie y redes */
(function () {
  "use strict";

  // Secciones que el sitio dibuja con una imagen al lado. "redes" no está:
  // en el inicio es un bloque de titulo, bajada y enlaces, sin lugar para una
  // foto. Si algun dia el sitio le agrega uno, se suma su clave acá.
  var SECCIONES_CON_IMAGEN = ["setup", "nosotros", "seo_editorial"];
  // Idem con el boton: solo la seccion de setup lo dibuja.
  var SECCIONES_CON_BOTON = ["setup"];
  function CON_BOTON(fila) {
    if (!fila.section_key) return true;
    return SECCIONES_CON_BOTON.indexOf(fila.section_key) !== -1;
  }
  function CON_IMAGEN(fila) {
    // En una seccion nueva todavia no hay clave: se muestran los campos y
    // sera el sitio el que decida si la dibuja.
    if (!fila.section_key) return true;
    return SECCIONES_CON_IMAGEN.indexOf(fila.section_key) !== -1;
  }

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
    // El sitio dibuja un solo hero, asi que el panel administra uno solo: sin
    // boton de "nuevo slide" y sin campo de orden. Varios slides sin poder
    // ordenarlos serian una trampa —no habria forma de saber cual sale—, y
    // ordenarlos no serviria de nada porque igual se muestra uno.
    soloEdicion: true,
    sinBorrado: true,
    nota: "Es el bloque grande de arriba de todo, en el inicio. Para sacarlo del sitio sin borrar su contenido, usá el interruptor “Mostrar hero” en Ajustes.",
    vacio: "Creá el contenido del hero.",

    columnas: [
      { label: "", render: celda.imagen("image_url") },
      { label: "Título", render: celda.principal("title", "eyebrow") },
      { label: "Botón", render: celda.texto("cta_label") },
      { label: "Estado", render: celda.estado("is_active", "Activo", "Oculto") }
    ],

    campos: [
      {
        k: "eyebrow", label: "Línea superior", grupo: "Textos",
        placeholder: "Tecnología · Informática · Gaming"
      },
      { k: "title", label: "Título", grupo: "Textos", placeholder: "Tecnología que mejora tu día." },
      { k: "subtitle", label: "Bajada", tipo: "textarea", filas: 3, grupo: "Textos" },

      // Sin texto alternativo: la imagen del hero es decorativa —va con
      // alt="" y aria-hidden— porque el titulo ya dice lo que hay que decir.
      // Un texto ahi seria ruido para quien usa lector de pantalla.
      { k: "image_url", label: "Imagen de fondo", tipo: "imagen", carpeta: "hero", grupo: "Imagen" },

      { k: "cta_label", label: "Botón principal", grupo: "Botones", placeholder: "Explorar productos" },
      {
        k: "cta_target", label: "Destino del botón principal", grupo: "Botones",
        pista: "catalog, nosotros, whatsapp, #ancla o una URL completa.",
        placeholder: "catalog"
      },
      // El boton secundario no se configura: el sitio lo decide solo. Ofrece
      // "Ver ofertas" cuando hay algo rebajado y "Ver novedades" cuando no,
      // asi nunca lleva a una seccion vacia.

      { k: "is_active", label: "Hero activo", tipo: "switch", grupo: "Publicación" }
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

      // Los campos de imagen solo aparecen en las secciones que el sitio
      // dibuja CON imagen. En las demás ofrecer una subida seria mentir: la
      // foto se guardaria y no se veria en ningun lado.
      { k: "image_url", label: "Imagen", tipo: "imagen", carpeta: "sections", grupo: "Imagen", mostrarSi: CON_IMAGEN },
      // Ya no se piden el texto alternativo ni el lado de la imagen. El
      // alternativo lo resuelve el sitio con el titulo de la seccion, y el
      // lado esta fijo en el diseno: elegirlo no cambiaba nada.

      // Solo "setup" dibuja un boton en el sitio; en las demas secciones
      // configurarlo no mostraria nada.
      { k: "cta_label", label: "Botón", grupo: "Botón", mostrarSi: CON_BOTON },
      { k: "cta_target", label: "Destino del botón", grupo: "Botón", placeholder: "catalog", mostrarSi: CON_BOTON },

      // Sin "Orden": el sitio busca cada seccion por su clave y las dibuja
      // en el lugar que les corresponde, asi que el numero no movia nada.
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
    // Cada grupo del pie se ordena por separado.
    alcanceOrden: "group_key",
    nota:
      "Las columnas “Productos” y “Marcas” del pie se arman solas con las categorías y marcas activas. " +
      "Acá se administran las tarjetas de envíos, retiro, garantía y atención, y la columna de ayuda.",
    vacio: "Creá el primer ítem del pie.",

    // Sin columna de grupo: mostraba la clave interna (`col_ayuda`,
    // `operativo`), que no le dice nada a quien administra. La tabla ya viene
    // ordenada por grupo, y el grupo se elige en el formulario.
    columnas: [
      { label: "Ítem", render: celda.principal("title", "text") },
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
        pista: "catalog, nosotros, #ancla o una ruta del sitio.",
        // Las tarjetas operativas del pie son texto, no enlaces: solo los
        // items de la columna de ayuda llevan destino.
        mostrarSi: function (f) { return f.group_key !== "operativo"; }
      },
      // Se llamaba "Color de fondo" y no lo era: el fondo de la tarjeta es
      // blanco fijo y este color pinta el borde.
      {
        k: "color", label: "Color del borde", tipo: "color", grupo: "Apariencia",
        pista: "El marco de la tarjeta en el pie del sitio."
      },
      {
        k: "ink_color", label: "Color del título", tipo: "color", grupo: "Apariencia",
        pista: "El título de la tarjeta. El texto de abajo va siempre en gris."
      },
      // No se ven en el sitio, pero no son de adorno: encienden el aviso
      // "Faltan datos del pie de página" del Resumen. Sin ellos ese aviso
      // quedaría prendido para siempre, sin forma de apagarlo.
      {
        k: "is_pending", label: "Falta el dato definitivo", tipo: "switch", pordefecto: false,
        grupo: "Estado del dato",
        pista: "Enciende el aviso del Resumen. Apagalo cuando cargues el dato real."
      },
      {
        k: "pending_note", label: "Qué falta", grupo: "Estado del dato",
        pista: "Es el texto que aparece en ese aviso. No se muestra en el sitio.",
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
