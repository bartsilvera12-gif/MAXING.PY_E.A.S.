-- =====================================================================
-- MAXING.py — 012: preguntas frecuentes
-- =====================================================================
-- Estructura solamente. NO se cargan respuestas: las tiene que escribir el
-- cliente desde el panel. Se siembran los ocho temas previstos como
-- categorías vacías, para que al entrar tenga dónde ir poniendo.
--
-- Una FAQ puede además apuntarse a categorías del catálogo o a productos
-- concretos: una pregunta sobre batería tiene sentido en Notebooks, y una
-- sobre la garantía de un fabricante en los productos de esa marca. Sin
-- ninguna relación, la pregunta es general y sale en la sección de FAQ.
-- =====================================================================

-- ------------------------------------------------- temas
create table if not exists maxingpy.faq_categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name        text not null,
  description text,
  sort_order  integer not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ------------------------------------------------- preguntas
create table if not exists maxingpy.faqs (
  id              uuid primary key default gen_random_uuid(),
  faq_category_id uuid references maxingpy.faq_categories(id) on delete set null,
  question        text not null,
  answer          text,
  sort_order      integer not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Una pregunta sin respuesta no se publica: el sitio la filtra. Así el
-- cliente puede ir dejando preguntas anotadas sin que aparezcan a medias.
create index if not exists faqs_publicables_idx
  on maxingpy.faqs (is_active, sort_order)
  where is_active and answer is not null and answer <> '';

create index if not exists faqs_tema_idx
  on maxingpy.faqs (faq_category_id, sort_order);

-- ------------------------------------------------- dónde se muestra cada una
-- Sin filas en estas dos tablas, la pregunta es general.
create table if not exists maxingpy.faq_product_categories (
  faq_id      uuid not null references maxingpy.faqs(id) on delete cascade,
  category_id uuid not null references maxingpy.categories(id) on delete cascade,
  primary key (faq_id, category_id)
);

create table if not exists maxingpy.faq_products (
  faq_id     uuid not null references maxingpy.faqs(id) on delete cascade,
  product_id uuid not null references maxingpy.products(id) on delete cascade,
  primary key (faq_id, product_id)
);

create index if not exists faq_product_categories_cat_idx
  on maxingpy.faq_product_categories (category_id);
create index if not exists faq_products_prod_idx
  on maxingpy.faq_products (product_id);

-- ------------------------------------------------- triggers y permisos
do $blk$
declare t text;
begin
  foreach t in array array['faq_categories', 'faqs'] loop
    execute format('drop trigger if exists %I on maxingpy.%I', 'set_updated_at_' || t, t);
    execute format(
      'create trigger %I before update on maxingpy.%I
         for each row execute function maxingpy.set_updated_at()',
      'set_updated_at_' || t, t);
  end loop;
end;
$blk$;

grant select on maxingpy.faq_categories, maxingpy.faqs,
                maxingpy.faq_product_categories, maxingpy.faq_products to anon;
grant select, insert, update, delete on maxingpy.faq_categories, maxingpy.faqs,
                maxingpy.faq_product_categories, maxingpy.faq_products to authenticated;

-- ------------------------------------------------- RLS
alter table maxingpy.faq_categories enable row level security;
alter table maxingpy.faqs enable row level security;
alter table maxingpy.faq_product_categories enable row level security;
alter table maxingpy.faq_products enable row level security;

drop policy if exists "temas de faq activos son publicos" on maxingpy.faq_categories;
drop policy if exists "admin escribe temas de faq"        on maxingpy.faq_categories;
drop policy if exists "faqs respondidas son publicas"     on maxingpy.faqs;
drop policy if exists "admin escribe faqs"                on maxingpy.faqs;
drop policy if exists "relacion faq categoria publica"    on maxingpy.faq_product_categories;
drop policy if exists "admin escribe relacion faq categoria" on maxingpy.faq_product_categories;
drop policy if exists "relacion faq producto publica"     on maxingpy.faq_products;
drop policy if exists "admin escribe relacion faq producto" on maxingpy.faq_products;

create policy "temas de faq activos son publicos"
  on maxingpy.faq_categories for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe temas de faq"
  on maxingpy.faq_categories for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- Solo salen las respondidas: una pregunta sin respuesta no se publica.
create policy "faqs respondidas son publicas"
  on maxingpy.faqs for select to anon, authenticated
  using ((is_active and answer is not null and answer <> '') or maxingpy.is_admin());
create policy "admin escribe faqs"
  on maxingpy.faqs for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

create policy "relacion faq categoria publica"
  on maxingpy.faq_product_categories for select to anon, authenticated using (true);
create policy "admin escribe relacion faq categoria"
  on maxingpy.faq_product_categories for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

create policy "relacion faq producto publica"
  on maxingpy.faq_products for select to anon, authenticated using (true);
create policy "admin escribe relacion faq producto"
  on maxingpy.faq_products for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- ------------------------------------------------- temas previstos
-- Solo los temas, sin preguntas ni respuestas: esas las escribe el cliente,
-- que es el unico que sabe como trabaja.
insert into maxingpy.faq_categories (slug, name, sort_order, is_active) values
  ('medios-de-pago',      'Medios de pago',       1, true),
  ('envios',              'Envíos',               2, true),
  ('garantias',           'Garantías',            3, true),
  ('cambios',             'Cambios',              4, true),
  ('facturacion',         'Facturación',          5, true),
  ('disponibilidad',      'Disponibilidad',       6, true),
  ('retiro-de-productos', 'Retiro de productos',  7, true),
  ('proceso-de-compra',   'Proceso de compra',    8, true)
on conflict (slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;
