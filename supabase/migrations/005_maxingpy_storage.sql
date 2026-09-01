-- =====================================================================
-- MAXING.py — 005: bucket de Storage
-- =====================================================================
-- Bucket publico `maxingpy` para las imagenes del sitio. Publico porque
-- las fotos de producto se sirven a visitantes anonimos: no hay nada
-- sensible ahi y un bucket privado obligaria a firmar cada URL.
--
-- La escritura, en cambio, esta cerrada: solo un admin activo puede
-- subir, reemplazar o borrar. Igual que con las tablas, la regla vive en
-- Postgres y no en el panel.
--
-- Carpetas previstas:
--   products/    fotos de producto
--   categories/  fotos de categoria
--   brands/      logos
--   hero/        imagenes del hero
--   sections/    imagenes de las secciones editables
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'maxingpy', 'maxingpy', true,
  5242880,   -- 5 MB: de sobra para una foto de 900x900 optimizada
  array['image/jpeg', 'image/png', 'image/webp', 'image/avif', 'image/svg+xml']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Politicas re-ejecutables.
drop policy if exists "maxingpy lectura publica"   on storage.objects;
drop policy if exists "maxingpy alta admin"        on storage.objects;
drop policy if exists "maxingpy cambio admin"      on storage.objects;
drop policy if exists "maxingpy borrado admin"     on storage.objects;

create policy "maxingpy lectura publica"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'maxingpy');

create policy "maxingpy alta admin"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'maxingpy' and maxingpy.is_admin());

create policy "maxingpy cambio admin"
  on storage.objects for update to authenticated
  using (bucket_id = 'maxingpy' and maxingpy.is_admin())
  with check (bucket_id = 'maxingpy' and maxingpy.is_admin());

create policy "maxingpy borrado admin"
  on storage.objects for delete to authenticated
  using (bucket_id = 'maxingpy' and maxingpy.is_admin());
