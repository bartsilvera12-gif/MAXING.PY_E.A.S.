/* MAXING.py — cliente minimo de PostgREST para el sitio publico
 *
 * El sitio publico solo necesita leer. No hace falta traer los ~120 KB de
 * @supabase/supabase-js para eso: la vidriera se abre mucho desde el celular
 * y ese peso se paga en cada visita. El panel de administracion si usa la
 * libreria oficial, porque ahi hacen falta sesiones, refresh de token y
 * subida a Storage.
 *
 * La API imita lo justo de supabase-js para que el codigo se lea igual:
 *
 *   const { data, error } = await db.from("products")
 *     .select("id, name, price")
 *     .eq("is_published", true)
 *     .order("sort_order")
 *     .limit(20);
 *
 * Todas las consultas van contra el schema `maxingpy` mediante el header
 * Accept-Profile, nunca contra `public`.
 */
(function () {
  "use strict";

  var cfg = window.MAXING_CONFIG;
  if (!cfg) throw new Error("Falta js/config.js antes de js/supabase-client.js");

  var BASE = cfg.SUPABASE_URL.replace(/\/+$/, "") + "/rest/v1/";

  function Consulta(tabla) {
    this.tabla = tabla;
    this.params = [];
    this.columnas = "*";
    this.unaFila = false;
  }

  // PostgREST espera los valores de filtro con un formato propio
  // (`campo=eq.valor`). Los strings con coma o parentesis necesitan
  // comillas o el parser los toma como lista.
  function valor(v) {
    if (v === null) return "null";
    var s = String(v);
    return /[,.()"\s]/.test(s) ? '"' + s.replace(/"/g, '\\"') + '"' : s;
  }

  Consulta.prototype.select = function (columnas) {
    if (columnas) this.columnas = columnas;
    return this;
  };
  Consulta.prototype.eq = function (campo, v) {
    this.params.push([campo, "eq." + valor(v)]);
    return this;
  };
  Consulta.prototype.neq = function (campo, v) {
    this.params.push([campo, "neq." + valor(v)]);
    return this;
  };
  Consulta.prototype.is = function (campo, v) {
    this.params.push([campo, "is." + v]);
    return this;
  };
  Consulta.prototype.in = function (campo, lista) {
    this.params.push([campo, "in.(" + lista.map(valor).join(",") + ")"]);
    return this;
  };
  Consulta.prototype.lte = function (campo, v) {
    this.params.push([campo, "lte." + valor(v)]);
    return this;
  };
  Consulta.prototype.order = function (campo, opciones) {
    var asc = !opciones || opciones.ascending !== false;
    this.params.push(["order", campo + "." + (asc ? "asc" : "desc")]);
    return this;
  };
  Consulta.prototype.limit = function (n) {
    this.params.push(["limit", String(n)]);
    return this;
  };
  Consulta.prototype.single = function () {
    this.unaFila = true;
    return this;
  };

  Consulta.prototype.url = function () {
    var qs = [["select", this.columnas]]
      .concat(this.params)
      .map(function (p) {
        return encodeURIComponent(p[0]) + "=" + encodeURIComponent(p[1]);
      })
      .join("&");
    return BASE + this.tabla + "?" + qs;
  };

  // `then` hace que la consulta sea awaitable sin llamar a nada mas, igual
  // que en supabase-js.
  Consulta.prototype.then = function (resolver, rechazar) {
    var self = this;
    var cabeceras = {
      apikey: cfg.SUPABASE_ANON_KEY,
      Authorization: "Bearer " + cfg.SUPABASE_ANON_KEY,
      "Accept-Profile": cfg.SCHEMA
    };
    if (this.unaFila) cabeceras.Accept = "application/vnd.pgrst.object+json";

    return fetch(this.url(), { headers: cabeceras, credentials: "omit" })
      .then(function (r) {
        return r.text().then(function (texto) {
          var cuerpo = null;
          try {
            cuerpo = texto ? JSON.parse(texto) : null;
          } catch (e) {
            cuerpo = null;
          }
          if (!r.ok) {
            return {
              data: null,
              error: {
                status: r.status,
                message: (cuerpo && (cuerpo.message || cuerpo.hint)) || r.statusText,
                tabla: self.tabla
              }
            };
          }
          return { data: cuerpo, error: null };
        });
      })
      .catch(function (e) {
        // Sin red, DNS caido o CORS: se devuelve un error en vez de tirar,
        // para que la pantalla pueda mostrar su estado de error.
        return { data: null, error: { status: 0, message: e.message, tabla: self.tabla } };
      })
      .then(resolver, rechazar);
  };

  window.MaxingDB = {
    from: function (tabla) {
      return new Consulta(tabla);
    },

    // Llama a una funcion de Postgres expuesta por PostgREST. La usa la
    // señal de version del contenido: una respuesta de 32 caracteres, mucho
    // mas barata que volver a bajar el catalogo para ver si cambio algo.
    rpc: function (nombre) {
      return fetch(BASE + "rpc/" + nombre, {
        method: "POST",
        headers: {
          apikey: cfg.SUPABASE_ANON_KEY,
          Authorization: "Bearer " + cfg.SUPABASE_ANON_KEY,
          "Content-Profile": cfg.SCHEMA,
          "Content-Type": "application/json"
        },
        body: "{}",
        credentials: "omit"
      })
        .then(function (r) {
          if (!r.ok) return { data: null, error: { status: r.status } };
          return r.json().then(function (d) {
            return { data: d, error: null };
          });
        })
        .catch(function (e) {
          return { data: null, error: { status: 0, message: e.message } };
        });
    },

    // URL publica de un archivo del bucket. Acepta tambien las rutas
    // relativas del catalogo viejo (./productos/...), que siguen viviendo
    // en el repositorio.
    imagen: function (ruta) {
      if (!ruta) return "";
      if (/^https?:\/\//i.test(ruta)) return ruta;
      if (/^\.?\//.test(ruta)) return ruta;
      // Rutas guardadas como "productos/foo.jpg": si el archivo esta en el
      // repo se resuelve solo; si se subio por el panel, lleva prefijo
      // "storage/" y se arma la URL del bucket.
      if (ruta.indexOf("storage/") === 0) {
        return (
          cfg.SUPABASE_URL.replace(/\/+$/, "") +
          "/storage/v1/object/public/" +
          cfg.BUCKET +
          "/" +
          ruta.slice("storage/".length)
        );
      }
      return cfg.IMAGE_BASE + ruta;
    }
  };
})();
