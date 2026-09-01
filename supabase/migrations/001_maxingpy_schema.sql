-- =====================================================================
-- MAXING.py — 001: schema, tablas, indices y triggers
-- =====================================================================
-- Todo el negocio vive en el schema `maxingpy`. Nada se crea en `public`:
-- ese schema es compartido con otros proyectos del mismo Postgres y
-- mezclar tablas ahi haria imposible saber que pertenece a quien.
--
-- Esta migracion es idempotente: se puede correr de nuevo sin romper nada.
-- =====================================================================

create schema if not exists maxingpy;

-- gen_random_uuid() y demas. En Supabase suele estar en `extensions`.
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------

-- Mantiene updated_at sin que la aplicacion tenga que acordarse.
create or replace function maxingpy.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Los slugs los propone el panel en JavaScript (UI.slugificar), asi que
-- aca no hace falta ninguna funcion de normalizacion de texto.

-- =====================================================================
-- 1. admin_profiles
-- =====================================================================
-- No guarda contrasenas: las credenciales viven en auth.users, gestionadas
-- por Supabase Auth. Esta tabla solo dice QUE puede hacer un usuario ya
-- autenticado. Un usuario de auth sin fila aca no es admin.
create table if not exists maxingpy.admin_profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text,
  role        text not null default 'admin'
              check (role in ('super_admin', 'admin', 'editor')),
  is_active   boolean not null default true,
  last_login  timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table maxingpy.admin_profiles is
  'Permisos de los usuarios del panel. Las credenciales estan en auth.users.';

-- =====================================================================
-- 2. categories
-- =====================================================================
create table if not exists maxingpy.categories (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique,
  name              text not null,
  short_description text,
  description       text,
  image_url         text,
  icon_svg          text,          -- path de un <svg> para las que no tienen foto
  color             text,          -- fondo de la ficha
  ink_color         text,          -- texto sobre ese fondo
  sort_order        integer not null default 0,
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists categories_activas_idx
  on maxingpy.categories (is_active, sort_order);

-- =====================================================================
-- 3. brands
-- =====================================================================
create table if not exists maxingpy.brands (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name        text not null,
  logo_url    text,
  website_url text,
  sort_order  integer not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists brands_activas_idx
  on maxingpy.brands (is_active, sort_order);

-- =====================================================================
-- 4. products
-- =====================================================================
-- `price` y `old_price` en guaranies enteros: no hay centavos en PYG y
-- numeric evita los errores de redondeo de float.
--
-- La oferta NO se escribe a mano. Un producto esta en oferta cuando
-- old_price > price; `is_on_sale` y `discount_percent` son columnas
-- generadas para que la condicion no pueda quedar desincronizada.
create table if not exists maxingpy.products (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique,
  sku              text unique,
  name             text not null,
  brand_id         uuid references maxingpy.brands(id) on delete set null,
  short_spec       text,           -- la linea tecnica corta de la ficha
  description      text,           -- parrafos largos, separados por doble salto
  price            numeric(14,2) not null default 0 check (price >= 0),
  old_price        numeric(14,2) check (old_price is null or old_price >= 0),
  currency         text not null default 'PYG',
  stock_status     text not null default 'Disponible'
                   check (stock_status in ('Disponible', 'Bajo pedido', 'Sin stock')),
  main_image_url   text,
  image_alt        text,
  is_published     boolean not null default false,
  is_featured      boolean not null default false,
  sort_order       integer not null default 0,
  views            integer not null default 0,
  meta_title       text,
  meta_description text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  is_on_sale       boolean generated always as
                   (old_price is not null and old_price > price) stored,
  discount_percent integer generated always as (
                     case
                       when old_price is not null and old_price > price and old_price > 0
                       then round((old_price - price) * 100 / old_price)::integer
                       else null
                     end
                   ) stored
);

create index if not exists products_publicados_idx
  on maxingpy.products (is_published, sort_order);
create index if not exists products_marca_idx
  on maxingpy.products (brand_id);
create index if not exists products_oferta_idx
  on maxingpy.products (is_on_sale) where is_on_sale;

-- Busqueda por texto sin depender del cliente.
create index if not exists products_busqueda_idx
  on maxingpy.products
  using gin (to_tsvector('simple',
    coalesce(name, '') || ' ' || coalesce(short_spec, '') || ' ' || coalesce(sku, '')));

-- =====================================================================
-- 5. product_categories  (N a N)
-- =====================================================================
-- Un producto puede estar en varias categorias: una notebook gamer es
-- "Notebooks" y tambien "Gaming".
create table if not exists maxingpy.product_categories (
  product_id  uuid not null references maxingpy.products(id) on delete cascade,
  category_id uuid not null references maxingpy.categories(id) on delete cascade,
  is_primary  boolean not null default false,
  primary key (product_id, category_id)
);

create index if not exists product_categories_cat_idx
  on maxingpy.product_categories (category_id);

-- =====================================================================
-- 6. product_images  (galeria)
-- =====================================================================
create table if not exists maxingpy.product_images (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references maxingpy.products(id) on delete cascade,
  image_url  text not null,
  alt_text   text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists product_images_producto_idx
  on maxingpy.product_images (product_id, sort_order);

-- =====================================================================
-- 7. product_features  (bullets)
-- =====================================================================
create table if not exists maxingpy.product_features (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references maxingpy.products(id) on delete cascade,
  feature    text not null,
  sort_order integer not null default 0
);

create index if not exists product_features_producto_idx
  on maxingpy.product_features (product_id, sort_order);

-- =====================================================================
-- 8. product_specs  (tabla clave/valor)
-- =====================================================================
create table if not exists maxingpy.product_specs (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references maxingpy.products(id) on delete cascade,
  spec_key   text not null,
  spec_value text not null,
  sort_order integer not null default 0
);

create index if not exists product_specs_producto_idx
  on maxingpy.product_specs (product_id, sort_order);

-- =====================================================================
-- 9. collections  (Ofertas, Novedades, Destacados, Mas vendidos)
-- =====================================================================
-- El cliente pidio que estas NO sean categorias. Son colecciones aparte.
--
-- `is_automatic` distingue las que se llenan solas (Ofertas sale de
-- old_price > price) de las curadas a mano desde el panel.
create table if not exists maxingpy.collections (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique,
  name         text not null,
  description  text,
  anchor_id    text,          -- id del ancla en el home, para el menu
  is_automatic boolean not null default false,
  auto_rule    text check (auto_rule in ('on_sale', 'newest', 'featured', 'most_viewed')),
  max_items    integer not null default 8 check (max_items > 0),
  sort_order   integer not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- =====================================================================
-- 10. product_collections  (N a N, curado manual)
-- =====================================================================
create table if not exists maxingpy.product_collections (
  product_id    uuid not null references maxingpy.products(id) on delete cascade,
  collection_id uuid not null references maxingpy.collections(id) on delete cascade,
  sort_order    integer not null default 0,
  primary key (product_id, collection_id)
);

create index if not exists product_collections_col_idx
  on maxingpy.product_collections (collection_id, sort_order);

-- =====================================================================
-- 11. hero_slides
-- =====================================================================
create table if not exists maxingpy.hero_slides (
  id            uuid primary key default gen_random_uuid(),
  title         text,
  subtitle      text,
  eyebrow       text,
  image_url     text,
  image_alt     text,
  cta_label     text,
  cta_target    text,          -- ancla, categoria o url
  cta_secondary_label  text,
  cta_secondary_target text,
  sort_order    integer not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- =====================================================================
-- 12. content_sections
-- =====================================================================
-- Bloques editables del sitio: "Quienes somos", la seccion editorial,
-- el bloque de redes. `section_key` es el identificador estable con el que
-- el frontend los busca; el resto lo edita el panel.
create table if not exists maxingpy.content_sections (
  id           uuid primary key default gen_random_uuid(),
  section_key  text not null unique,
  title        text,
  subtitle     text,
  body         text,
  image_url    text,
  image_alt    text,
  image_side   text default 'right' check (image_side in ('left', 'right', 'none')),
  cta_label    text,
  cta_target   text,
  sort_order   integer not null default 0,
  is_visible   boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- =====================================================================
-- 13. benefits
-- =====================================================================
create table if not exists maxingpy.benefits (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  text       text,
  icon_key   text,          -- check | chat | shield | clock
  icon_color text,
  tint_color text,
  line_color text,
  sort_order integer not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 14. footer_items
-- =====================================================================
-- `group_key` separa las tarjetas operativas (envios, garantia...) de las
-- columnas de enlaces. `is_pending` marca lo que el cliente todavia no
-- entrego, para que el panel lo muestre como pendiente en vez de publicar
-- un dato inventado.
create table if not exists maxingpy.footer_items (
  id          uuid primary key default gen_random_uuid(),
  group_key   text not null,   -- 'operativo' | 'col_productos' | 'col_marcas' | 'col_ayuda'
  group_label text,
  title       text not null,
  text        text,
  link_target text,
  color       text,
  ink_color   text,
  is_pending  boolean not null default false,
  pending_note text,
  sort_order  integer not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists footer_items_grupo_idx
  on maxingpy.footer_items (group_key, sort_order);

-- =====================================================================
-- 15. social_links
-- =====================================================================
create table if not exists maxingpy.social_links (
  id         uuid primary key default gen_random_uuid(),
  platform   text not null unique
             check (platform in ('whatsapp', 'instagram', 'tiktok', 'facebook', 'x', 'youtube', 'linkedin')),
  label      text,
  url        text not null,
  handle     text,
  sort_order integer not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 16. site_settings  (clave/valor)
-- =====================================================================
-- Ajustes sueltos: telefono de WhatsApp, mensaje por defecto, visibilidad
-- y orden de secciones del home. Clave/valor para no migrar el schema
-- cada vez que aparece un ajuste nuevo.
create table if not exists maxingpy.site_settings (
  key         text primary key,
  value       text,
  value_type  text not null default 'text'
              check (value_type in ('text', 'number', 'boolean', 'json', 'url')),
  label       text,
  description text,
  group_key   text not null default 'general',
  sort_order  integer not null default 0,
  updated_at  timestamptz not null default now()
);

-- =====================================================================
-- 17. seo_pages
-- =====================================================================
create table if not exists maxingpy.seo_pages (
  id               uuid primary key default gen_random_uuid(),
  page_key         text not null unique,   -- home | catalog | product | nosotros | favoritos | carrito
  path             text,
  title            text,
  meta_description text,
  og_title         text,
  og_description   text,
  og_image_url     text,
  canonical_url    text,
  robots           text default 'index,follow',
  json_ld          jsonb,
  updated_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Triggers de updated_at
-- ---------------------------------------------------------------------
do $$
declare
  t text;
  tablas text[] := array[
    'admin_profiles', 'categories', 'brands', 'products', 'collections',
    'hero_slides', 'content_sections', 'benefits', 'footer_items',
    'social_links', 'site_settings', 'seo_pages'
  ];
begin
  foreach t in array tablas loop
    execute format(
      'drop trigger if exists %I on maxingpy.%I', 'set_updated_at_' || t, t);
    execute format(
      'create trigger %I before update on maxingpy.%I
         for each row execute function maxingpy.set_updated_at()',
      'set_updated_at_' || t, t);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------
-- Permisos de schema
-- ---------------------------------------------------------------------
-- Se abre el schema a los roles de PostgREST. Esto NO da acceso a los
-- datos por si solo: RLS (migracion 002) decide fila por fila.
grant usage on schema maxingpy to anon, authenticated, service_role;

grant select on all tables in schema maxingpy to anon;
grant select, insert, update, delete on all tables in schema maxingpy to authenticated;
grant all on all tables in schema maxingpy to service_role;

alter default privileges in schema maxingpy
  grant select on tables to anon;
alter default privileges in schema maxingpy
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema maxingpy
  grant all on tables to service_role;
