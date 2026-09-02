-- =====================================================================
-- MAXING.py — 013: productos relacionados
-- =====================================================================
-- Hasta acá la sección "También te puede interesar" mostraba los primeros
-- cuatro productos del catálogo que no fueran el abierto. No era una
-- recomendación: era relleno.
--
-- Ahora las relaciones se cargan a mano desde el panel. `relation_type`
-- distingue el motivo, y queda lista para que más adelante convivan las
-- elegidas a mano con las que salgan de compras reales: bastaría con
-- agregar un tipo nuevo y un origen, sin tocar lo ya cargado.
-- =====================================================================

create table if not exists maxingpy.product_relations (
  id                 uuid primary key default gen_random_uuid(),
  product_id         uuid not null references maxingpy.products(id) on delete cascade,
  related_product_id uuid not null references maxingpy.products(id) on delete cascade,
  relation_type      text not null default 'related'
                     check (relation_type in ('related', 'complementary', 'frequently_bought_together')),
  sort_order         integer not null default 0,
  is_active          boolean not null default true,
  created_at         timestamptz not null default now(),

  -- Un producto no se relaciona consigo mismo.
  constraint product_relations_no_espejo check (product_id <> related_product_id),
  -- Y no se repite la misma pareja con el mismo motivo.
  constraint product_relations_unicas unique (product_id, related_product_id, relation_type)
);

create index if not exists product_relations_producto_idx
  on maxingpy.product_relations (product_id, sort_order)
  where is_active;

-- Para poder responder "quién apunta a este" al dar de baja un producto.
create index if not exists product_relations_inverso_idx
  on maxingpy.product_relations (related_product_id);

-- ------------------------------------------------- permisos y RLS
grant select on maxingpy.product_relations to anon;
grant select, insert, update, delete on maxingpy.product_relations to authenticated;

alter table maxingpy.product_relations enable row level security;

drop policy if exists "relaciones visibles con los dos productos" on maxingpy.product_relations;
drop policy if exists "admin escribe relaciones"                  on maxingpy.product_relations;

-- La relación solo se ve si los DOS productos están publicados. Sin esto,
-- despublicar un producto dejaría su tarjeta rota en la ficha de otro.
-- El borrado en cascada cubre el caso de eliminarlo; esto cubre el de
-- pasarlo a borrador, que es lo que se hace en el día a día.
create policy "relaciones visibles con los dos productos"
  on maxingpy.product_relations for select to anon, authenticated
  using (
    maxingpy.is_admin() or (
      is_active
      and exists (select 1 from maxingpy.products p where p.id = product_id and p.is_published)
      and exists (select 1 from maxingpy.products p where p.id = related_product_id and p.is_published)
    )
  );

create policy "admin escribe relaciones"
  on maxingpy.product_relations for all to authenticated
  using (maxingpy.is_admin()) with check (maxingpy.is_admin());

comment on table maxingpy.product_relations is
  'Venta cruzada cargada a mano. Preparada para convivir con recomendaciones automáticas.';
