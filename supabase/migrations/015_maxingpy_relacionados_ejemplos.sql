-- MAXING.py — primeras relaciones entre productos
--
-- La migración 013 creó la tabla pero quedó vacía, así que la sección
-- "También te puede interesar" no aparecía en ninguna ficha.
--
-- Estas relaciones son un punto de partida, no una recomendación cerrada:
-- son las obvias, las que no dependen de conocer al cliente ni sus márgenes.
--   · Complementario → algo que se lleva junto (un teléfono y sus auriculares,
--     una notebook y su mouse, una consola y un televisor).
--   · Relacionado    → una alternativa del mismo rubro (los tres iPhone entre
--     sí, las dos PS5, los dos monitores).
-- Cuál conviene empujar en cada ficha lo decide quien vende. Se edita desde
-- el panel, en Productos → abrir el producto → "Productos relacionados".
--
-- La relación es de ida: poner B en la ficha de A no pone A en la de B. Por
-- eso las alternativas van cargadas en los dos sentidos.
--
-- La ficha muestra como máximo cuatro, en el orden de esta lista. Ninguno de
-- estos productos supera ese tope.
--
-- Solo siembra si la tabla está vacía: correrla dos veces no duplica nada ni
-- pisa lo que el cliente haya armado a mano.

begin;

insert into maxingpy.product_relations
  (product_id, related_product_id, relation_type, sort_order, is_active)
select a.id, b.id, v.tipo, v.orden, true
from (values
  -- Celulares: los accesorios del ecosistema y los otros dos modelos.
  ('apple-iphone-17-pro',     'apple-airpods-pro-3',        'complementary', 1),
  ('apple-iphone-17-pro',     'apple-watch-s11-42mm',       'complementary', 2),
  ('apple-iphone-17-pro',     'apple-iphone-17-pro-max',    'related',       3),
  ('apple-iphone-17-pro',     'apple-iphone-17',            'related',       4),

  ('apple-iphone-17-pro-max', 'apple-airpods-pro-3',        'complementary', 1),
  ('apple-iphone-17-pro-max', 'apple-watch-s11-42mm',       'complementary', 2),
  ('apple-iphone-17-pro-max', 'apple-iphone-17-pro',        'related',       3),
  ('apple-iphone-17-pro-max', 'apple-iphone-17',            'related',       4),

  ('apple-iphone-17',         'apple-airpods-pro-3',        'complementary', 1),
  ('apple-iphone-17',         'apple-watch-s11-42mm',       'complementary', 2),
  ('apple-iphone-17',         'apple-iphone-17-pro',        'related',       3),
  ('apple-iphone-17',         'apple-iphone-17-pro-max',    'related',       4),

  -- Notebooks: con qué se completa un puesto de trabajo o de juego.
  ('msi-katana-15',           'redragon-m916w-pro-4k',      'complementary', 1),
  ('msi-katana-15',           'ajazz-af98-negro',           'complementary', 2),
  ('msi-katana-15',           'msi-mag-242c',               'complementary', 3),
  ('msi-katana-15',           'hp-15-fd2050wm',             'related',       4),

  ('hp-15-fd2050wm',          'redragon-m916w-pro-4k',      'complementary', 1),
  ('hp-15-fd2050wm',          'ftx-gk03s-dorado',           'complementary', 2),
  ('hp-15-fd2050wm',          'msi-katana-15',              'related',       3),
  ('hp-15-fd2050wm',          'apple-macbook-neo-13',       'related',       4),

  ('apple-macbook-neo-13',    'apple-airpods-pro-3',        'complementary', 1),
  ('apple-macbook-neo-13',    'hp-15-fd2050wm',             'related',       2),
  ('apple-macbook-neo-13',    'msi-katana-15',              'related',       3),

  -- Consolas: la consola pide pantalla, y la otra versión como alternativa.
  ('sony-ps5-pro-2tb',        'samsung-tv-55-un55u8000',    'complementary', 1),
  ('sony-ps5-pro-2tb',        'sony-ps5-slim-825gb',        'related',       2),

  ('sony-ps5-slim-825gb',     'xiaomi-tv-a-2026-65',        'complementary', 1),
  ('sony-ps5-slim-825gb',     'sony-ps5-pro-2tb',           'related',       2),

  -- Periféricos: el mismo teclado en el otro color.
  ('ajazz-af98-negro',        'ajazz-af98-azul',            'related',       1),
  ('ajazz-af98-negro',        'redragon-m916w-pro-4k',      'complementary', 2),

  ('ajazz-af98-azul',         'ajazz-af98-negro',           'related',       1),
  ('ajazz-af98-azul',         'redragon-m916w-pro-4k',      'complementary', 2),

  -- Monitores.
  ('mtek-m27sfv280c',         'msi-mag-242c',               'related',       1),
  ('msi-mag-242c',            'mtek-m27sfv280c',            'related',       1),

  -- Tablets.
  ('apple-ipad-11-128gb',     'xiaomi-redmi-pad-2',         'related',       1),
  ('apple-ipad-11-128gb',     'samsung-galaxy-tab-s10-fe',  'related',       2),

  ('xiaomi-redmi-pad-2',      'apple-ipad-11-128gb',        'related',       1),
  ('xiaomi-redmi-pad-2',      'samsung-galaxy-tab-s10-fe',  'related',       2),

  ('samsung-galaxy-tab-s10-fe', 'apple-ipad-11-128gb',      'related',       1),
  ('samsung-galaxy-tab-s10-fe', 'xiaomi-redmi-pad-2',       'related',       2)
) as v(origen, destino, tipo, orden)
join maxingpy.products a on a.slug = v.origen
join maxingpy.products b on b.slug = v.destino
where not exists (select 1 from maxingpy.product_relations);

commit;
