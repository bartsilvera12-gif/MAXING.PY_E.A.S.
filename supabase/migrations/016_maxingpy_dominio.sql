-- MAXING.py — el dominio definitivo es maxingpy.com
--
-- El sitio se sembró apuntando a https://maxing.py, que nunca llegó a
-- existir: el dominio registrado es maxingpy.com. En el código ya está
-- cambiado; acá se corrigen las filas que ya viven en la base y que el
-- código lee en vivo.
--
-- Son tres cosas:
--   · site_url en Ajustes.
--   · La URL canónica de cada tipo de página en seo_pages.
--   · El JSON-LD de Organization y WebSite, donde el dominio es además el
--     identificador (@id) con el que se enlazan entre sí y con cada ficha
--     de producto. Si quedara el viejo, el buscador vería dos empresas
--     distintas: la que dice ser el vendedor de cada producto y la que
--     describe el sitio.
--
-- No se toca el nombre de la marca. "MAXING.py" con punto py es como se
-- llama la tienda y aparece en site_name, legal_name y en el saludo de
-- WhatsApp; ahí no es una dirección web.
--
-- Se reemplaza por texto en vez de escribir los valores nuevos a mano para
-- no pisar lo que el cliente haya editado desde el panel: solo cambia el
-- pedazo del dominio, el resto queda como está.

begin;

-- Ajustes: la URL del sitio.
update maxingpy.site_settings
   set value = replace(value, 'https://maxing.py', 'https://maxingpy.com')
 where value_type = 'url'
   and value like '%https://maxing.py%';

-- SEO por tipo de página: canónica, imagen de compartir y JSON-LD.
update maxingpy.seo_pages
   set canonical_url = replace(canonical_url, 'https://maxing.py', 'https://maxingpy.com')
 where canonical_url like '%https://maxing.py%';

update maxingpy.seo_pages
   set json_ld = replace(json_ld::text, 'https://maxing.py', 'https://maxingpy.com')::jsonb
 where json_ld::text like '%https://maxing.py%';

-- Por si alguna ficha o categoría tiene una canónica cargada a mano.
update maxingpy.products
   set canonical_url = replace(canonical_url, 'https://maxing.py', 'https://maxingpy.com')
 where canonical_url like '%https://maxing.py%';

update maxingpy.categories
   set canonical_url = replace(canonical_url, 'https://maxing.py', 'https://maxingpy.com')
 where canonical_url like '%https://maxing.py%';

update maxingpy.products
   set og_image_url = replace(og_image_url, 'https://maxing.py', 'https://maxingpy.com')
 where og_image_url like '%https://maxing.py%';

-- Enlaces del pie que hayan quedado absolutos.
update maxingpy.footer_items
   set link_target = replace(link_target, 'https://maxing.py', 'https://maxingpy.com')
 where link_target like '%https://maxing.py%';

commit;
