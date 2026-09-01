/* MAXING.py — cliente de Supabase para el panel
 *
 * A diferencia del sitio publico, el panel si usa la libreria oficial:
 * necesita sesiones, refresco automatico del token y subida a Storage.
 *
 * SOLO se usa la anon key. La service_role NUNCA entra aca: se saltea RLS
 * por completo, y todo lo que este archivo carga termina en el navegador
 * de quien abra el panel. Que un usuario pueda editar el catalogo lo
 * decide RLS a partir de su sesion, no esta clave.
 */
(function () {
  "use strict";

  var cfg = window.MAXING_CONFIG;
  if (!cfg) throw new Error("Falta js/config.js");
  if (!window.supabase || !window.supabase.createClient) {
    throw new Error("No cargo @supabase/supabase-js");
  }

  var cliente = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
      storageKey: "maxingpy.admin.auth"
    },
    // Todas las consultas del panel van al schema del negocio.
    db: { schema: cfg.SCHEMA }
  });

  window.sb = cliente;

  // Storage vive fuera del schema, asi que se expone aparte para no
  // confundirlo con las tablas.
  window.sbStorage = cliente.storage.from(cfg.BUCKET);
})();
