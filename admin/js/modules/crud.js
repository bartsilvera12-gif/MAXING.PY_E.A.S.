/* MAXING.py — fabrica de modulos CRUD
 *
 * Categorias, marcas, colecciones, beneficios, pie y redes son la misma
 * pantalla con distintos campos: una tabla y un cajon con un formulario.
 * En vez de escribir seis modulos casi identicos, se describen los campos
 * y esta fabrica arma la pantalla.
 *
 * Productos no usa esto: tiene relaciones (categorias, caracteristicas,
 * ficha tecnica, galeria) que no entran en un formulario plano.
 */
(function () {
  "use strict";

  var h = UI.h;

  function control(campo, valor) {
    if (campo.tipo === "imagen") {
      return UI.selectorImagen({ label: campo.label, valor: valor, carpeta: campo.carpeta || "sections" });
    }
    if (campo.tipo === "switch") {
      var sw = UI.interruptor(campo.label, valor == null ? campo.pordefecto !== false : valor);
      sw.leer = function () { return sw.control.checked; };
      return sw;
    }
    if (campo.tipo === "color") {
      var c = UI.campo({ label: campo.label, valor: valor || "", placeholder: "#40DF36", pista: campo.pista });
      var muestra = h("span", {
        style:
          "display:inline-block;width:15px;height:15px;border-radius:4px;border:1px solid var(--linea);" +
          "vertical-align:-2px;margin-right:6px;background:" + (valor || "transparent")
      });
      c.querySelector(".etiqueta").insertBefore(muestra, c.querySelector(".etiqueta").firstChild);
      c.control.addEventListener("input", function () {
        muestra.style.background = c.control.value || "transparent";
      });
      c.leer = function () { return c.control.value.trim() || null; };
      return c;
    }

    var campoUI = UI.campo({
      label: campo.label,
      tipo: campo.tipo || "text",
      filas: campo.filas,
      valor: valor == null ? (campo.pordefecto == null ? "" : campo.pordefecto) : valor,
      placeholder: campo.placeholder,
      pista: campo.pista,
      min: campo.min,
      // Un modulo puede pasar las opciones como funcion cuando dependen de
      // algo que se carga al entrar a la pantalla, como los temas de la FAQ.
      // Sin resolverla aca llegaba la funcion cruda y el cajon no abria.
      opciones: typeof campo.opciones === "function" ? campo.opciones() : campo.opciones
    });
    campoUI.leer = function () {
      var v = campoUI.control.value;
      if (campo.tipo === "number") return v === "" ? null : Number(v);
      v = String(v).trim();
      return v === "" ? null : v;
    };
    return campoUI;
  }

  // Reacomoda el orden de una tabla después de guardar.
  //
  // Sin esto, poner 1 en un registro dejaba dos con el número 1 y el desempate
  // quedaba al azar. Ahora el registro se mete en la posición pedida y los
  // demás corren un lugar, como cuando se inserta una carta en un mazo.
  //
  // `alcance` limita el reordenamiento a un subconjunto: el pie de página
  // ordena por separado las tarjetas operativas y la columna de ayuda, así que
  // mover una no debe tocar las otras.
  async function reordenar(tabla, id, pedido, alcance, valorAlcance) {
    // Sin saber a que grupo pertenece la fila no se puede reordenar: hacerlo
    // sobre toda la tabla mezclaria grupos que se ordenan por separado.
    if (alcance && valorAlcance == null) return;

    var q = sb.from(tabla).select("id, sort_order").order("sort_order");
    if (alcance) q = q.eq(alcance, valorAlcance);
    var r = await q;
    if (r.error || !r.data) return;

    var otros = r.data.filter(function (f) { return f.id !== id; });
    // El pedido se acota a lo posible: 0 o un número gigante no deberían
    // dejar la lista con huecos.
    var pos = Math.max(1, Math.min(Number(pedido) || otros.length + 1, otros.length + 1));
    otros.splice(pos - 1, 0, { id: id, sort_order: pos });

    // Solo se escriben las filas que de verdad cambiaron de número.
    for (var i = 0; i < otros.length; i++) {
      var nuevo = i + 1;
      if (otros[i].sort_order === nuevo) continue;
      var u = await sb.from(tabla).update({ sort_order: nuevo }).eq("id", otros[i].id);
      if (u.error) return;
    }
  }

  window.reordenarTabla = reordenar;

  window.crudSimple = function (def) {
    registrarModulo(def.clave, {
      titulo: def.titulo,
      sub: def.sub,
      grupo: def.grupo,
      icono: def.icono,

      async render(cont, app) {
        // Un modulo puede necesitar datos antes de dibujarse: los temas y las
        // categorias que llenan sus selectores, por ejemplo.
        if (def.preparar) await def.preparar(app);

        if (def.nota) {
          cont.appendChild(h("div", { class: "aviso" }, [h("div", null, def.nota)]));
        }

        if (!def.soloEdicion) {
          app.acciones([
            {
              label: "+ " + (def.singular || "Nuevo"),
              clase: "btn-primario",
              onclick: function () { abrir(null); }
            }
          ]);
        }

        var caja = h("div");
        cont.appendChild(caja);
        await pintar();

        async function pintar() {
          var q = sb.from(def.tabla).select(def.select || "*");
          (def.orden || ["sort_order"]).forEach(function (o) {
            q = q.order(o);
          });
          var r = await q;
          if (r.error) throw r.error;

          var filas = r.data || [];
          UI.vaciar(caja);

          if (!filas.length) {
            caja.appendChild(
              h("div", { class: "tarjeta" }, [
                h("div", { class: "vacio" }, [
                  h("h3", null, "Todavía no hay nada acá"),
                  h("p", null, def.vacio || "Creá el primer registro.")
                ])
              ])
            );
            return;
          }

          var tbody = h("tbody");
          filas.forEach(function (f) {
            var celdas = def.columnas.map(function (col) {
              return h("td", { class: col.clase || null }, [col.render ? col.render(f) : String(f[col.k] == null ? "—" : f[col.k])]);
            });
            celdas.push(
              h("td", { class: "acciones" }, [
                h(
                  "button",
                  { class: "btn btn-plano", type: "button", onclick: function () { abrir(f); } },
                  "Editar"
                ),
                // Las secciones de contenido no se borran: el sitio las busca
                // por clave y el panel no podria volver a crearlas. Se ocultan.
                def.sinBorrado
                  ? null
                  : UI.botonEliminar({
                      nombre: def.nombreDe ? def.nombreDe(f) : f.name || f.title || f.label || "este registro",
                      tabla: def.tabla,
                      id: f[def.pk || "id"],
                      pk: def.pk,
                      alTerminar: function () { App.invalidar(); App.recargar(); }
                    })
              ])
            );
            tbody.appendChild(h("tr", null, celdas));
          });

          caja.appendChild(
            h("div", { class: "tarjeta" }, [
              h("div", { class: "tarjeta-cab" }, [
                h("h2", null, [
                  filas.length + " " + (filas.length === 1 ? def.contadorSingular || "registro" : def.contadorPlural || "registros"),
                  def.subtitulo ? h("span", { class: "nota", text: def.subtitulo }) : null
                ])
              ]),
              h("div", { class: "tabla-marco" }, [
                h("table", { class: "tabla" }, [
                  h("thead", null, [
                    h("tr", null, def.columnas
                      .map(function (c) { return h("th", { class: c.clase || null }, c.label); })
                      .concat([h("th", { class: "acciones" }, "")]))
                  ]),
                  tbody
                ])
              ])
            ])
          );
        }

        function abrir(fila) {
          var controles = {};
          var bloques = [];
          var grupoActual = null;
          var contGrupo = null;

          def.campos.forEach(function (campo) {
            // Un campo puede no aplicar a este registro. Se usa para no
            // ofrecer subir una imagen en una seccion que el sitio dibuja sin
            // imagen: seria una foto que nunca se ve.
            if (campo.mostrarSi && !campo.mostrarSi(fila || {})) return;

            if (campo.grupo !== grupoActual || !contGrupo) {
              grupoActual = campo.grupo;
              contGrupo = h("fieldset", { class: "bloque" }, [
                grupoActual ? h("legend", null, grupoActual) : null
              ]);
              bloques.push(contGrupo);
            }
            var c = control(campo, fila ? fila[campo.k] : undefined);
            controles[campo.k] = c;
            contGrupo.appendChild(c);
          });

          // Un grupo puede quedar sin ningun campo visible; en ese caso se
          // saca, para no dejar un titulo suelto sobre la nada.
          bloques = bloques.filter(function (b) {
            return b.querySelector(".campo, .interruptor");
          });

          // El slug se escribe solo mientras se tipea el nombre, pero SOLO en
          // un registro nuevo. En uno que ya existe no se toca: el slug es la
          // URL, y cambiarlo romperia los enlaces que ya circulan. Tambien
          // deja de seguir al nombre en cuanto alguien lo edita a mano.
          def.campos.forEach(function (campo) {
            if (!campo.desde || fila) return;
            var destino = controles[campo.k];
            var origen = controles[campo.desde];
            if (!destino || !origen) return;

            var tocadoAMano = false;
            destino.control.addEventListener("input", function () { tocadoAMano = true; });
            origen.control.addEventListener("input", function () {
              if (tocadoAMano) return;
              destino.control.value = UI.slugificar(origen.control.value);
            });
          });

          // Un modulo puede sumar controles propios —relaciones, listas— que
          // no entran en un campo plano. Se dibujan al final y se guardan con
          // el hook `alGuardar`.
          var extras = def.extras ? def.extras(fila) : null;
          if (extras) bloques.push(extras.nodo || extras);

          var acciones = [
            { label: "Cancelar", clase: "btn-plano", onclick: function () { UI.cerrarCajon(); } },
            {
              label: fila ? "Guardar cambios" : "Crear",
              clase: "btn-primario",
              onclick: guardar
            }
          ];

          if (fila && !def.sinBorrado) {
            acciones.unshift({
              label: "Eliminar",
              clase: "btn-peligro izq",
              onclick: async function () {
                var nombre = def.nombreDe ? def.nombreDe(fila) : fila.name || fila.title || "este registro";
                if (!UI.confirmarBorrado("“" + nombre + "”")) return;
                var r = await sb.from(def.tabla).delete().eq(def.pk || "id", fila[def.pk || "id"]);
                if (r.error) { UI.noti(UI.explicar(r.error), "error"); return; }
                UI.cerrarCajon();
                UI.noti("Eliminado.");
                App.invalidar();
                App.recargar();
              }
            });
          }

          UI.abrirCajon({
            titulo: fila ? "Editar " + (def.singular || "registro").toLowerCase() : "Nuevo " + (def.singular || "registro").toLowerCase(),
            cuerpo: bloques,
            acciones: acciones
          });

          async function guardar(e) {
            var boton = e.currentTarget;
            var datos = {};
            def.campos.forEach(function (campo) {
              if (campo.soloLectura) return;
              // Un campo oculto para este registro no se toca: se deja como
              // esta en la base en vez de escribirle null.
              if (!controles[campo.k]) return;
              datos[campo.k] = controles[campo.k].leer();
            });

            var problema = def.validar ? def.validar(datos, controles) : null;
            if (problema) { UI.noti(problema, "error"); return; }

            boton.disabled = true;
            boton.textContent = "Guardando…";
            try {
              var r;
              if (fila) {
                r = await sb.from(def.tabla).update(datos).eq(def.pk || "id", fila[def.pk || "id"]);
              } else {
                r = await sb.from(def.tabla).insert(datos).select("id").single();
              }
              if (r.error) throw r.error;
              if (def.alGuardar) {
                await def.alGuardar(fila, datos, extras, r);
              }

              // Si la tabla se ordena a mano, se reacomoda el resto.
              if ("sort_order" in datos) {
                var idGuardado = fila ? fila[def.pk || "id"] : r.data && r.data.id;
                if (idGuardado) {
                  await reordenar(def.tabla, idGuardado, datos.sort_order,
                    def.alcanceOrden, datos[def.alcanceOrden]);
                }
              }
              UI.cerrarCajon();
              UI.noti(fila ? "Cambios guardados." : "Creado.");
              App.invalidar();
              App.recargar();
            } catch (err) {
              UI.noti(UI.explicar(err), "error");
              boton.disabled = false;
              boton.textContent = fila ? "Guardar cambios" : "Crear";
            }
          }
        }
      }
    });
  };

  /* Celdas reutilizables ------------------------------------------- */
  window.celda = {
    imagen: function (clave) {
      return function (f) {
        return f[clave]
          ? h("img", { class: "miniatura", src: UI.urlImagen(f[clave]), alt: "", loading: "lazy" })
          : h("div", { class: "miniatura vacia" }, "—");
      };
    },
    principal: function (claveTitulo, claveMeta) {
      return function (f) {
        return h("div", null, [
          h("div", { class: "nombre", style: "font-weight:600;color:var(--negro)", text: f[claveTitulo] || "—" }),
          claveMeta && f[claveMeta]
            ? h("div", { class: "meta", style: "font-size:12px;color:var(--gris)", text: f[claveMeta] })
            : null
        ]);
      };
    },
    estado: function (clave, textoSi, textoNo) {
      return function (f) {
        return h("span", {
          class: "insignia " + (f[clave] ? "publicado" : "borrador"),
          text: f[clave] ? textoSi || "Activo" : textoNo || "Oculto"
        });
      };
    },
    texto: function (clave, corte) {
      return function (f) {
        var v = f[clave] == null ? "—" : String(f[clave]);
        return h("span", { text: corte && v.length > corte ? v.slice(0, corte) + "…" : v });
      };
    }
  };
})();
