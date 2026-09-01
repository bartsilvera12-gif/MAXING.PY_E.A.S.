/* MAXING.py — armazon del panel
 *
 * Router por hash (#/productos), registro de modulos y estado compartido.
 * Hash y no History API porque el panel se sirve como un unico archivo
 * estatico: con rutas reales haria falta un rewrite por cada seccion.
 */
(function () {
  "use strict";

  var h = UI.h;

  var Modulos = {};
  var orden = [];

  var App = {
    perfil: null,
    // Cache de tablas cortas que casi todos los modulos necesitan
    // (categorias y marcas para los selectores de producto). Evita pedirlas
    // de nuevo en cada pantalla.
    cache: {},

    registrar: function (clave, def) {
      Modulos[clave] = def;
      orden.push(clave);
    },

    async invalidar(clave) {
      if (clave) delete this.cache[clave];
      else this.cache = {};
    },

    async categorias() {
      if (!this.cache.categorias) {
        var r = await sb.from("categories").select("id, slug, name, sort_order").order("sort_order");
        this.cache.categorias = r.data || [];
      }
      return this.cache.categorias;
    },

    async marcas() {
      if (!this.cache.marcas) {
        var r = await sb.from("brands").select("id, slug, name, sort_order").order("sort_order");
        this.cache.marcas = r.data || [];
      }
      return this.cache.marcas;
    },

    ir: function (clave) {
      location.hash = "#/" + clave;
    }
  };

  window.App = App;
  window.registrarModulo = function (clave, def) {
    App.registrar(clave, def);
  };

  /* --------------------------------------------------------------- */
  /* Iconos                                                           */
  /* --------------------------------------------------------------- */
  // La misma rampa de verdes que ordena la grilla del inicio del sitio: va de
  // lima a esmeralda. Cada sección del panel toma un tono, así el menú se lee
  // como parte de MAXING.py y no como un panel genérico.
  var VERDES = ["#86DC2C", "#6ADD2F", "#4EDE33", "#40DF36", "#2FD453", "#2FBF6B", "#24CA6B", "#1BBD83", "#16B092", "#14A28C"];

  function glifo(d) {
    return h("span", {
      class: "glifo",
      "aria-hidden": "true",
      html:
        '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" ' +
        'stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
        d +
        "</svg>"
    });
  }

  App.glifo = glifo;

  /* --------------------------------------------------------------- */
  /* Navegacion                                                       */
  /* --------------------------------------------------------------- */
  function pintarNav(nav, actual) {
    UI.vaciar(nav);

    var grupos = [];
    orden.forEach(function (clave) {
      var m = Modulos[clave];
      var g = grupos.filter(function (x) {
        return x.nombre === m.grupo;
      })[0];
      if (!g) {
        g = { nombre: m.grupo, items: [] };
        grupos.push(g);
      }
      g.items.push({ clave: clave, def: m });
    });

    // El tono se asigna por posición en el menú completo, no dentro del grupo,
    // para que la rampa recorra la barra entera de arriba a abajo.
    var n = 0;

    grupos.forEach(function (g) {
      var caja = h("div", { class: "nav-grupo" }, [
        g.nombre ? h("div", { class: "nav-grupo-titulo", text: g.nombre }) : null
      ]);

      g.items.forEach(function (it) {
        var verde = VERDES[n % VERDES.length];
        n++;
        var boton = h(
          "button",
          {
            class: "nav-item",
            type: "button",
            // El velo es el mismo color con alfa: un hex de 8 dígitos evita
            // tener que calcular la versión clara en JavaScript.
            style: "--c:" + verde + ";--c-velo:" + verde + "1f",
            "aria-current": it.clave === actual ? "page" : null,
            onclick: function () {
              App.ir(it.clave);
              nav.classList.remove("abierta");
            }
          },
          [glifo(it.def.icono), it.def.titulo]
        );
        caja.appendChild(boton);
      });

      nav.appendChild(caja);
    });
  }

  /* --------------------------------------------------------------- */
  /* Arranque                                                         */
  /* --------------------------------------------------------------- */
  var nav, tituloBarra, subBarra, cuerpo, accionesBarra;

  function armarLayout(perfil) {
    var raiz = document.getElementById("app");
    UI.vaciar(raiz);

    nav = h("nav", { class: "lateral-nav", "aria-label": "Secciones del panel" });

    var alterna = h(
      "button",
      {
        class: "btn btn-plano",
        type: "button",
        "aria-label": "Menú",
        onclick: function () {
          nav.classList.toggle("abierta");
        }
      },
      "☰"
    );
    alterna.style.display = "none";

    var iniciales = (perfil.full_name || perfil.email || "?")
      .split(/[\s@.]+/)
      .slice(0, 2)
      .map(function (p) {
        return p.charAt(0).toUpperCase();
      })
      .join("");

    var lateral = h("div", { class: "lateral" }, [
      h("div", { class: "lateral-cab" }, [
        h("span", { class: "marca-panel" }, [
          "MAXING",
          h("span", { class: "py", text: ".py" })
        ]),
        alterna
      ]),
      nav,
      h("div", { class: "nav-cuenta" }, [
        h("div", { class: "avatar", text: iniciales }),
        h("div", { class: "datos" }, [
          h("div", { class: "rol", text: etiquetaRol(perfil.role) }),
          h("div", { class: "correo", text: perfil.email })
        ]),
        h(
          "button",
          {
            class: "btn btn-plano",
            type: "button",
            "aria-label": "Cerrar sesión",
            title: "Cerrar sesión",
            onclick: async function () {
              await MaxingAuth.salir();
              location.replace("/admin/login");
            }
          },
          [glifo('<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>')]
        )
      ])
    ]);

    tituloBarra = h("h1");
    subBarra = h("span", { class: "sub" });
    accionesBarra = h("div", { style: "display:flex;gap:8px;flex-wrap:wrap" });
    cuerpo = h("div", { class: "cuerpo" });

    var contenido = h("div", { class: "contenido" }, [
      h("header", { class: "barra" }, [
        h("div", { style: "flex:1;min-width:150px" }, [tituloBarra, subBarra]),
        accionesBarra,
        h(
          "a",
          {
            class: "btn",
            href: "/",
            target: "_blank",
            rel: "noopener",
            title: "Abrir el sitio en otra pestaña"
          },
          "Ver el sitio ↗"
        )
      ]),
      cuerpo
    ]);

    raiz.appendChild(h("div", { class: "panel" }, [lateral, contenido]));

    // El boton de menu solo tiene sentido cuando el lateral se colapsa.
    var mq = window.matchMedia("(max-width: 939px)");
    function ajustar() {
      alterna.style.display = mq.matches ? "" : "none";
      if (!mq.matches) nav.classList.remove("abierta");
    }
    mq.addEventListener ? mq.addEventListener("change", ajustar) : mq.addListener(ajustar);
    ajustar();
  }

  function etiquetaRol(rol) {
    return { super_admin: "Administrador general", admin: "Administrador", editor: "Editor" }[rol] || rol;
  }

  App.acciones = function (lista) {
    UI.vaciar(accionesBarra);
    (lista || []).forEach(function (a) {
      accionesBarra.appendChild(
        h("button", { class: "btn " + (a.clase || ""), type: "button", onclick: a.onclick }, a.label)
      );
    });
  };

  /* --------------------------------------------------------------- */
  /* Router                                                           */
  /* --------------------------------------------------------------- */
  var enCurso = 0;

  async function enrutar() {
    var clave = (location.hash || "").replace(/^#\/?/, "") || orden[0];
    if (!Modulos[clave]) clave = orden[0];
    var def = Modulos[clave];

    pintarNav(nav, clave);
    tituloBarra.textContent = def.titulo;
    subBarra.textContent = def.sub || "";
    App.acciones([]);
    UI.cerrarCajon();

    var barraCarga = h("div", { class: "cargando" });
    document.body.appendChild(barraCarga);

    var mio = ++enCurso;

    // Se dibuja en un contenedor suelto y recien se cuelga si esta navegacion
    // sigue siendo la vigente. Si el usuario cambia de seccion mientras una
    // consulta esta en vuelo, la que llega tarde se descarta en vez de mezclar
    // su contenido con el de la seccion nueva.
    var destino = h("div");

    try {
      await def.render(destino, App);
      if (mio !== enCurso) return;
      UI.vaciar(cuerpo).appendChild(destino);
    } catch (e) {
      if (mio === enCurso) {
        UI.vaciar(cuerpo).appendChild(
          h("div", { class: "aviso error" }, [
            h("div", null, [
              h("strong", null, "No se pudo cargar esta sección. "),
              UI.explicar(e)
            ])
          ])
        );
      }
      // Se deja en consola para poder diagnosticar sin adivinar.
      console.error("[panel]", clave, e);
    } finally {
      if (barraCarga.parentNode) barraCarga.parentNode.removeChild(barraCarga);
    }

    // Al cambiar de seccion se vuelve arriba: quedar a media pagina de la
    // seccion anterior desorienta.
    window.scrollTo(0, 0);
  }

  App.recargar = enrutar;

  window.addEventListener("hashchange", enrutar);

  App.iniciar = async function () {
    var perfil = await MaxingAuth.verificar();
    if (!perfil) {
      MaxingAuth.alIngreso();
      return;
    }
    App.perfil = perfil;
    armarLayout(perfil);
    // replaceState y no location.replace: cambiar el hash con location.replace
    // dispara un hashchange, que ya llama a enrutar(), y la pantalla terminaba
    // dibujandose dos veces en paralelo sobre el mismo contenedor.
    if (!location.hash) history.replaceState(null, "", "#/" + orden[0]);
    await enrutar();

    // Si la sesion se cae (token vencido, cierre desde otra pestana), se
    // vuelve al ingreso en vez de dejar una pantalla que ya no puede guardar.
    sb.auth.onAuthStateChange(function (evento) {
      if (evento === "SIGNED_OUT") location.replace("/admin/login");
    });
  };
})();
