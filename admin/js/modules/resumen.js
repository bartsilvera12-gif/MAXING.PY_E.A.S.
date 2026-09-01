/* MAXING.py — pantalla de inicio del panel
 *
 * No es un tablero decorativo: muestra lo que hay y, sobre todo, lo que
 * esta a medias — productos sin foto, categorias vacias, datos del pie que
 * el cliente todavia no entrego. Cada aviso lleva a la pantalla donde se
 * arregla.
 */
(function () {
  "use strict";

  var h = UI.h;

  registrarModulo("resumen", {
    titulo: "Resumen",
    sub: "Estado del sitio",
    grupo: null,
    icono: '<rect x="3" y="3" width="8" height="10" rx="1.5"/><rect x="13" y="3" width="8" height="6" rx="1.5"/><rect x="13" y="13" width="8" height="8" rx="1.5"/><rect x="3" y="17" width="8" height="4" rx="1.5"/>',

    async render(cont, app) {
      var r = await Promise.all([
        sb.from("products").select("id, name, is_published, main_image_url, is_on_sale, stock_status, product_categories(category_id)"),
        sb.from("categories").select("id, name, is_active"),
        sb.from("brands").select("id, name, is_active"),
        sb.from("footer_items").select("id, title, is_pending, pending_note").eq("is_pending", true)
      ]);

      var fallo = r.find(function (x) { return x.error; });
      if (fallo) throw fallo.error;

      var productos = r[0].data || [];
      var categorias = r[1].data || [];
      var marcas = r[2].data || [];
      var pendientes = r[3].data || [];

      var publicados = productos.filter(function (p) { return p.is_published; });
      var sinFoto = productos.filter(function (p) { return !p.main_image_url; });
      var borradores = productos.filter(function (p) { return !p.is_published; });
      var enOferta = publicados.filter(function (p) { return p.is_on_sale; });
      var sinStock = publicados.filter(function (p) { return p.stock_status === "Sin stock"; });

      // Una categoria activa sin productos publicados no se ve en el sitio.
      // No es un error, pero conviene que el admin lo sepa.
      var usadas = {};
      publicados.forEach(function (p) {
        (p.product_categories || []).forEach(function (x) { usadas[x.category_id] = true; });
      });
      var vacias = categorias.filter(function (c) { return c.is_active && !usadas[c.id]; });

      /* --- metricas --- */
      cont.appendChild(
        h("div", { class: "metricas" }, [
          metrica("Productos publicados", publicados.length, borradores.length + " en borrador"),
          metrica("Categorías con productos", categorias.length - vacias.length, "de " + categorias.length + " activas"),
          metrica("Marcas activas", marcas.filter(function (m) { return m.is_active; }).length, null),
          metrica("En oferta", enOferta.length, enOferta.length ? "calculado desde los precios" : "ninguno ahora")
        ])
      );

      /* --- pendientes --- */
      var avisos = [];

      if (sinFoto.length) {
        avisos.push(
          aviso(
            "atencion",
            sinFoto.length === 1 ? "1 producto sin foto" : sinFoto.length + " productos sin foto",
            "El sitio no muestra productos sin foto, ni siquiera publicados. " +
              nombres(sinFoto),
            "Ver productos",
            "productos"
          )
        );
      }

      if (vacias.length) {
        avisos.push(
          aviso(
            "atencion",
            vacias.length === 1 ? "1 categoría sin productos" : vacias.length + " categorías sin productos",
            "No aparecen en el sitio hasta que tengan al menos un producto publicado: " +
              vacias.map(function (c) { return c.name; }).join(", ") + ".",
            "Ver categorías",
            "categorias"
          )
        );
      }

      if (pendientes.length) {
        avisos.push(
          aviso(
            "atencion",
            "Faltan datos del pie de página",
            pendientes
              .map(function (f) { return f.pending_note || f.title; })
              .join(" · ") + ".",
            "Completar",
            "pie"
          )
        );
      }

      if (sinStock.length) {
        avisos.push(
          aviso(
            "",
            sinStock.length === 1 ? "1 producto sin stock" : sinStock.length + " productos sin stock",
            "Siguen visibles en el sitio con la etiqueta “Sin stock”. " + nombres(sinStock),
            "Ver productos",
            "productos"
          )
        );
      }

      if (avisos.length) {
        cont.appendChild(
          h("div", { class: "tarjeta" }, [
            h("div", { class: "tarjeta-cab" }, [
              h("h2", null, [
                "Para revisar",
                h("span", { class: "nota", text: "Nada de esto rompe el sitio, pero conviene resolverlo." })
              ])
            ]),
            h("div", { class: "tarjeta-cuerpo" }, avisos)
          ])
        );
      } else {
        cont.appendChild(
          h("div", { class: "tarjeta" }, [
            h("div", { class: "tarjeta-cuerpo" }, [
              h("div", { class: "aviso ok" }, [
                h("div", null, [
                  h("strong", null, "Todo en orden. "),
                  "No hay productos sin foto, categorías vacías ni datos pendientes."
                ])
              ])
            ])
          ])
        );
      }

      /* --- accesos --- */
      cont.appendChild(
        h("div", { class: "tarjeta" }, [
          h("div", { class: "tarjeta-cab" }, [h("h2", null, "Accesos rápidos")]),
          h("div", { class: "tarjeta-cuerpo", style: "display:flex;gap:9px;flex-wrap:wrap" }, [
            atajo("Cargar un producto", "productos"),
            atajo("Editar “Quiénes somos”", "secciones"),
            atajo("Cambiar el hero", "hero"),
            atajo("Ofertas y destacados", "colecciones"),
            atajo("Contacto y WhatsApp", "ajustes")
          ])
        ])
      );
    }
  });

  function metrica(rotulo, valor, pie) {
    return h("div", { class: "metrica" }, [
      h("div", { class: "rotulo", text: rotulo }),
      h("div", { class: "valor", text: String(valor) }),
      pie ? h("div", { class: "pie", text: pie }) : null
    ]);
  }

  function nombres(lista) {
    var n = lista.slice(0, 3).map(function (p) { return p.name; });
    return n.join(", ") + (lista.length > 3 ? " y " + (lista.length - 3) + " más." : ".");
  }

  function aviso(tipo, titulo, texto, etiqueta, destino) {
    return h("div", { class: "aviso " + tipo, style: "align-items:center" }, [
      h("div", { style: "flex:1" }, [h("strong", null, titulo + ". "), texto]),
      h(
        "button",
        {
          class: "btn",
          type: "button",
          style: "flex:none",
          onclick: function () { App.ir(destino); }
        },
        etiqueta
      )
    ]);
  }

  function atajo(etiqueta, destino) {
    return h(
      "button",
      { class: "btn", type: "button", onclick: function () { App.ir(destino); } },
      etiqueta
    );
  }
})();
