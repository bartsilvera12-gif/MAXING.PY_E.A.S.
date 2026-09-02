-- =====================================================================
-- MAXING.py — 009: limpiar la imagen de las secciones que no la muestran
-- =====================================================================
-- La sección "redes" quedó con una imagen cargada de cuando el panel
-- todavía ofrecía subirla. El sitio la dibuja como un bloque de título,
-- bajada y enlaces, sin lugar para una foto, así que esa imagen no se ve
-- en ninguna parte.
--
-- Se borra la referencia. El panel ya no ofrece subir imágenes en esas
-- secciones (ver admin/js/modules/contenido.js), así que no vuelve a
-- pasar.
--
-- El archivo en sí sigue en Storage: borrarlo desde SQL dejaría el blob
-- huérfano en el disco del servidor, porque el borrado prolijo lo hace la
-- API de Storage. Se elimina desde Supabase Studio → Storage → maxingpy →
-- sections, o queda ahí ocupando unos KB sin molestar a nadie.
--
-- Idempotente.
-- =====================================================================

update maxingpy.content_sections
   set image_url = null,
       image_alt = null,
       image_side = 'none'
 where section_key in ('redes')
   and (image_url is not null or image_alt is not null);
