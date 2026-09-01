/* MAXING.py — utilidades de interfaz del panel
 *
 * Sin framework. El panel maneja pocas pantallas y listas cortas, asi que
 * un constructor de elementos y unos pocos helpers alcanzan, y evitan
 * sumar una dependencia mas al proyecto.
 */
(function () {
  "use strict";

  /* --------------------------------------------------------------- */
  /* Construccion de elementos                                        */
  /* --------------------------------------------------------------- */
  // h("div", {class: "x"}, [h("span", null, "hola")])
  // El texto se asigna siempre con textContent, nunca con innerHTML: los
  // nombres de producto vienen de la base y no deben poder inyectar markup.
  function h(tag, attrs, hijos) {
    var el = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        var v = attrs[k];
        if (v === null || v === undefined || v === false) return;
        if (k === "class") el.className = v;
        else if (k === "text") el.textContent = v;
        else if (k === "html") el.innerHTML = v; // solo para iconos propios
        else if (k === "style") el.setAttribute("style", v);
        else if (k.indexOf("on") === 0 && typeof v === "function") {
          el.addEventListener(k.slice(2).toLowerCase(), v);
        } else if (v === true) el.setAttribute(k, "");
        else el.setAttribute(k, v);
      });
    }
    (Array.isArray(hijos) ? hijos : hijos == null ? [] : [hijos]).forEach(function (c) {
      if (c === null || c === undefined || c === false) return;
      el.appendChild(typeof c === "object" ? c : document.createTextNode(String(c)));
    });
    return el;
  }

  function vaciar(el) {
    while (el.firstChild) el.removeChild(el.firstChild);
    return el;
  }

  /* --------------------------------------------------------------- */
  /* Color                                                            */
  /* --------------------------------------------------------------- */
  // La misma rampa de verdes que ordena la grilla del inicio del sitio, de
  // lima a esmeralda. Se usa en el menu lateral y en las etiquetas de marca.
  var VERDES = ["#86DC2C", "#6ADD2F", "#4EDE33", "#40DF36", "#2FD453", "#2FBF6B", "#24CA6B", "#1BBD83", "#16B092", "#14A28C"];

  // Color estable para un texto: la misma marca siempre recibe el mismo tono,
  // en esta y en cualquier otra pantalla. Se calcula del nombre en vez de
  // guardarlo, asi una marca nueva ya viene con color sin tener que elegirlo.
  function colorDe(texto) {
    var t = String(texto || "");
    var n = 0;
    for (var i = 0; i < t.length; i++) n = (n * 31 + t.charCodeAt(i)) % 100000;
    return VERDES[n % VERDES.length];
  }

  // Etiqueta de color para un valor de texto (marca, categoria).
  function chipColor(texto) {
    if (!texto) return h("span", { style: "color:var(--gris)" }, "—");
    var c = colorDe(texto);
    return h("span", {
      class: "chip chip-color",
      style: "--c:" + c + ";--c-velo:" + c + "24",
      text: texto
    });
  }

  /* --------------------------------------------------------------- */
  /* Formato                                                          */
  /* --------------------------------------------------------------- */
  // Guaranies: sin decimales y con punto de miles, como en el sitio.
  function gs(n) {
    var v = Number(n);
    if (!isFinite(v)) return "—";
    return "Gs. " + Math.round(v).toLocaleString("es-PY").replace(/,/g, ".");
  }

  function fecha(iso) {
    if (!iso) return "—";
    var d = new Date(iso);
    if (isNaN(d)) return "—";
    return d.toLocaleDateString("es-PY", { day: "2-digit", month: "short", year: "numeric" });
  }

  // Slug propuesto a partir del nombre. Editable: el admin puede corregirlo,
  // pero no se regenera solo despues de publicar, porque cambiarlo romperia
  // los enlaces que ya circulan.
  function slugificar(txt) {
    return String(txt || "")
      .toLowerCase()
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 80);
  }

  /* --------------------------------------------------------------- */
  /* Notificaciones                                                   */
  /* --------------------------------------------------------------- */
  var pilaNotis = null;

  function noti(texto, tipo) {
    if (!pilaNotis) {
      pilaNotis = h("div", { class: "notis", role: "status", "aria-live": "polite" });
      document.body.appendChild(pilaNotis);
    }
    var n = h("div", { class: "noti " + (tipo || "ok"), text: texto });
    pilaNotis.appendChild(n);
    setTimeout(function () {
      n.style.transition = "opacity .25s ease";
      n.style.opacity = "0";
      setTimeout(function () {
        if (n.parentNode) n.parentNode.removeChild(n);
      }, 260);
    }, tipo === "error" ? 6000 : 3200);
  }

  // Traduce el error de PostgREST a algo que el admin pueda accionar.
  function explicar(error) {
    if (!error) return "";
    var m = error.message || "";
    if (error.code === "23505" || /duplicate key/i.test(m)) {
      return "Ya existe un registro con ese identificador (slug o SKU).";
    }
    if (error.code === "23503" || /foreign key/i.test(m)) {
      return "No se puede completar: hay otros registros que dependen de este.";
    }
    if (error.code === "42501" || /row-level security|permission denied/i.test(m)) {
      return "Tu cuenta no tiene permiso para esta acción.";
    }
    if (/JWT|token/i.test(m)) return "La sesión venció. Volvé a ingresar.";
    if (/fetch|network|failed to fetch/i.test(m)) return "No se pudo conectar con el servidor.";
    return m || "Ocurrió un error inesperado.";
  }

  /* --------------------------------------------------------------- */
  /* Cajon lateral                                                    */
  /* --------------------------------------------------------------- */
  var cajonAbierto = null;

  function abrirCajon(opciones) {
    cerrarCajon();

    var velo = h("div", { class: "velo", onclick: pedirCierre });
    var titulo = h("h2", { text: opciones.titulo });
    var cuerpo = h("div", { class: "cajon-cuerpo" }, opciones.cuerpo);

    var acciones = (opciones.acciones || []).map(function (a) {
      return h(
        "button",
        {
          class: "btn " + (a.clase || ""),
          type: "button",
          onclick: a.onclick,
          "data-accion": a.id || null
        },
        a.label
      );
    });

    var cajon = h("aside", { class: "cajon", role: "dialog", "aria-modal": "true", "aria-label": opciones.titulo }, [
      h("div", { class: "cajon-cab" }, [
        titulo,
        h("button", { class: "btn btn-plano", type: "button", onclick: pedirCierre, "aria-label": "Cerrar" }, "✕")
      ]),
      cuerpo,
      h("div", { class: "cajon-pie" }, acciones)
    ]);

    document.body.appendChild(velo);
    document.body.appendChild(cajon);
    document.body.style.overflow = "hidden";

    cajonAbierto = { velo: velo, cajon: cajon, alCerrar: opciones.alCerrar, sucio: opciones.sucio };
    document.addEventListener("keydown", teclaEscape);

    // Foco al primer control, que es lo que se va a querer editar.
    var primero = cajon.querySelector("input, select, textarea, button:not([aria-label='Cerrar'])");
    if (primero) primero.focus();

    return { cajon: cajon, cuerpo: cuerpo, cerrar: cerrarCajon };
  }

  function teclaEscape(e) {
    if (e.key === "Escape") pedirCierre();
  }

  // No se cierra en seco si hay cambios sin guardar: perder un formulario
  // largo por un Escape es una forma tonta de perder trabajo.
  function pedirCierre() {
    if (cajonAbierto && typeof cajonAbierto.sucio === "function" && cajonAbierto.sucio()) {
      if (!confirm("Hay cambios sin guardar. ¿Cerrar igual?")) return;
    }
    cerrarCajon();
  }

  function cerrarCajon() {
    if (!cajonAbierto) return;
    document.removeEventListener("keydown", teclaEscape);
    if (cajonAbierto.velo.parentNode) cajonAbierto.velo.parentNode.removeChild(cajonAbierto.velo);
    if (cajonAbierto.cajon.parentNode) cajonAbierto.cajon.parentNode.removeChild(cajonAbierto.cajon);
    document.body.style.overflow = "";
    var cb = cajonAbierto.alCerrar;
    cajonAbierto = null;
    if (cb) cb();
  }

  /* --------------------------------------------------------------- */
  /* Controles de formulario                                          */
  /* --------------------------------------------------------------- */
  function campo(opciones) {
    var id = "c_" + Math.random().toString(36).slice(2, 9);
    var control;

    if (opciones.tipo === "textarea") {
      control = h("textarea", {
        id: id,
        rows: opciones.filas || 4,
        placeholder: opciones.placeholder || null
      });
      control.value = opciones.valor == null ? "" : opciones.valor;
    } else if (opciones.tipo === "select") {
      control = h(
        "select",
        { id: id },
        (opciones.opciones || []).map(function (o) {
          var op = h("option", { value: o.valor }, o.label);
          if (String(o.valor) === String(opciones.valor)) op.selected = true;
          return op;
        })
      );
    } else {
      control = h("input", {
        id: id,
        type: opciones.tipo || "text",
        placeholder: opciones.placeholder || null,
        min: opciones.min != null ? opciones.min : null,
        step: opciones.step || null,
        autocomplete: "off"
      });
      control.value = opciones.valor == null ? "" : opciones.valor;
    }

    if (opciones.onInput) control.addEventListener("input", opciones.onInput);
    if (opciones.requerido) control.required = true;

    var envoltorio = h("div", { class: "campo" }, [
      h("label", { class: "etiqueta", for: id }, opciones.label),
      control,
      opciones.pista ? h("span", { class: "pista", text: opciones.pista }) : null
    ]);

    envoltorio.control = control;
    return envoltorio;
  }

  function interruptor(label, valor, onCambio) {
    var input = h("input", { type: "checkbox" });
    input.checked = !!valor;
    if (onCambio) input.addEventListener("change", function () { onCambio(input.checked); });
    var el = h("label", { class: "interruptor" }, [
      input,
      h("span", { class: "pista-sw" }),
      h("span", { class: "texto-sw", text: label })
    ]);
    el.control = input;
    return el;
  }

  // Lista de textos reordenable: caracteristicas, specs, imagenes.
  function listaEditable(opciones) {
    var valores = (opciones.valores || []).slice();
    var cont = h("div", { class: "lista-edit" });

    function pintar() {
      vaciar(cont);
      valores.forEach(function (v, i) {
        var input = h("input", { type: "text", placeholder: opciones.placeholder || "" });
        input.value = v;
        input.addEventListener("input", function () {
          valores[i] = input.value;
        });

        cont.appendChild(
          h("div", { class: "renglon" }, [
            h("div", { class: "mover" }, [
              h(
                "button",
                {
                  type: "button",
                  "aria-label": "Subir",
                  disabled: i === 0,
                  onclick: function () {
                    var t = valores[i - 1];
                    valores[i - 1] = valores[i];
                    valores[i] = t;
                    pintar();
                  }
                },
                "▲"
              ),
              h(
                "button",
                {
                  type: "button",
                  "aria-label": "Bajar",
                  disabled: i === valores.length - 1,
                  onclick: function () {
                    var t = valores[i + 1];
                    valores[i + 1] = valores[i];
                    valores[i] = t;
                    pintar();
                  }
                },
                "▼"
              )
            ]),
            input,
            h(
              "button",
              {
                class: "btn btn-plano",
                type: "button",
                "aria-label": "Quitar",
                onclick: function () {
                  valores.splice(i, 1);
                  pintar();
                }
              },
              "✕"
            )
          ])
        );
      });

      cont.appendChild(
        h(
          "button",
          {
            class: "btn",
            type: "button",
            style: "align-self:flex-start;margin-top:2px",
            onclick: function () {
              valores.push("");
              pintar();
              var inputs = cont.querySelectorAll("input");
              if (inputs.length) inputs[inputs.length - 1].focus();
            }
          },
          opciones.textoAgregar || "+ Agregar"
        )
      );
    }

    pintar();

    var envoltorio = h("div", { class: "campo" }, [
      h("span", { class: "etiqueta", text: opciones.label }),
      opciones.pista ? h("span", { class: "pista", style: "margin:-2px 0 7px", text: opciones.pista }) : null,
      cont
    ]);

    envoltorio.leer = function () {
      return valores
        .map(function (v) {
          return String(v).trim();
        })
        .filter(Boolean);
    };
    return envoltorio;
  }

  /* --------------------------------------------------------------- */
  /* Subida de imagenes a Storage                                     */
  /* --------------------------------------------------------------- */
  // Devuelve una ruta con prefijo "storage/", que es como el frontend
  // distingue una imagen subida por el panel de las que siguen viviendo en
  // el repositorio (./productos/...).
  async function subirArchivo(archivo, carpeta) {
    if (!archivo) return null;
    if (archivo.size > 5 * 1024 * 1024) {
      throw new Error("La imagen pesa más de 5 MB. Reducila antes de subirla.");
    }
    var ext = (archivo.name.split(".").pop() || "jpg").toLowerCase();
    // Nombre unico: reusar el nombre original haria que una imagen nueva
    // quedara tapada por la cache del navegador y de Vercel.
    var nombre =
      carpeta +
      "/" +
      Date.now().toString(36) +
      "-" +
      Math.random().toString(36).slice(2, 8) +
      "." +
      ext;

    var r = await window.sbStorage.upload(nombre, archivo, {
      cacheControl: "31536000",
      upsert: false,
      contentType: archivo.type || undefined
    });
    if (r.error) throw new Error(explicar(r.error));
    return "storage/" + nombre;
  }

  // URL mostrable de una ruta guardada.
  function urlImagen(ruta) {
    if (!ruta) return "";
    if (/^https?:\/\//i.test(ruta)) return ruta;
    if (ruta.indexOf("storage/") === 0) {
      return window.sbStorage.getPublicUrl(ruta.slice("storage/".length)).data.publicUrl;
    }
    // Imagen del catalogo original, servida desde el propio sitio.
    return "/" + ruta.replace(/^\.?\//, "");
  }

  // Control completo de imagen: vista previa, subir, o pegar una ruta.
  function selectorImagen(opciones) {
    var ruta = opciones.valor || "";

    var vista = h("img", { class: "vista", alt: "" });
    var sinFoto = h("div", { class: "vista", style: "display:grid;place-items:center;color:#b8beb8;font-size:11px" }, "sin imagen");

    var entrada = h("input", { type: "file", accept: "image/*", style: "display:none" });
    var manual = h("input", { type: "text", placeholder: "productos/archivo.jpg" });
    var zona = h("div", { class: "zona-suelta", text: "Subir imagen o arrastrarla acá" });
    var contVista = h("div", { style: "flex:none" });

    function refrescar() {
      vaciar(contVista);
      manual.value = ruta;
      if (ruta) {
        vista.src = urlImagen(ruta);
        contVista.appendChild(vista);
      } else {
        contVista.appendChild(sinFoto);
      }
    }

    async function tomar(archivo) {
      if (!archivo) return;
      zona.textContent = "Subiendo…";
      try {
        ruta = await subirArchivo(archivo, opciones.carpeta || "products");
        refrescar();
        noti("Imagen subida.");
      } catch (e) {
        noti(e.message, "error");
      }
      zona.textContent = "Subir imagen o arrastrarla acá";
    }

    zona.addEventListener("click", function () {
      entrada.click();
    });
    zona.addEventListener("dragover", function (e) {
      e.preventDefault();
      zona.classList.add("encima");
    });
    zona.addEventListener("dragleave", function () {
      zona.classList.remove("encima");
    });
    zona.addEventListener("drop", function (e) {
      e.preventDefault();
      zona.classList.remove("encima");
      tomar(e.dataTransfer.files[0]);
    });
    entrada.addEventListener("change", function () {
      tomar(entrada.files[0]);
    });
    manual.addEventListener("input", function () {
      ruta = manual.value.trim();
      refrescar();
    });

    refrescar();

    var envoltorio = h("div", { class: "campo" }, [
      h("span", { class: "etiqueta", text: opciones.label }),
      h("div", { class: "subida" }, [
        contVista,
        h("div", { class: "controles" }, [
          zona,
          entrada,
          h("span", { class: "pista", style: "margin:8px 0 4px", text: "o escribí la ruta si la imagen ya está en el sitio" }),
          manual
        ])
      ])
    ]);

    envoltorio.leer = function () {
      return ruta || null;
    };
    return envoltorio;
  }

  /* --------------------------------------------------------------- */
  /* Confirmacion                                                     */
  /* --------------------------------------------------------------- */
  function confirmarBorrado(queCosa) {
    return confirm(
      "¿Eliminar " + queCosa + "?\n\nEsta acción no se puede deshacer."
    );
  }

  // Boton de borrado para una fila de la tabla, sin tener que abrir el
  // formulario. Va en gris y recien se pone rojo al pasar por encima: es la
  // unica accion del panel que no se puede deshacer, y no conviene que grite
  // desde todos los renglones.
  function botonEliminar(opciones) {
    return h(
      "button",
      {
        class: "btn btn-plano btn-borrar",
        type: "button",
        title: "Eliminar",
        onclick: async function (e) {
          e.stopPropagation();
          if (!confirmarBorrado("“" + opciones.nombre + "”")) return;

          var boton = e.currentTarget;
          boton.disabled = true;
          boton.textContent = "Eliminando…";

          var r = await window.sb
            .from(opciones.tabla)
            .delete()
            .eq(opciones.pk || "id", opciones.id);

          if (r.error) {
            noti(explicar(r.error), "error");
            boton.disabled = false;
            boton.textContent = "Eliminar";
            return;
          }
          noti("Eliminado.");
          if (opciones.alTerminar) opciones.alTerminar();
        }
      },
      "Eliminar"
    );
  }

  window.UI = {
    h: h,
    vaciar: vaciar,
    gs: gs,
    fecha: fecha,
    slugificar: slugificar,
    noti: noti,
    explicar: explicar,
    abrirCajon: abrirCajon,
    cerrarCajon: cerrarCajon,
    campo: campo,
    interruptor: interruptor,
    listaEditable: listaEditable,
    selectorImagen: selectorImagen,
    subirArchivo: subirArchivo,
    urlImagen: urlImagen,
    confirmarBorrado: confirmarBorrado,
    VERDES: VERDES,
    colorDe: colorDe,
    chipColor: chipColor,
    botonEliminar: botonEliminar
  };
})();
