-- =====================================================================
-- MAXING.py — 002: Row Level Security
-- =====================================================================
-- Regla del proyecto: la proteccion real vive en Postgres, no en el
-- frontend. Esconder un boton en el panel no protege nada; cualquiera
-- puede abrir la consola y llamar a la API con la anon key, que es
-- publica por diseno.
--
-- Modelo:
--   anon           -> lee SOLO lo publicado/activo. Nunca escribe.
--   authenticated  -> escribe SOLO si ademas es admin activo.
--   service_role   -> se salta RLS. Por eso nunca va al navegador.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Helper: is_admin()
-- ---------------------------------------------------------------------
-- SECURITY DEFINER porque necesita leer admin_profiles, tabla que el
-- propio usuario no puede consultar libremente. search_path fijo para que
-- nadie pueda anteponer un schema propio con una tabla admin_profiles
-- falsa y ascender a admin.
create or replace function maxingpy.is_admin()
returns boolean
language sql
stable
security definer
set search_path = maxingpy, pg_temp
as $fn$
  select exists (
    select 1
    from maxingpy.admin_profiles p
    where p.id = auth.uid()
      and p.is_active
  );
$fn$;

revoke all on function maxingpy.is_admin() from public;
grant execute on function maxingpy.is_admin() to anon, authenticated;

-- Igual que la anterior pero exigiendo un rol concreto o superior.
create or replace function maxingpy.has_role(minimo text)
returns boolean
language sql
stable
security definer
set search_path = maxingpy, pg_temp
as $fn$
  select exists (
    select 1
    from maxingpy.admin_profiles p
    where p.id = auth.uid()
      and p.is_active
      and case minimo
            when 'editor'      then p.role in ('editor', 'admin', 'super_admin')
            when 'admin'       then p.role in ('admin', 'super_admin')
            when 'super_admin' then p.role = 'super_admin'
            else false
          end
  );
$fn$;

revoke all on function maxingpy.has_role(text) from public;
grant execute on function maxingpy.has_role(text) to authenticated;

-- ---------------------------------------------------------------------
-- RLS activo en TODAS las tablas
-- ---------------------------------------------------------------------
-- Se usa ENABLE y NO force row level security, a proposito.
--
-- ENABLE ya cubre el modelo de amenaza: PostgREST se conecta y cambia al
-- rol anon o authenticated, y ninguno de los dos es dueno de las tablas,
-- asi que las politicas se les aplican siempre.
--
-- FORCE ademas se lo aplicaria al dueno (postgres), y eso romperia dos
-- cosas: el seed de las migraciones 003 y 004, y sobre todo is_admin().
-- Esa funcion es SECURITY DEFINER y lee admin_profiles; si el dueno
-- tambien quedara sujeto a RLS, leer admin_profiles volveria a evaluar la
-- politica que llama a is_admin(), y se caeria en recursion infinita.
do $blk$
declare
  t text;
begin
  for t in
    select tablename from pg_tables where schemaname = 'maxingpy'
  loop
    execute format('alter table maxingpy.%I enable row level security', t);
  end loop;
end;
$blk$;

-- Se borran las politicas previas para que la migracion sea re-ejecutable
-- sin acumular reglas duplicadas.
do $blk$
declare
  r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies where schemaname = 'maxingpy'
  loop
    execute format('drop policy %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end;
$blk$;

-- ---------------------------------------------------------------------
-- admin_profiles
-- ---------------------------------------------------------------------
-- anon no ve nada: la lista de administradores no es informacion publica.
create policy "perfil propio visible"
  on maxingpy.admin_profiles for select to authenticated
  using (id = auth.uid() or maxingpy.is_admin());

-- Un admin puede editar su nombre, pero no su propio rol ni reactivarse.
-- Eso lo hace un super_admin.
create policy "editar perfil propio"
  on maxingpy.admin_profiles for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select role from maxingpy.admin_profiles where id = auth.uid())
    and is_active = (select is_active from maxingpy.admin_profiles where id = auth.uid())
  );

create policy "super_admin gestiona perfiles"
  on maxingpy.admin_profiles for all to authenticated
  using (maxingpy.has_role('super_admin'))
  with check (maxingpy.has_role('super_admin'));

-- ---------------------------------------------------------------------
-- Contenido publico: lectura anon filtrada, escritura solo admin
-- ---------------------------------------------------------------------

-- categories
create policy "categorias activas son publicas"
  on maxingpy.categories for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe categorias"
  on maxingpy.categories for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- brands
create policy "marcas activas son publicas"
  on maxingpy.brands for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe marcas"
  on maxingpy.brands for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- products
create policy "productos publicados son publicos"
  on maxingpy.products for select to anon, authenticated
  using (is_published or maxingpy.is_admin());
create policy "admin escribe productos"
  on maxingpy.products for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- product_categories: visible solo si el producto lo es. Sin este filtro
-- las relaciones delatarian la existencia de borradores.
create policy "relacion categoria visible con el producto"
  on maxingpy.product_categories for select to anon, authenticated
  using (
    maxingpy.is_admin() or exists (
      select 1 from maxingpy.products p
      where p.id = product_id and p.is_published
    )
  );
create policy "admin escribe relacion categoria"
  on maxingpy.product_categories for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- product_images
create policy "imagenes visibles con el producto"
  on maxingpy.product_images for select to anon, authenticated
  using (
    maxingpy.is_admin() or exists (
      select 1 from maxingpy.products p
      where p.id = product_id and p.is_published
    )
  );
create policy "admin escribe imagenes"
  on maxingpy.product_images for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- product_features
create policy "features visibles con el producto"
  on maxingpy.product_features for select to anon, authenticated
  using (
    maxingpy.is_admin() or exists (
      select 1 from maxingpy.products p
      where p.id = product_id and p.is_published
    )
  );
create policy "admin escribe features"
  on maxingpy.product_features for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- product_specs
create policy "specs visibles con el producto"
  on maxingpy.product_specs for select to anon, authenticated
  using (
    maxingpy.is_admin() or exists (
      select 1 from maxingpy.products p
      where p.id = product_id and p.is_published
    )
  );
create policy "admin escribe specs"
  on maxingpy.product_specs for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- collections
create policy "colecciones activas son publicas"
  on maxingpy.collections for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe colecciones"
  on maxingpy.collections for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- product_collections
create policy "relacion coleccion visible con el producto"
  on maxingpy.product_collections for select to anon, authenticated
  using (
    maxingpy.is_admin() or exists (
      select 1 from maxingpy.products p
      where p.id = product_id and p.is_published
    )
  );
create policy "admin escribe relacion coleccion"
  on maxingpy.product_collections for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- hero_slides
create policy "hero activo es publico"
  on maxingpy.hero_slides for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe hero"
  on maxingpy.hero_slides for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- content_sections
create policy "secciones visibles son publicas"
  on maxingpy.content_sections for select to anon, authenticated
  using (is_visible or maxingpy.is_admin());
create policy "admin escribe secciones"
  on maxingpy.content_sections for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- benefits
create policy "beneficios activos son publicos"
  on maxingpy.benefits for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe beneficios"
  on maxingpy.benefits for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- footer_items
create policy "footer activo es publico"
  on maxingpy.footer_items for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe footer"
  on maxingpy.footer_items for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- social_links
create policy "redes activas son publicas"
  on maxingpy.social_links for select to anon, authenticated
  using (is_active or maxingpy.is_admin());
create policy "admin escribe redes"
  on maxingpy.social_links for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- site_settings
create policy "ajustes son publicos"
  on maxingpy.site_settings for select to anon, authenticated
  using (true);
create policy "admin escribe ajustes"
  on maxingpy.site_settings for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

-- seo_pages
create policy "seo es publico"
  on maxingpy.seo_pages for select to anon, authenticated
  using (true);
create policy "admin escribe seo"
  on maxingpy.seo_pages for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());
