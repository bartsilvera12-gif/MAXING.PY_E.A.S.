-- =====================================================================
-- MAXING.py — 011: campos SEO por producto y por categoría
-- =====================================================================
-- Hasta acá el SEO por página vivía solo en `seo_pages`, que alcanza para
-- el inicio y el catálogo pero no para las fichas: cada producto y cada
-- categoría necesita su propio título, su descripción y su canónica.
--
-- Nota sobre nombres: `products` ya tenía meta_title y meta_description
-- desde la migración 001, y cumplen el papel de seo_title / seo_description.
-- No se renombran —romperían el código que ya los lee— y se agregan al lado
-- los que faltaban.
-- =====================================================================

-- ------------------------------------------------- productos
alter table maxingpy.products
  add column if not exists canonical_url text,
  add column if not exists og_title      text,
  add column if not exists og_description text,
  add column if not exists og_image_url  text;

comment on column maxingpy.products.meta_title is
  'Título SEO. Si está vacío, el sitio arma uno con la marca y el nombre.';
comment on column maxingpy.products.canonical_url is
  'URL canónica. Si está vacía, el sitio usa /productos/<slug>.';
comment on column maxingpy.products.og_image_url is
  'Imagen al compartir. Si está vacía, se usa la foto principal.';

-- ------------------------------------------------- categorías
alter table maxingpy.categories
  add column if not exists seo_title       text,
  add column if not exists seo_description text,
  add column if not exists canonical_url   text;

comment on column maxingpy.categories.seo_title is
  'Título SEO de /categorias/<slug>. Vacío = "<nombre> — MAXING.py".';
comment on column maxingpy.categories.canonical_url is
  'URL canónica. Vacía = /categorias/<slug>.';

-- ------------------------------------------------- índices para las URLs
-- Las dos rutas nuevas buscan por slug en cada carga de página, así que
-- conviene que esa búsqueda no recorra la tabla entera. `products.slug` y
-- `categories.slug` ya son unique, que crea su índice; esto solo lo deja
-- explícito para las consultas que además filtran por publicado.
create index if not exists products_slug_publicado_idx
  on maxingpy.products (slug) where is_published;
create index if not exists categories_slug_activa_idx
  on maxingpy.categories (slug) where is_active;
