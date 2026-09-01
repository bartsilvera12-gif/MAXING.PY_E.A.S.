-- =====================================================================
-- MAXING.py — 006: alta del primer administrador
-- =====================================================================
-- IMPORTANTE, leer antes de ejecutar.
--
-- Esta migracion NO crea el usuario ni define ninguna contraseña. El
-- usuario se crea antes, a mano, desde el panel de Supabase:
--
--   Authentication -> Users -> Add user
--     Email:    admin@maxing.com
--     Password: (la elegis vos en ese formulario, no va en ningun archivo)
--     Marcar "Auto Confirm User"
--
-- Recien despues se corre este SQL, que busca ese usuario por email en
-- auth.users y le da el perfil de super_admin. Asi:
--
--   * la contraseña queda hasheada por Supabase Auth y nunca pasa por el
--     repositorio ni por el historial de git;
--   * no se inventa ningun UUID: se usa el que Auth ya asigno.
--
-- Si el email todavia no existe, la migracion avisa y no hace nada, en
-- vez de fallar a la mitad.
-- =====================================================================

do $blk$
declare
  correo   constant text := 'admin@maxing.com';
  id_auth  uuid;
begin
  select id into id_auth from auth.users where email = correo;

  if id_auth is null then
    raise warning
      'No existe el usuario % en auth.users. Crealo primero desde Authentication -> Users -> Add user y volve a correr esta migracion.',
      correo;
    return;
  end if;

  insert into maxingpy.admin_profiles (id, email, full_name, role, is_active)
  values (id_auth, correo, 'Administrador MAXING.py', 'super_admin', true)
  on conflict (id) do update set
    email     = excluded.email,
    role      = 'super_admin',
    is_active = true;

  raise notice 'Perfil de super_admin listo para % (%).', correo, id_auth;
end;
$blk$;
