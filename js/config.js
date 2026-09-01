/* MAXING.py — configuracion de Supabase (publica)
 *
 * Lo de este archivo va al navegador y es visible para cualquiera. Esta
 * bien: la anon key esta disenada para eso. Lo que impide que un visitante
 * escriba en la base no es esconder esta clave, sino las politicas RLS de
 * Postgres (supabase/migrations/002_maxingpy_rls.sql).
 *
 * NUNCA agregar aca la service_role key ni la contrasena de Postgres. La
 * service_role se saltea RLS por completo: si llega al navegador, cualquier
 * persona puede borrar el catalogo entero.
 */
window.MAXING_CONFIG = {
  SUPABASE_URL: "https://api.neura.com.py",

  // Rol `anon`, solo lectura de lo publicado. Publica por diseno.
  SUPABASE_ANON_KEY:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MTAxNDYxLCJleHAiOjE5MzE3ODE0NjF9.7_wAph8IolPMXtgfpezSwS5XR62IdD__qhqCywLDp3Q",

  // Todas las tablas del negocio viven en este schema, nunca en `public`.
  SCHEMA: "maxingpy",

  // Bucket de imagenes.
  BUCKET: "maxingpy",

  // Mientras las imagenes sigan sirviendose desde el repo (./productos/...)
  // en vez de Storage, las rutas relativas se resuelven contra el sitio.
  // Cuando el admin sube una imagen nueva, queda como URL absoluta de
  // Storage y este prefijo no se aplica. Convive el catalogo viejo con el
  // que se cargue desde el panel.
  IMAGE_BASE: "./"
};
