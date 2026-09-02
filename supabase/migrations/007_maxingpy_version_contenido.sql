-- =====================================================================
-- MAXING.py — 007: señal de versión del contenido
-- =====================================================================
-- Sirve para que la vidriera se entere de que el panel cambió algo sin
-- tener que volver a bajar todo el catálogo cada vez que pregunta.
--
-- Devuelve un hash corto que resume el estado de todas las tablas de
-- contenido. El sitio lo consulta cada tanto —es una respuesta de 32
-- caracteres— y solo cuando el hash cambia vuelve a pedir los datos
-- completos.
--
-- Por qué esto y no Realtime: el websocket de Realtime
-- (wss://api.neura.com.py/realtime/v1/websocket) hoy rechaza la conexión
-- desde el navegador. Cuando ese servicio quede habilitado, el sitio puede
-- suscribirse y esta función deja de hacer falta; hasta entonces, esto da
-- el mismo resultado con un costo mínimo.
--
-- Toma en cuenta la fecha del último cambio Y la cantidad de filas: sin el
-- conteo, borrar un registro pasaría desapercibido, porque un borrado no
-- deja updated_at en ninguna parte.
-- =====================================================================

create or replace function maxingpy.contenido_version()
returns text
language sql
stable
security definer
set search_path = maxingpy, pg_temp
as $fn$
  select md5(
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.products)          || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.categories)        || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.brands)            || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.collections)       || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.hero_slides)       || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.content_sections)  || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.benefits)          || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.footer_items)      || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.social_links)      || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.site_settings)     || '|' ||
    (select coalesce(max(updated_at)::text, '') || ':' || count(*) from maxingpy.seo_pages)         || '|' ||
    -- Las tablas hijas no tienen updated_at; alcanza con el conteo, porque
    -- cualquier edición desde el panel toca además la fila del producto.
    (select count(*)::text from maxingpy.product_categories)  || '|' ||
    (select count(*)::text from maxingpy.product_collections) || '|' ||
    (select count(*)::text from maxingpy.product_features)    || '|' ||
    (select count(*)::text from maxingpy.product_images)      || '|' ||
    (select count(*)::text from maxingpy.product_specs)
  );
$fn$;

-- SECURITY DEFINER para que el conteo no dependa de lo que cada visitante
-- pueda ver. No filtra nada: devuelve un hash, no contenido.
revoke all on function maxingpy.contenido_version() from public;
grant execute on function maxingpy.contenido_version() to anon, authenticated;

comment on function maxingpy.contenido_version() is
  'Hash del estado del contenido. La vidriera lo consulta para saber si tiene que recargar.';
