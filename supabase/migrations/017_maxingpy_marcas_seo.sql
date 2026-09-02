-- MAXING.py — las marcas pasan a tener página propia
--
-- Hasta ahora una marca era solo un filtro del catálogo: existía en la base y
-- en el panel, pero no tenía dirección propia ni forma de contarle a un
-- buscador qué es. Quien busca "notebooks MSI Paraguay" no encontraba nada.
--
-- Con esto cada marca activa tiene /marcas/<slug>, con su título, su
-- descripción y su tarjeta al compartir, igual que ya tienen los productos y
-- las categorías.
--
-- Las columnas se agregan con IF NOT EXISTS y todas admiten nulo: no se pisa
-- ni se pierde nada de lo que ya está cargado. Una marca sin estos datos
-- sigue funcionando igual — el sitio le arma el título y la descripción solo.

begin;

alter table maxingpy.brands
  -- Un párrafo sobre la marca, para la cabecera de su página. Es también el
  -- texto que se ofrece al buscador cuando no hay descripción SEO propia.
  add column if not exists description     text,
  add column if not exists seo_title       text,
  add column if not exists seo_description text,
  add column if not exists canonical_url   text,
  -- La imagen de la tarjeta al compartir. Si está vacía se usa el logo, que
  -- suele ser un PNG chico con fondo transparente: sirve, pero una foto
  -- propia se ve mejor en WhatsApp.
  add column if not exists og_image_url    text;

commit;
