/* MAXING.py — modulos Ajustes y SEO */
(function () {
  "use strict";

  var h = UI.h;

  var TITULOS_GRUPO = {
    general: "General",
    contacto: "Contacto",
    catalogo: "Catálogo",
    secciones: "Secciones del inicio"
  };

  var AYUDA_GRUPO = {
    secciones:
      "Apagar una sección la saca del inicio sin borrar su contenido. " +
      "Las secciones que se quedan sin datos (una colección vacía, por ejemplo) se ocultan solas igual."
  };

  /* ---------------------------------------------------------------- */
  /* Ajustes                                                          */
  /* ---------------------------------------------------------------- */
  registrarModulo("ajustes", {
    titulo: "Ajustes",
    sub: "Contacto, WhatsApp y visibilidad de secciones",
    grupo: "Sitio",
    icono: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.9.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.9.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.9-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.9V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/>',

    async render(cont, app) {
      var r = await sb.from("site_settings").select("*").order("group_key").order("sort_order");
      if (r.error) throw r.error;

      // Ajustes que el sitio todavia no lee. Se ocultan en vez de borrarlos:
      // las filas quedan en la base por si alguna vez se conectan, pero no se
      // ofrecen para editar, porque escribirlos no cambiaria nada en la web.
      //
      // El nombre, el eslogan y la razon social estan escritos en el HTML;
      // los datos de contacto van en las tarjetas del pie, que si se editan;
      // y el escalon del filtro y el prefijo de precio son fijos.
      var SIN_USO = [
        "site_name", "site_slogan", "site_url", "legal_name",
        "contact_email", "contact_address", "contact_hours",
        "price_step", "currency_prefix"
      ];

      var filas = (r.data || []).filter(function (f) {
        return SIN_USO.indexOf(f.key) === -1;
      });
      var controles = {};
      var grupos = [];

      filas.forEach(function (f) {
        var g = grupos.filter(function (x) { return x.clave === f.group_key; })[0];
        if (!g) {
          g = { clave: f.group_key, items: [] };
          grupos.push(g);
        }
        g.items.push(f);
      });

      grupos.forEach(function (g) {
        var cuerpo = h("div", { class: "tarjeta-cuerpo" });

        g.items.forEach(function (f) {
          var c;
          if (f.value_type === "boolean") {
            c = UI.interruptor(f.label || f.key, f.value === "true");
            c.leer = function () { return c.control.checked ? "true" : "false"; };
            if (f.description) {
              cuerpo.appendChild(c);
              cuerpo.appendChild(h("span", { class: "pista", style: "margin:-6px 0 12px 44px", text: f.description }));
              controles[f.key] = c;
              return;
            }
          } else if (f.value_type === "number") {
            c = UI.campo({ label: f.label || f.key, tipo: "number", valor: f.value, pista: f.description });
            c.leer = function () { return c.control.value; };
          } else {
            c = UI.campo({
              label: f.label || f.key,
              valor: f.value,
              pista: f.description,
              tipo: f.value_type === "url" ? "url" : "text"
            });
            // Sin trim, a proposito. Hay ajustes cuyo espacio final es parte
            // del dato: el prefijo de precio es "Gs. " y el saludo de WhatsApp
            // termina en ": ", porque despues se les pega el numero o el
            // nombre del producto. Recortarlos los rompia, y ademas hacia que
            // el panel los diera por modificados y los reescribiera cada vez
            // que alguien entraba a Ajustes y tocaba Guardar.
            c.leer = function () { return c.control.value; };
          }
          controles[f.key] = c;
          cuerpo.appendChild(c);
        });

        cont.appendChild(
          h("div", { class: "tarjeta" }, [
            h("div", { class: "tarjeta-cab" }, [
              h("h2", null, [
                TITULOS_GRUPO[g.clave] || g.clave,
                AYUDA_GRUPO[g.clave] ? h("span", { class: "nota", text: AYUDA_GRUPO[g.clave] }) : null
              ])
            ]),
            cuerpo
          ])
        );
      });

      app.acciones([
        {
          label: "Guardar ajustes",
          clase: "btn-primario",
          onclick: async function (e) {
            var boton = e.currentTarget;
            boton.disabled = true;
            boton.textContent = "Guardando…";

            // Se guardan solo los que cambiaron: menos escrituras y menos
            // ruido en updated_at.
            var cambios = filas.filter(function (f) {
              return controles[f.key] && controles[f.key].leer() !== (f.value == null ? "" : f.value);
            });

            if (!cambios.length) {
              UI.noti("No había cambios para guardar.");
              boton.disabled = false;
              boton.textContent = "Guardar ajustes";
              return;
            }

            var errores = [];
            for (var i = 0; i < cambios.length; i++) {
              var f = cambios[i];
              var u = await sb.from("site_settings").update({ value: controles[f.key].leer() }).eq("key", f.key);
              if (u.error) errores.push(f.key + ": " + UI.explicar(u.error));
            }

            if (errores.length) {
              UI.noti(errores[0], "error");
            } else {
              UI.noti(cambios.length + (cambios.length === 1 ? " ajuste guardado." : " ajustes guardados."));
            }
            boton.disabled = false;
            boton.textContent = "Guardar ajustes";
            App.recargar();
          }
        }
      ]);
    }
  });

  /* ---------------------------------------------------------------- */
  /* SEO                                                              */
  /* ---------------------------------------------------------------- */
  var NOMBRES_PAGINA = {
    home: "Inicio",
    catalog: "Catálogo",
    product: "Ficha de producto",
    nosotros: "Quiénes somos",
    favoritos: "Favoritos",
    carrito: "Lista de consulta"
  };

  registrarModulo("seo", {
    titulo: "SEO",
    sub: "Títulos y descripciones de cada página",
    grupo: "Sitio",
    icono: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',

    async render(cont, app) {
      cont.appendChild(
        h("div", { class: "aviso" }, [
          h("div", null, [
            h("strong", null, "Largos recomendados: "),
            "título hasta 60 caracteres, descripción entre 120 y 160. Más largo, Google lo corta."
          ])
        ])
      );

      var r = await sb.from("seo_pages").select("*").order("page_key");
      if (r.error) throw r.error;

      var filas = r.data || [];
      if (!filas.length) {
        cont.appendChild(
          h("div", { class: "tarjeta" }, [
            h("div", { class: "vacio" }, [
              h("h3", null, "No hay páginas cargadas"),
              h("p", null, "Se crean con la migración inicial.")
            ])
          ])
        );
        return;
      }

      var tbody = h("tbody");
      filas.forEach(function (f) {
        tbody.appendChild(
          h("tr", null, [
            h("td", null, [
              h("div", { style: "font-weight:600;color:var(--negro)", text: NOMBRES_PAGINA[f.page_key] || f.page_key }),
              h("div", { style: "font-size:12px;color:var(--gris)", text: f.path || "—" })
            ]),
            h("td", null, [medidor(f.title, 60)]),
            h("td", null, [medidor(f.meta_description, 160)]),
            h("td", { class: "acciones" }, [
              h("button", { class: "btn btn-plano", type: "button", onclick: function () { editar(f); } }, "Editar")
            ])
          ])
        );
      });

      cont.appendChild(
        h("div", { class: "tarjeta" }, [
          h("div", { class: "tarjeta-cab" }, [h("h2", null, filas.length + " páginas")]),
          h("div", { class: "tabla-marco" }, [
            h("table", { class: "tabla" }, [
              h("thead", null, [
                h("tr", null, [
                  h("th", null, "Página"),
                  h("th", null, "Título"),
                  h("th", null, "Descripción"),
                  h("th", { class: "acciones" }, "")
                ])
              ]),
              tbody
            ])
          ])
        ])
      );
    }
  });

  // Muestra el texto y avisa cuando se pasa del largo util.
  function medidor(texto, tope) {
    var t = texto || "";
    var largo = t.length;
    return h("div", null, [
      h("div", { style: "font-size:13px", text: t ? (t.length > 52 ? t.slice(0, 52) + "…" : t) : "— sin cargar —" }),
      h("div", {
        style: "font-size:11.5px;font-variant-numeric:tabular-nums;color:" +
          (largo === 0 ? "var(--aviso)" : largo > tope ? "var(--peligro)" : "var(--gris)"),
        text: largo === 0 ? "vacío" : largo + " / " + tope
      })
    ]);
  }

  function editar(f) {
    function contado(campoUI, tope) {
      var cuenta = h("span", { class: "pista" });
      function refrescar() {
        var n = campoUI.control.value.length;
        cuenta.textContent = n + " de " + tope + " caracteres" + (n > tope ? " — se va a cortar" : "");
        cuenta.style.color = n > tope ? "var(--peligro)" : "var(--gris)";
      }
      campoUI.control.addEventListener("input", refrescar);
      campoUI.appendChild(cuenta);
      refrescar();
      return campoUI;
    }

    var fTitulo = contado(UI.campo({ label: "Título", valor: f.title }), 60);
    var fDesc = contado(UI.campo({ label: "Descripción", tipo: "textarea", filas: 3, valor: f.meta_description }), 160);

    UI.abrirCajon({
      titulo: "SEO — " + (NOMBRES_PAGINA[f.page_key] || f.page_key),
      cuerpo: [
        h("fieldset", { class: "bloque" }, [
          h("legend", null, "Título y descripción"),
          fTitulo, fDesc
        ])
      ],
      acciones: [
        { label: "Cancelar", clase: "btn-plano", onclick: function () { UI.cerrarCajon(); } },
        {
          label: "Guardar",
          clase: "btn-primario",
          onclick: async function (e) {
            var boton = e.currentTarget;
            boton.disabled = true;
            boton.textContent = "Guardando…";
            var r = await sb
              .from("seo_pages")
              .update({
                title: fTitulo.control.value.trim() || null,
                meta_description: fDesc.control.value.trim() || null,
                meta_description: fDesc.control.value.trim() || null
              })
              .eq("page_key", f.page_key);

            if (r.error) {
              UI.noti(UI.explicar(r.error), "error");
              boton.disabled = false;
              boton.textContent = "Guardar";
              return;
            }
            UI.cerrarCajon();
            UI.noti("SEO actualizado.");
            App.recargar();
          }
        }
      ]
    });
  }
})();
