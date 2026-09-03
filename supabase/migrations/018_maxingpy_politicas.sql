-- MAXING.py — enlace a la nueva página de políticas en el pie
--
-- Se agrega un ítem en la columna "Ayuda" del pie (group_key = 'col_ayuda')
-- que apunta a /politicas-comerciales. Va justo antes de "Política de
-- privacidad" para agrupar las dos páginas legales.
--
-- Solo crea la fila si no está: correrla dos veces no duplica.

begin;

insert into maxingpy.footer_items
  (group_key, group_label, title, text, link_target, is_pending, sort_order, is_active)
select 'col_ayuda', 'Ayuda', 'Envíos, devoluciones y garantía', null,
       '/politicas-comerciales', false, 6, true
where not exists (
  select 1 from maxingpy.footer_items
  where link_target = '/politicas-comerciales'
);

-- Y a "Política de privacidad" se le sube el sort_order para que quede
-- después de la nueva (7 en vez de 6).
update maxingpy.footer_items
   set sort_order = 7
 where link_target = '/politicadeprivacidad'
   and sort_order = 6;

commit;
