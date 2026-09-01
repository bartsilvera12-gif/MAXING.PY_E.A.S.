/* MAXING.py — modulo Productos */
(function () {
  "use strict";

  var h = UI.h;

  var ESTADOS = ["Disponible", "Bajo pedido", "Sin stock"];

  var filtro = { q: "", categoria: "", estado: "", publicado: "" };

  registrarModulo("productos", {
    titulo: "Productos",
    sub: "Catálogo completo del sitio",
    grupo: "Catálogo",
    icono: '<path d="M20 7 12 3 4 7v10l8 4 8-4V7Z"/><path d="m4 7 8 4 8-4"/><path d="M12 21V11"/>',

    async render(cont, app) {
      var categorias = await app.categorias();
      var marcas = await app.marcas();

      app.acciones([
        {
          label: "+ Nuevo producto",
          clase: "btn-primario",
          onclick: function () {
            editar(null, categorias, marcas);
          }
        }
      ]);

      var tabla = h("div");
      cont.appendChild(barraFiltros(categorias, function () { pintar(tabla, categorias, marcas); }));
      cont.appendChild(tabla);
      await pintar(tabla, categorias, marcas);
    }
  });

  /* --------------------------------------------------------------- */
  function barraFiltros(categorias, alCambiar) {
    var buscador = h("input", { type: "search", placeholder: "Buscar por nombre, SKU o marca…" });
    buscador.value = filtro.q;

    // Se espera a que deje de escribir: una consulta por tecla es ruido
    // para el servidor y parpadeo para quien mira.
    var temporizador;
    buscador.addEventListener("input", function () {
      clearTimeout(temporizador);
      temporizador = setTimeout(function () {
        filtro.q = buscador.value.trim();
        alCambiar();
      }, 220);
    });

    function selector(clave, vacio, opciones) {
      var s = h(
        "select",
        {
          onchange: function () {
            filtro[clave] = s.value;
            alCambiar();
          }
        },
        [h("option", { value: "" }, vacio)].concat(
          opciones.map(function (o) {
            var op = h("option", { value: o.valor }, o.label);
            if (o.valor === filtro[clave]) op.selected = true;
            return op;
          })
        )
      );
      return s;
    }

    return h("div", { class: "herramientas" }, [
      h("div", { class: "buscador" }, [
        h("span", {
          html:
            '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>'
        }),
        buscador
      ]),
      selector("categoria", "Todas las categorías", categorias.map(function (c) {
        return { valor: c.id, label: c.name };
      })),
      selector("estado", "Toda disponibilidad", ESTADOS.map(function (e) {
        return { valor: e, label: e };
      })),
      selector("publicado", "Publicados y borradores", [
        { valor: "si", label: "Solo publicados" },
        { valor: "no", label: "Solo borradores" }
      ])
    ]);
  }

  /* --------------------------------------------------------------- */
  async function pintar(cont, categorias, marcas) {
    UI.vaciar(cont).appendChild(esqueleto());

    var q = sb
      .from("products")
      .select(
        "id, slug, sku, name, price, old_price, is_on_sale, discount_percent, stock_status," +
          " main_image_url, is_published, is_featured, sort_order, updated_at," +
          " brand:brands(name), product_categories(category_id)"
      )
      .order("sort_order");

    if (filtro.estado) q = q.eq("stock_status", filtro.estado);
    if (filtro.publicado) q = q.eq("is_published", filtro.publicado === "si");
    if (filtro.q) {
      // `or` con ilike cubre los tres campos por los que se busca a mano.
      var t = "%" + filtro.q.replace(/[,()]/g, " ") + "%";
      q = q.or("name.ilike." + t + ",sku.ilike." + t + ",short_spec.ilike." + t);
    }

    var r = await q;
    if (r.error) throw r.error;

    var filas = r.data || [];
    if (filtro.categoria) {
      filas = filas.filter(function (p) {
        return (p.product_categories || []).some(function (x) {
          return x.category_id === filtro.categoria;
        });
      });
    }

    UI.vaciar(cont);

    if (!filas.length) {
      cont.appendChild(
        h("div", { class: "tarjeta" }, [
          h("div", { class: "vacio" }, [
            h("h3", null, "No hay productos que coincidan"),
            h("p", null, filtro.q || filtro.categoria || filtro.estado || filtro.publicado
              ? "Probá quitando algún filtro."
              : "Cargá el primero con el botón “Nuevo producto”.")
          ])
        ])
      );
      return;
    }

    var cuerpo = h("tbody");
    filas.forEach(function (p) {
      cuerpo.appendChild(fila(p, categorias, marcas));
    });

    cont.appendChild(
      h("div", { class: "tarjeta" }, [
        h("div", { class: "tarjeta-cab" }, [
          h("h2", null, [
            filas.length + (filas.length === 1 ? " producto" : " productos"),
            h("span", { class: "nota", text: contarPublicados(filas) })
          ])
        ]),
        h("div", { class: "tabla-marco" }, [
          h("table", { class: "tabla" }, [
            h("thead", null, [
              h("tr", null, [
                h("th", null, "Producto"),
                h("th", null, "Marca"),
                h("th", { class: "num" }, "Precio"),
                h("th", null, "Disponibilidad"),
                h("th", null, "Estado"),
                h("th", { class: "acciones" }, "")
              ])
            ]),
            cuerpo
          ])
        ])
      ])
    );
  }

  function contarPublicados(filas) {
    var pub = filas.filter(function (p) {
      return p.is_published;
    }).length;
    var ofertas = filas.filter(function (p) {
      return p.is_on_sale;
    }).length;
    return pub + " publicados · " + (filas.length - pub) + " en borrador" +
      (ofertas ? " · " + ofertas + " en oferta" : "");
  }

  function fila(p, categorias, marcas) {
    var foto = p.main_image_url
      ? h("img", { class: "miniatura", src: UI.urlImagen(p.main_image_url), alt: "", loading: "lazy" })
      : h("div", { class: "miniatura vacia" }, "—");

    var precio = h("div", null, [
      h("div", { class: "precio", text: UI.gs(p.price) }),
      p.is_on_sale
        ? h("div", { style: "font-size:11.5px;color:var(--gris);text-decoration:line-through", text: UI.gs(p.old_price) })
        : null
    ]);

    // Verde disponible, ámbar a pedido, rojo sin stock.
    var CLASE_STOCK = { "Disponible": "stock-ok", "Bajo pedido": "stock-espera", "Sin stock": "stock-agotado" };

    return h("tr", null, [
      h("td", null, [
        h("div", { class: "celda-prod" }, [
          foto,
          h("div", null, [
            h("div", { class: "nombre", text: p.name }),
            h("div", { class: "meta", text: p.sku || "sin SKU" })
          ])
        ])
      ]),
      h("td", null, [UI.chipColor((p.brand && p.brand.name) || "")]),
      h("td", { class: "num" }, [precio]),
      h("td", null, [
        h("span", {
          class: "insignia " + (CLASE_STOCK[p.stock_status] || "sin-punto"),
          text: p.stock_status
        })
      ]),
      h("td", null, [
        h("span", {
          class: "insignia " + (p.is_published ? "publicado" : "borrador"),
          text: p.is_published ? "Publicado" : "Borrador"
        }),
        p.is_on_sale ? h("span", { class: "insignia oferta", style: "margin-left:5px", text: "-" + p.discount_percent + "%" }) : null,
        p.is_featured ? h("span", { class: "chip", style: "margin-left:5px", text: "Destacado" }) : null
      ]),
      h("td", { class: "acciones" }, [
        h(
          "button",
          {
            class: "btn btn-plano",
            type: "button",
            onclick: function () {
              editar(p.id, categorias, marcas);
            }
          },
          "Editar"
        ),
        // Al borrar el producto se van con él sus categorías, características,
        // ficha técnica e imágenes: la base lo hace en cascada.
        UI.botonEliminar({
          nombre: p.name,
          tabla: "products",
          id: p.id,
          alTerminar: function () { App.recargar(); }
        })
      ])
    ]);
  }

  function esqueleto() {
    var filas = [];
    for (var i = 0; i < 6; i++) {
      filas.push(
        h("div", { style: "display:flex;gap:12px;align-items:center;padding:12px 16px;border-bottom:1px solid var(--linea-suave)" }, [
          h("div", { class: "esqueleto", style: "width:40px;height:40px;border-radius:7px;flex:none" }),
          h("div", { class: "esqueleto", style: "width:" + (26 + ((i * 13) % 34)) + "%" }),
          h("div", { class: "esqueleto", style: "width:70px;margin-left:auto" })
        ])
      );
    }
    return h("div", { class: "tarjeta" }, filas);
  }

  /* --------------------------------------------------------------- */
  /* Alta y edicion                                                   */
  /* --------------------------------------------------------------- */
  async function editar(id, categorias, marcas) {
    var p = {
      name: "", slug: "", sku: "", brand_id: "", short_spec: "", description: "",
      price: "", old_price: "", stock_status: "Disponible", main_image_url: "",
      image_alt: "", is_published: false, is_featured: false, sort_order: 0,
      meta_title: "", meta_description: ""
    };
    var catsElegidas = [];
    var features = [];
    var specs = [];

    if (id) {
      var r = await sb
        .from("products")
        .select("*, product_categories(category_id), product_features(feature, sort_order), product_specs(spec_key, spec_value, sort_order)")
        .eq("id", id)
        .single();
      if (r.error) {
        UI.noti(UI.explicar(r.error), "error");
        return;
      }
      p = r.data;
      catsElegidas = (p.product_categories || []).map(function (x) {
        return x.category_id;
      });
      features = (p.product_features || [])
        .sort(function (a, b) { return a.sort_order - b.sort_order; })
        .map(function (x) { return x.feature; });
      specs = (p.product_specs || [])
        .sort(function (a, b) { return a.sort_order - b.sort_order; })
        .map(function (x) { return x.spec_key + " | " + x.spec_value; });
    }

    /* ---- controles ---- */
    var fNombre = UI.campo({
      label: "Nombre", valor: p.name, requerido: true,
      placeholder: "Katana 15 B14WEK-001US",
      onInput: function () {
        // El slug se propone solo mientras el producto es nuevo. En uno ya
        // publicado no se toca: cambiarlo romperia los enlaces que circulan.
        if (!id && !slugTocado) fSlug.control.value = UI.slugificar(fNombre.control.value);
      }
    });

    var slugTocado = !!id;
    var fSlug = UI.campo({
      label: "Identificador en la URL (slug)", valor: p.slug, requerido: true,
      pista: id ? "Cambiarlo rompe los enlaces que ya circulan." : "Se propone solo desde el nombre.",
      onInput: function () { slugTocado = true; }
    });

    var fSku = UI.campo({ label: "SKU", valor: p.sku, placeholder: "B14WEK-001US" });

    var fMarca = UI.campo({
      label: "Marca", tipo: "select", valor: p.brand_id,
      opciones: [{ valor: "", label: "— Sin marca —" }].concat(
        marcas.map(function (m) { return { valor: m.id, label: m.name }; })
      )
    });

    var fSpec = UI.campo({
      label: "Línea técnica corta", valor: p.short_spec,
      pista: "La que se ve debajo del nombre en la ficha del catálogo.",
      placeholder: "Core i7-14650HX · RTX 5050 8 GB · 16 GB / 512 GB"
    });

    var fPrecio = UI.campo({
      label: "Precio (Gs.)", tipo: "number", valor: p.price, min: 0, step: 1000, requerido: true
    });

    var fPrecioViejo = UI.campo({
      label: "Precio anterior (Gs.)", tipo: "number", valor: p.old_price == null ? "" : p.old_price, min: 0, step: 1000,
      pista: "Dejalo vacío si no está en oferta.",
      onInput: refrescarOferta
    });
    fPrecio.control.addEventListener("input", refrescarOferta);

    var avisoOferta = h("div", { class: "aviso", style: "margin:-4px 0 16px" });

    function refrescarOferta() {
      var nuevo = Number(fPrecio.control.value);
      var viejo = Number(fPrecioViejo.control.value);
      if (!fPrecioViejo.control.value || !(viejo > nuevo)) {
        avisoOferta.hidden = true;
        return;
      }
      var pct = Math.round(((viejo - nuevo) * 100) / viejo);
      avisoOferta.hidden = false;
      avisoOferta.className = "aviso ok";
      // El descuento no se escribe a mano: lo calcula Postgres a partir de
      // estos dos precios. Aca solo se muestra lo que va a quedar.
      UI.vaciar(avisoOferta).appendChild(
        h("div", null, [
          h("strong", null, "Queda en oferta: -" + pct + "%. "),
          "La etiqueta se calcula sola desde los dos precios."
        ])
      );
    }

    var fEstado = UI.campo({
      label: "Disponibilidad", tipo: "select", valor: p.stock_status,
      opciones: ESTADOS.map(function (e) { return { valor: e, label: e }; })
    });

    var fOrden = UI.campo({
      label: "Orden", tipo: "number", valor: p.sort_order, min: 0,
      pista: "Menor número, aparece antes."
    });

    var fFoto = UI.selectorImagen({ label: "Foto principal", valor: p.main_image_url, carpeta: "products" });
    var fAlt = UI.campo({
      label: "Texto alternativo de la foto", valor: p.image_alt,
      pista: "Lo leen los lectores de pantalla y los buscadores."
    });

    var fDesc = UI.campo({
      label: "Descripción", tipo: "textarea", filas: 9, valor: p.description,
      pista: "Separá los párrafos con una línea en blanco."
    });

    /* categorias */
    var casillas = h("div", { class: "casillas" });
    categorias.forEach(function (c) {
      var input = h("input", { type: "checkbox", value: c.id });
      input.checked = catsElegidas.indexOf(c.id) !== -1;
      casillas.appendChild(h("label", { class: "casilla" }, [input, c.name]));
    });

    var fFeatures = UI.listaEditable({
      label: "Características",
      valores: features,
      placeholder: "Intel Core i7-14650HX",
      textoAgregar: "+ Agregar característica"
    });

    var fSpecs = UI.listaEditable({
      label: "Ficha técnica",
      valores: specs,
      pista: "Un dato por línea, con el formato  Clave | Valor",
      placeholder: "Pantalla | 15,6 pulgadas",
      textoAgregar: "+ Agregar dato"
    });

    var swPublicado = UI.interruptor("Publicado en el sitio", p.is_published);
    var swDestacado = UI.interruptor("Marcar como destacado", p.is_featured);

    var fMetaTitulo = UI.campo({ label: "Título SEO", valor: p.meta_title, pista: "Si lo dejás vacío se usa el nombre." });
    var fMetaDesc = UI.campo({ label: "Descripción SEO", tipo: "textarea", filas: 3, valor: p.meta_description });

    refrescarOferta();

    var cuerpo = [
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Identificación"),
        fNombre, fSlug,
        h("div", { class: "fila" }, [fSku, fMarca]),
        fSpec
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Precio y disponibilidad"),
        h("div", { class: "fila" }, [fPrecio, fPrecioViejo]),
        avisoOferta,
        h("div", { class: "fila" }, [fEstado, fOrden])
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Imagen"),
        fFoto, fAlt
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Categorías"),
        casillas
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Contenido"),
        fDesc, fFeatures, fSpecs
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Publicación"),
        swPublicado, swDestacado
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "SEO"),
        fMetaTitulo, fMetaDesc
      ])
    ];

    var acciones = [
      {
        label: "Cancelar",
        clase: "btn-plano",
        onclick: function () { UI.cerrarCajon(); }
      },
      {
        label: id ? "Guardar cambios" : "Crear producto",
        clase: "btn-primario",
        onclick: guardar
      }
    ];

    if (id) {
      acciones.unshift({
        label: "Eliminar",
        clase: "btn-peligro izq",
        onclick: async function () {
          if (!UI.confirmarBorrado("el producto “" + p.name + "”")) return;
          var r = await sb.from("products").delete().eq("id", id);
          if (r.error) { UI.noti(UI.explicar(r.error), "error"); return; }
          UI.cerrarCajon();
          UI.noti("Producto eliminado.");
          App.recargar();
        }
      });
    }

    UI.abrirCajon({
      titulo: id ? "Editar producto" : "Nuevo producto",
      cuerpo: cuerpo,
      acciones: acciones
    });

    /* ---- guardado ---- */
    async function guardar(e) {
      var boton = e.currentTarget;
      var datos = {
        name: fNombre.control.value.trim(),
        slug: fSlug.control.value.trim() || UI.slugificar(fNombre.control.value),
        sku: fSku.control.value.trim() || null,
        brand_id: fMarca.control.value || null,
        short_spec: fSpec.control.value.trim() || null,
        description: fDesc.control.value.trim() || null,
        price: Number(fPrecio.control.value) || 0,
        old_price: fPrecioViejo.control.value === "" ? null : Number(fPrecioViejo.control.value),
        stock_status: fEstado.control.value,
        main_image_url: fFoto.leer(),
        image_alt: fAlt.control.value.trim() || null,
        is_published: swPublicado.control.checked,
        is_featured: swDestacado.control.checked,
        sort_order: Number(fOrden.control.value) || 0,
        meta_title: fMetaTitulo.control.value.trim() || null,
        meta_description: fMetaDesc.control.value.trim() || null
      };

      if (!datos.name) { UI.noti("Falta el nombre.", "error"); fNombre.control.focus(); return; }
      if (!datos.slug) { UI.noti("Falta el identificador.", "error"); fSlug.control.focus(); return; }
      if (datos.old_price != null && datos.old_price <= datos.price) {
        UI.noti("El precio anterior tiene que ser mayor al precio actual, o quedar vacío.", "error");
        fPrecioViejo.control.focus();
        return;
      }
      // Publicar sin foto deja una ficha rota en la vidriera.
      if (datos.is_published && !datos.main_image_url) {
        UI.noti("Un producto publicado necesita foto. Subila o dejalo en borrador.", "error");
        return;
      }

      boton.disabled = true;
      boton.textContent = "Guardando…";

      try {
        var idProd = id;
        if (id) {
          var u = await sb.from("products").update(datos).eq("id", id);
          if (u.error) throw u.error;
        } else {
          var i = await sb.from("products").insert(datos).select("id").single();
          if (i.error) throw i.error;
          idProd = i.data.id;
        }

        var elegidas = Array.prototype.slice
          .call(casillas.querySelectorAll("input:checked"))
          .map(function (x) { return x.value; });

        // Las relaciones y listas se reemplazan enteras. Son pocas filas por
        // producto y evita tener que calcular altas, bajas y reordenamientos.
        await sb.from("product_categories").delete().eq("product_id", idProd);
        if (elegidas.length) {
          var rc = await sb.from("product_categories").insert(
            elegidas.map(function (cid, n) {
              return { product_id: idProd, category_id: cid, is_primary: n === 0 };
            })
          );
          if (rc.error) throw rc.error;
        }

        await sb.from("product_features").delete().eq("product_id", idProd);
        var lf = fFeatures.leer();
        if (lf.length) {
          var rf = await sb.from("product_features").insert(
            lf.map(function (t, n) { return { product_id: idProd, feature: t, sort_order: n + 1 }; })
          );
          if (rf.error) throw rf.error;
        }

        await sb.from("product_specs").delete().eq("product_id", idProd);
        var ls = fSpecs.leer()
          .map(function (t) {
            var partes = t.split("|");
            return { k: (partes[0] || "").trim(), v: partes.slice(1).join("|").trim() };
          })
          .filter(function (x) { return x.k && x.v; });
        if (ls.length) {
          var rs = await sb.from("product_specs").insert(
            ls.map(function (x, n) {
              return { product_id: idProd, spec_key: x.k, spec_value: x.v, sort_order: n + 1 };
            })
          );
          if (rs.error) throw rs.error;
        }

        // La foto principal se mantiene como primera imagen de la galeria.
        await sb.from("product_images").delete().eq("product_id", idProd);
        if (datos.main_image_url) {
          await sb.from("product_images").insert({
            product_id: idProd,
            image_url: datos.main_image_url,
            alt_text: datos.image_alt,
            sort_order: 1
          });
        }

        UI.cerrarCajon();
        UI.noti(id ? "Producto actualizado." : "Producto creado.");
        App.recargar();
      } catch (err) {
        UI.noti(UI.explicar(err), "error");
        boton.disabled = false;
        boton.textContent = id ? "Guardar cambios" : "Crear producto";
      }
    }
  }
})();
