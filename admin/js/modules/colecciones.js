/* MAXING.py — modulo Colecciones
 *
 * Ofertas, Novedades, Destacados y Mas vendidos. El cliente pidio que sean
 * colecciones y no categorias.
 *
 * Hay dos clases:
 *   automatica -> se llena sola con una regla (en oferta, mas nuevos...).
 *                 No se eligen productos a mano; asi "Ofertas" no puede
 *                 quedar desincronizada de los precios.
 *   curada     -> el admin elige y ordena los productos.
 */
(function () {
  "use strict";

  var h = UI.h;

  var REGLAS = {
    on_sale: "Productos con precio anterior mayor al actual",
    newest: "Los últimos productos cargados",
    featured: "Los marcados como destacados",
    most_viewed: "Los más vistos"
  };

  registrarModulo("colecciones", {
    titulo: "Colecciones",
    sub: "Ofertas, novedades y destacados",
    grupo: "Catálogo",
    icono: '<path d="M4 7h16"/><path d="M4 12h16"/><path d="M4 17h10"/>',

    async render(cont, app) {
      app.acciones([
        { label: "+ Nueva colección", clase: "btn-primario", onclick: function () { editar(null); } }
      ]);

      cont.appendChild(
        h("div", { class: "aviso" }, [
          h("div", null, [
            h("strong", null, "Automáticas y curadas. "),
            "Una colección automática se llena sola con su regla: no se le eligen productos. " +
              "Así “Ofertas” siempre coincide con los precios cargados."
          ])
        ])
      );

      var r = await sb
        .from("collections")
        .select("*, product_collections(product_id)")
        .order("sort_order");
      if (r.error) throw r.error;

      var filas = r.data || [];
      if (!filas.length) {
        cont.appendChild(
          h("div", { class: "tarjeta" }, [
            h("div", { class: "vacio" }, [
              h("h3", null, "No hay colecciones"),
              h("p", null, "Creá la primera para agrupar productos fuera de las categorías.")
            ])
          ])
        );
        return;
      }

      var tbody = h("tbody");
      filas.forEach(function (c) {
        tbody.appendChild(
          h("tr", null, [
            h("td", null, [celda.principal("name", "slug")(c)]),
            h("td", null, [
              c.is_automatic
                ? h("span", { class: "insignia sin-punto", text: "Automática" })
                : h("span", { class: "chip", text: "Curada" })
            ]),
            h("td", null, [
              h("span", {
                style: "font-size:12.5px;color:var(--gris)",
                text: c.is_automatic ? REGLAS[c.auto_rule] || "—" : (c.product_collections || []).length + " productos elegidos"
              })
            ]),
            h("td", { class: "num", text: String(c.max_items) }),
            h("td", null, [celda.estado("is_active", "Activa", "Oculta")(c)]),
            h("td", { class: "acciones" }, [
              !c.is_automatic
                ? h(
                    "button",
                    {
                      class: "btn btn-plano",
                      type: "button",
                      onclick: function () { elegirProductos(c); }
                    },
                    "Elegir productos"
                  )
                : null,
              h(
                "button",
                { class: "btn btn-plano", type: "button", onclick: function () { editar(c); } },
                "Editar"
              ),
              // Borrar la colección no toca los productos: sólo deshace la
              // agrupación.
              UI.botonEliminar({
                nombre: c.name,
                tabla: "collections",
                id: c.id,
                alTerminar: function () { App.recargar(); }
              })
            ])
          ])
        );
      });

      cont.appendChild(
        h("div", { class: "tarjeta" }, [
          h("div", { class: "tarjeta-cab" }, [h("h2", null, filas.length + " colecciones")]),
          h("div", { class: "tabla-marco" }, [
            h("table", { class: "tabla" }, [
              h("thead", null, [
                h("tr", null, [
                  h("th", null, "Colección"),
                  h("th", null, "Tipo"),
                  h("th", null, "Contenido"),
                  h("th", { class: "num" }, "Máximo"),
                  h("th", null, "Estado"),
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

  /* ---------------------------------------------------------------- */
  function editar(c) {
    var esNueva = !c;
    c = c || { slug: "", name: "", description: "", anchor_id: "", is_automatic: false, auto_rule: "featured", max_items: 8, sort_order: 0, is_active: true };

    var fNombre = UI.campo({ label: "Nombre", valor: c.name, placeholder: "Destacados" });
    var fSlug = UI.campo({ label: "Slug", valor: c.slug, placeholder: "destacados" });
    var fDesc = UI.campo({ label: "Bajada", tipo: "textarea", filas: 2, valor: c.description });
    var fAncla = UI.campo({
      label: "Ancla en el inicio", valor: c.anchor_id,
      pista: "El id de la sección a la que salta el menú. Vacío si no tiene sección propia.",
      placeholder: "feat-h"
    });

    var swAuto = UI.interruptor("Se llena automáticamente", c.is_automatic, function (v) {
      fRegla.style.display = v ? "" : "none";
    });

    var fRegla = UI.campo({
      label: "Regla", tipo: "select", valor: c.auto_rule,
      opciones: Object.keys(REGLAS).map(function (k) {
        return { valor: k, label: REGLAS[k] };
      })
    });
    fRegla.style.display = c.is_automatic ? "" : "none";

    var fMax = UI.campo({ label: "Máximo de productos", tipo: "number", valor: c.max_items, min: 1 });
    var fOrden = UI.campo({ label: "Orden", tipo: "number", valor: c.sort_order, min: 0 });
    var swActiva = UI.interruptor("Colección activa", c.is_active);

    var acciones = [
      { label: "Cancelar", clase: "btn-plano", onclick: function () { UI.cerrarCajon(); } },
      { label: esNueva ? "Crear" : "Guardar cambios", clase: "btn-primario", onclick: guardar }
    ];

    if (!esNueva) {
      acciones.unshift({
        label: "Eliminar",
        clase: "btn-peligro izq",
        onclick: async function () {
          if (!UI.confirmarBorrado("la colección “" + c.name + "”")) return;
          var r = await sb.from("collections").delete().eq("id", c.id);
          if (r.error) { UI.noti(UI.explicar(r.error), "error"); return; }
          UI.cerrarCajon();
          UI.noti("Colección eliminada.");
          App.recargar();
        }
      });
    }

    UI.abrirCajon({
      titulo: esNueva ? "Nueva colección" : "Editar colección",
      cuerpo: [
        h("fieldset", { class: "bloque" }, [
          h("legend", null, "Identificación"),
          fNombre, fSlug, fDesc, fAncla
        ]),
        h("fieldset", { class: "bloque" }, [
          h("legend", null, "Cómo se llena"),
          swAuto, fRegla, fMax
        ]),
        h("fieldset", { class: "bloque" }, [
          h("legend", null, "Publicación"),
          fOrden, swActiva
        ])
      ],
      acciones: acciones
    });

    async function guardar(e) {
      var boton = e.currentTarget;
      var datos = {
        name: fNombre.control.value.trim(),
        slug: fSlug.control.value.trim() || UI.slugificar(fNombre.control.value),
        description: fDesc.control.value.trim() || null,
        anchor_id: fAncla.control.value.trim() || null,
        is_automatic: swAuto.control.checked,
        auto_rule: swAuto.control.checked ? fRegla.control.value : null,
        max_items: Number(fMax.control.value) || 8,
        sort_order: Number(fOrden.control.value) || 0,
        is_active: swActiva.control.checked
      };

      if (!datos.name) { UI.noti("Falta el nombre.", "error"); return; }
      if (!/^[a-z0-9-]+$/.test(datos.slug)) {
        UI.noti("El slug solo puede tener minúsculas, números y guiones.", "error");
        return;
      }

      boton.disabled = true;
      boton.textContent = "Guardando…";
      var r = esNueva
        ? await sb.from("collections").insert(datos)
        : await sb.from("collections").update(datos).eq("id", c.id);

      if (r.error) {
        UI.noti(UI.explicar(r.error), "error");
        boton.disabled = false;
        boton.textContent = esNueva ? "Crear" : "Guardar cambios";
        return;
      }
      UI.cerrarCajon();
      UI.noti("Colección guardada.");
      App.recargar();
    }
  }

  /* ---------------------------------------------------------------- */
  /* Eleccion de productos para una coleccion curada                   */
  /* ---------------------------------------------------------------- */
  async function elegirProductos(coleccion) {
    var rp = await sb
      .from("products")
      .select("id, name, sku, price, main_image_url, is_published")
      .eq("is_published", true)
      .order("name");
    if (rp.error) { UI.noti(UI.explicar(rp.error), "error"); return; }

    var re = await sb
      .from("product_collections")
      .select("product_id, sort_order")
      .eq("collection_id", coleccion.id)
      .order("sort_order");
    if (re.error) { UI.noti(UI.explicar(re.error), "error"); return; }

    // Se guarda el orden elegido, no solo el conjunto: en la vidriera el
    // orden de los destacados es una decision editorial.
    var elegidos = (re.data || []).map(function (x) { return x.product_id; });

    var buscador = h("input", { type: "search", placeholder: "Buscar producto…" });
    var lista = h("div", { style: "max-height:none" });
    var contador = h("p", { class: "pista", style: "margin:0 0 12px" });

    function pintar() {
      UI.vaciar(lista);
      var t = buscador.value.trim().toLowerCase();

      // Primero los elegidos, en su orden; despues el resto.
      var porId = {};
      rp.data.forEach(function (p) { porId[p.id] = p; });

      var arriba = elegidos.map(function (id) { return porId[id]; }).filter(Boolean);
      var resto = rp.data.filter(function (p) { return elegidos.indexOf(p.id) === -1; });

      arriba.concat(resto).forEach(function (p) {
        if (t && (p.name + " " + (p.sku || "")).toLowerCase().indexOf(t) === -1) return;

        var i = elegidos.indexOf(p.id);
        var marcado = i !== -1;

        var casilla = h("input", { type: "checkbox" });
        casilla.checked = marcado;
        casilla.addEventListener("change", function () {
          if (casilla.checked) {
            if (elegidos.length >= coleccion.max_items) {
              casilla.checked = false;
              UI.noti("Esta colección admite hasta " + coleccion.max_items + " productos.", "error");
              return;
            }
            elegidos.push(p.id);
          } else {
            elegidos.splice(elegidos.indexOf(p.id), 1);
          }
          pintar();
        });

        lista.appendChild(
          h(
            "div",
            {
              style:
                "display:flex;align-items:center;gap:10px;padding:8px 4px;border-bottom:1px solid var(--linea-suave)" +
                (marcado ? ";background:var(--acento-velo)" : "")
            },
            [
              casilla,
              p.main_image_url
                ? h("img", { class: "miniatura", style: "width:32px;height:32px", src: UI.urlImagen(p.main_image_url), alt: "", loading: "lazy" })
                : h("div", { class: "miniatura vacia", style: "width:32px;height:32px" }, "—"),
              h("div", { style: "flex:1;min-width:0" }, [
                h("div", { style: "font-weight:600;font-size:13px", text: p.name }),
                h("div", { style: "font-size:11.5px;color:var(--gris)", text: UI.gs(p.price) })
              ]),
              marcado
                ? h("div", { class: "mover", style: "display:flex;flex-direction:column;gap:1px" }, [
                    h(
                      "button",
                      {
                        type: "button", "aria-label": "Subir", disabled: i === 0,
                        style: "padding:1px 6px;font-size:9px;border:1px solid var(--linea);background:#fff;cursor:pointer",
                        onclick: function () {
                          var tmp = elegidos[i - 1]; elegidos[i - 1] = elegidos[i]; elegidos[i] = tmp;
                          pintar();
                        }
                      },
                      "▲"
                    ),
                    h(
                      "button",
                      {
                        type: "button", "aria-label": "Bajar", disabled: i === elegidos.length - 1,
                        style: "padding:1px 6px;font-size:9px;border:1px solid var(--linea);background:#fff;cursor:pointer",
                        onclick: function () {
                          var tmp = elegidos[i + 1]; elegidos[i + 1] = elegidos[i]; elegidos[i] = tmp;
                          pintar();
                        }
                      },
                      "▼"
                    )
                  ])
                : null
            ]
          )
        );
      });

      contador.textContent = elegidos.length + " de " + coleccion.max_items + " lugares usados.";
    }

    buscador.addEventListener("input", pintar);
    pintar();

    UI.abrirCajon({
      titulo: "Productos de “" + coleccion.name + "”",
      cuerpo: [
        h("div", { class: "campo" }, [buscador]),
        contador,
        lista
      ],
      acciones: [
        { label: "Cancelar", clase: "btn-plano", onclick: function () { UI.cerrarCajon(); } },
        {
          label: "Guardar selección",
          clase: "btn-primario",
          onclick: async function (e) {
            var boton = e.currentTarget;
            boton.disabled = true;
            boton.textContent = "Guardando…";

            await sb.from("product_collections").delete().eq("collection_id", coleccion.id);
            if (elegidos.length) {
              var r = await sb.from("product_collections").insert(
                elegidos.map(function (id, n) {
                  return { product_id: id, collection_id: coleccion.id, sort_order: n + 1 };
                })
              );
              if (r.error) {
                UI.noti(UI.explicar(r.error), "error");
                boton.disabled = false;
                boton.textContent = "Guardar selección";
                return;
              }
            }
            UI.cerrarCajon();
            UI.noti("Selección guardada.");
            App.recargar();
          }
        }
      ]
    });
  }
})();
