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
          " main_image_url, is_published, sort_order, updated_at," +
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
        p.is_on_sale ? h("span", { class: "insignia oferta", style: "margin-left:5px", text: "-" + p.discount_percent + "%" }) : null
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
      image_alt: "", is_published: false, sort_order: 0
    };
    var catsElegidas = [];
    var features = [];
    var specs = [];
    var galeria = [];
    var relacionados = [];

    // Catalogo liviano para el buscador de relacionados: solo lo necesario
    // para listar y reconocer un producto, no la ficha entera.
    var catalogoLiviano = (await sb
      .from("products")
      .select("id, name, sku, price, main_image_url, brand:brands(name)")
      .order("name")).data || [];

    if (id) {
      var r = await sb
        .from("products")
        .select("*, product_categories(category_id), product_features(feature, sort_order), product_specs(spec_key, spec_value, sort_order), product_images(image_url, sort_order), product_relations!product_relations_product_id_fkey(related_product_id, relation_type, sort_order)")
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
      galeria = (p.product_images || [])
        .sort(function (a, b) { return a.sort_order - b.sort_order; })
        .map(function (x) { return x.image_url; });
      // Un producto cargado antes de que hubiera galería tiene su foto en
      // main_image_url y puede no estar en la lista: se agrega para que
      // aparezca en la grilla y no parezca que se perdió.
      if (p.main_image_url && galeria.indexOf(p.main_image_url) === -1) {
        galeria.unshift(p.main_image_url);
      }
      relacionados = (p.product_relations || [])
        .sort(function (a, b) { return a.sort_order - b.sort_order; })
        .map(function (x) { return { id: x.related_product_id, tipo: x.relation_type }; });
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

    // Varias fotos por producto. La marcada con estrella es la principal y
    // es la que va a products.main_image_url, que es la que ve el catalogo.
    var fFotos = UI.galeriaImagenes({
      label: "Imágenes",
      valores: galeria,
      principal: p.main_image_url,
      carpeta: "products"
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

    // El grupo SEO se saco del formulario. Los tres campos de “compartir”
    // (titulo, descripcion e imagen) nunca hicieron nada: el sitio tiene sus
    // etiquetas og: fijas en el encabezado y jamas leia esos valores. Los
    // otros tres si servian, pero el sitio ya los arma solo: el titulo con la
    // marca y el nombre, la descripcion con la ficha corta y la URL canonica
    // con /productos/<slug>. Las columnas siguen en la base: si alguna vez
    // hay un valor cargado, se sigue respetando.

    // --- Productos relacionados ---
    var fRelacionados = UI.selectorProductos({
      valores: relacionados,
      // El propio producto no puede relacionarse consigo mismo.
      excluir: id,
      catalogo: catalogoLiviano
    });


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
        fFotos
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
        h("legend", null, "Productos relacionados"),
        h("span", {
          class: "pista",
          style: "margin:0 0 10px",
          text:
            "La ficha muestra un bloque por tipo. Lo que elijas al lado de cada " +
            "producto es el título de la sección donde va a aparecer."
        }),
        fRelacionados
      ]),
      h("fieldset", { class: "bloque" }, [
        h("legend", null, "Publicación"),
        swPublicado
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
        main_image_url: fFotos.leer().principal,
        // El texto alternativo no se pide: se usa el nombre del producto, que
        // es lo que hay que describir en una foto de producto.
        image_alt: null,
        is_published: swPublicado.control.checked,
        sort_order: Number(fOrden.control.value) || 0
        // Los campos SEO no se escriben: se dejan como esten en la base.
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

        // La galería se guarda entera, con la principal primera: así el sitio
        // la muestra arriba de todo sin tener que ordenar nada.
        var fotos = fFotos.leer();
        var orden = fotos.imagenes.slice().sort(function (a, b) {
          if (a === fotos.principal) return -1;
          if (b === fotos.principal) return 1;
          return 0;
        });

        await sb.from("product_images").delete().eq("product_id", idProd);
        if (orden.length) {
          var ri = await sb.from("product_images").insert(
            orden.map(function (url, n) {
              return {
                product_id: idProd,
                image_url: url,
                // El texto alternativo sale del nombre del producto: para una
                // foto de producto es justo lo que corresponde describir, y
                // evita un campo mas que nadie completa.
                alt_text: datos.name,
                sort_order: n + 1
              };
            })
          );
          if (ri.error) throw ri.error;
        }

        // Productos relacionados. Se reemplaza la lista entera, igual que las
        // demás relaciones: son pocas filas por producto.
        await sb.from("product_relations").delete().eq("product_id", idProd);
        var rels = fRelacionados.leer();
        if (rels.length) {
          var rr = await sb.from("product_relations").insert(
            rels.map(function (x, n) {
              return {
                product_id: idProd,
                related_product_id: x.id,
                relation_type: x.tipo || "related",
                sort_order: n + 1,
                is_active: true
              };
            })
          );
          if (rr.error) throw rr.error;
        }

        // El orden se acomoda solo: poner un producto en 1 corre al resto un
        // lugar, en vez de dejar dos con el mismo numero.
        await reordenarTabla("products", idProd, datos.sort_order);

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
