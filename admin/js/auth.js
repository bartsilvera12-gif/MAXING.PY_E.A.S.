/* MAXING.py — sesion del panel
 *
 * Estar autenticado NO alcanza para entrar. Cualquiera podria registrarse
 * contra el mismo proyecto de Supabase; lo que habilita el panel es tener
 * fila activa en maxingpy.admin_profiles.
 *
 * Esta comprobacion es de conveniencia (mostrar el panel o mandar al
 * ingreso). La proteccion real esta en RLS: aunque alguien saltee esta
 * pantalla, Postgres le va a rechazar cualquier escritura.
 */
(function () {
  "use strict";

  var sb = window.sb;

  var Auth = {
    perfil: null,

    // Devuelve el perfil de admin si la sesion es valida, o null.
    // Si hay sesion pero no es admin, cierra la sesion: dejarla abierta
    // solo confunde a quien vuelve a intentar.
    async verificar() {
      var ses = await sb.auth.getSession();
      if (!ses.data.session) return null;

      var r = await sb
        .from("admin_profiles")
        .select("id, email, full_name, role, is_active")
        .eq("id", ses.data.session.user.id)
        .maybeSingle();

      if (r.error || !r.data || !r.data.is_active) {
        await sb.auth.signOut();
        return null;
      }

      this.perfil = r.data;
      return r.data;
    },

    async ingresar(email, password) {
      var r = await sb.auth.signInWithPassword({ email: email, password: password });
      if (r.error) {
        // Supabase devuelve el mismo error para usuario inexistente y
        // contrasena incorrecta, a proposito. No se afina el mensaje:
        // distinguirlos permitiria averiguar que correos existen.
        return { ok: false, mensaje: mensajeDeError(r.error) };
      }

      var perfil = await this.verificar();
      if (!perfil) {
        return {
          ok: false,
          mensaje: "Esta cuenta no tiene acceso al panel. Pedile a un administrador que la habilite."
        };
      }

      // Se registra el ingreso. Si falla no se corta el acceso: es un dato
      // informativo, no una condicion para entrar.
      sb.from("admin_profiles")
        .update({ last_login: new Date().toISOString() })
        .eq("id", perfil.id)
        .then(function () {}, function () {});

      return { ok: true, perfil: perfil };
    },

    async salir() {
      await sb.auth.signOut();
      this.perfil = null;
    },

    puede(minimo) {
      if (!this.perfil) return false;
      var orden = { editor: 1, admin: 2, super_admin: 3 };
      return (orden[this.perfil.role] || 0) >= (orden[minimo] || 99);
    },

    // Manda al ingreso conservando a donde queria ir.
    alIngreso() {
      var destino = location.pathname + location.hash;
      location.replace("/admin/login?volver=" + encodeURIComponent(destino));
    }
  };

  function mensajeDeError(error) {
    var m = (error && error.message) || "";
    if (/invalid login credentials/i.test(m)) return "Correo o contraseña incorrectos.";
    if (/email not confirmed/i.test(m)) return "La cuenta todavía no fue confirmada.";
    if (/rate limit|too many/i.test(m)) return "Demasiados intentos. Esperá un momento.";
    if (/fetch|network/i.test(m)) return "No se pudo conectar con el servidor.";
    return m || "No se pudo iniciar sesión.";
  }

  window.MaxingAuth = Auth;
})();
