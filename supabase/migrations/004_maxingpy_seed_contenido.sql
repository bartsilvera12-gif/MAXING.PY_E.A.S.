-- =====================================================================
-- MAXING.py — 004: seed del contenido editable del sitio
-- =====================================================================
-- Colecciones, hero, secciones, beneficios, pie, redes, ajustes y SEO.
-- Los textos son exactamente los que hoy estan escritos a mano en
-- index.html, para que la migracion no cambie ni una coma de lo que ve
-- el visitante.
--
-- Lo que el cliente todavia no entrego (cobertura de envios, direccion,
-- plazo de garantia, horarios) queda marcado con is_pending = true y el
-- texto generico actual. No se inventa un dato para llenar el hueco.
--
-- Idempotente.
-- =====================================================================

-- ------------------------------------------------- colecciones
-- El cliente pidio que Ofertas, Novedades y Destacados NO sean categorias.
-- Van aca, como colecciones. Ofertas se llena sola desde old_price > price;
-- Novedades por fecha de alta; Destacados se cura a mano desde el panel.
insert into maxingpy.collections
  (slug, name, description, anchor_id, is_automatic, auto_rule, max_items, sort_order, is_active)
values
  ('ofertas',   'Ofertas',   'Selección con descuento vigente.',  'ofertas', true,  'on_sale',  4, 1, true),
  ('novedades', 'Novedades', 'Lo último que sumamos al catálogo.', 'new-h',  true,  'newest',   4, 2, true),
  ('destacados','Destacados','Selección recomendada por el equipo.','feat-h', false, 'featured', 8, 3, true),
  ('mas-vendidos','Más vendidos','Los que más consultan.',        null,      true,  'most_viewed', 8, 4, false)
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  anchor_id = excluded.anchor_id,
  is_automatic = excluded.is_automatic,
  auto_rule = excluded.auto_rule,
  max_items = excluded.max_items,
  sort_order = excluded.sort_order;

-- Destacados arranca con los 8 primeros del catalogo, que es lo que el
-- sitio muestra hoy con slice(0, 8). A partir de aca lo decide el panel.
insert into maxingpy.product_collections (product_id, collection_id, sort_order)
select p.id, c.id, p.sort_order
from maxingpy.products p
cross join maxingpy.collections c
where c.slug = 'destacados' and p.is_published and p.sort_order <= 8
on conflict (product_id, collection_id) do nothing;

-- ------------------------------------------------- hero
insert into maxingpy.hero_slides
  (title, subtitle, eyebrow, image_url, image_alt,
   cta_label, cta_target, cta_secondary_label, cta_secondary_target, sort_order, is_active)
select
  'Tecnología que mejora tu día.',
  'Encontrá tecnología, informática y accesorios para trabajar, crear, jugar y disfrutar más.',
  'Tecnología · Informática · Gaming',
  'hero.jpg',
  'Setup de escritorio con notebook, monitor y periféricos',
  'Explorar productos', 'catalog',
  'Consultar por WhatsApp', 'whatsapp',
  1, true
where not exists (select 1 from maxingpy.hero_slides);

-- ------------------------------------------------- secciones de contenido
insert into maxingpy.content_sections
  (section_key, title, subtitle, body, image_url, image_alt, image_side, cta_label, cta_target, sort_order, is_visible)
values
  ('setup',
   'Todo lo que necesitás para tu setup.',
   'Setup completo',
   'Monitores, periféricos, audio y almacenamiento seleccionados para trabajar y jugar mejor.',
   'setup.jpg',
   'Setup de escritorio con monitor, notebook, teclado y auriculares',
   'right',
   'Armar mi setup', 'catalog',
   1, true),

  ('nosotros',
   '¿Quiénes somos?',
   'La empresa',
   'MAXING.PY E.A.S. es una empresa paraguaya fundada en 2025, especializada en soluciones tecnológicas para personas, profesionales y empresas.' || chr(10) || chr(10) ||
   'Comercializamos equipos de informática, dispositivos móviles y soluciones personalizadas, acompañando a cada cliente con asesoramiento profesional, garantía y un servicio cercano.' || chr(10) || chr(10) ||
   'Más que vender tecnología, buscamos construir relaciones de confianza mediante un acompañamiento antes, durante y después de cada compra.',
   'nosotros.jpg',
   'Equipo de MAXING.py en la oficina',
   'left',
   null, null,
   2, true),

  ('seo_editorial',
   'Tecnología para trabajar, crear y disfrutar',
   null,
   'En MAXING.py acercamos productos de informática y tecnología para profesionales, empresas, gamers y usuarios que buscan rendimiento, calidad y una buena experiencia de compra.' || chr(10) || chr(10) ||
   'Trabajamos con computadoras, notebooks, componentes de PC, monitores, celulares, audio, periféricos y accesorios tecnológicos, con asesoramiento directo para elegir el equipo correcto según el uso y el presupuesto.' || chr(10) || chr(10) ||
   'Si buscás una tienda de tecnología e informática en Paraguay, escribinos por WhatsApp y te ayudamos a encontrar lo que necesitás.',
   'seccion.jpg',
   'Setup de escritorio con PC, monitor, teclado y auriculares',
   'right',
   null, null,
   3, true),

  ('redes',
   'Seguinos y descubrí lo nuevo',
   null,
   'Novedades, lanzamientos y recomendaciones en nuestras redes.',
   null, null, 'none',
   null, null,
   4, true)
on conflict (section_key) do update set
  title = excluded.title,
  subtitle = excluded.subtitle,
  body = excluded.body,
  image_url = excluded.image_url,
  image_alt = excluded.image_alt,
  image_side = excluded.image_side,
  cta_label = excluded.cta_label,
  cta_target = excluded.cta_target,
  sort_order = excluded.sort_order;

-- ------------------------------------------------- beneficios
-- icon_key referencia los iconos ya dibujados en el frontend (this.icon).
-- Se guarda la clave, no el SVG, para no meter markup en la base.
delete from maxingpy.benefits;
insert into maxingpy.benefits
  (title, text, icon_key, icon_color, tint_color, line_color, sort_order, is_active)
values
  ('Productos seleccionados',
   'Elegimos equipos y accesorios por rendimiento real, no por catálogo.',
   'check', '#1F8F19', '#E9FBE7', '#BCEDB7', 1, true),
  ('Asesoramiento personalizado',
   'Te ayudamos a definir el equipo según tu uso y tu presupuesto.',
   'chat', '#1E6FE8', '#E8F1FE', '#C1D8FB', 2, true),
  ('Compra simple y segura',
   'Proceso claro, sin pasos innecesarios ni sorpresas.',
   'shield', '#6D3BD1', '#F0EAFD', '#D7C7F7', 3, true),
  ('Atención directa por WhatsApp',
   'Consultas respondidas por personas, no por un formulario.',
   'clock', '#C97A06', '#FDF2E0', '#F2DCB3', 4, true);

-- ------------------------------------------------- pie
-- Las columnas "Productos" y "Marcas" del pie NO se cargan aca: se derivan
-- de las categorias y marcas activas, asi se mantienen solas cuando el
-- admin agrega o quita una. Aca van las tarjetas operativas y la columna
-- de ayuda, que si son texto fijo.
delete from maxingpy.footer_items;
insert into maxingpy.footer_items
  (group_key, group_label, title, text, link_target, color, ink_color,
   is_pending, pending_note, sort_order, is_active)
values
  ('operativo', 'Cómo trabajamos', 'Envíos',
   'Coordinamos el envío al confirmar la compra.', null, '#86DC2C', '#4E7F13',
   true, 'Falta: cobertura y transportadoras', 1, true),
  ('operativo', 'Cómo trabajamos', 'Retiro en local',
   'Retiro coordinado por WhatsApp.', null, '#40DF36', '#24801C',
   true, 'Falta: dirección y cómo llegar', 2, true),
  ('operativo', 'Cómo trabajamos', 'Garantía',
   'Garantía según política del fabricante.', null, '#22C86F', '#12784A',
   true, 'Falta: plazo y cómo se tramita', 3, true),
  ('operativo', 'Cómo trabajamos', 'Atención',
   'Respondemos por WhatsApp todos los días.', null, '#16AE95', '#0C6E60',
   true, 'Falta: horarios de atención', 4, true),

  ('col_ayuda', 'Ayuda', 'Ver todo el catálogo', null, 'catalog', null, null, false, null, 1, true),
  ('col_ayuda', 'Ayuda', 'Ofertas',              null, '#ofertas', null, null, false, null, 2, true),
  ('col_ayuda', 'Ayuda', 'Quiénes somos',        null, 'nosotros', null, null, false, null, 3, true),
  ('col_ayuda', 'Ayuda', 'Cómo comprar',         null, '#ben-h',   null, null, false, null, 4, true),
  ('col_ayuda', 'Ayuda', 'Contacto',             null, '#contacto',null, null, false, null, 5, true),
  ('col_ayuda', 'Ayuda', 'Política de privacidad', null, '/politicadeprivacidad', null, null, false, null, 6, true);

-- ------------------------------------------------- redes
insert into maxingpy.social_links (platform, label, url, handle, sort_order, is_active)
values
  ('whatsapp',  'WhatsApp',  'https://wa.me/595984127274', '+595 984 127274', 1, true),
  ('instagram', 'Instagram', 'https://instagram.com/maxing.py', '@maxing.py',  2, true),
  ('tiktok',    'TikTok',    'https://tiktok.com/@maxing.py',  '@maxing.py',   3, true)
on conflict (platform) do update set
  label = excluded.label,
  url = excluded.url,
  handle = excluded.handle,
  sort_order = excluded.sort_order;

-- ------------------------------------------------- ajustes
insert into maxingpy.site_settings (key, value, value_type, label, description, group_key, sort_order)
values
  ('site_name',        'MAXING.py', 'text', 'Nombre del sitio', null, 'general', 1),
  ('site_slogan',      'Tecnología que mejora tu día.', 'text', 'Eslogan', 'Aparece en el hero y en el pie.', 'general', 2),
  ('site_url',         'https://maxing.py/', 'url', 'URL del sitio', null, 'general', 3),
  ('legal_name',       'MAXING.PY E.A.S.', 'text', 'Razón social', null, 'general', 4),

  ('whatsapp_phone',   '595984127274', 'text', 'WhatsApp', 'Solo números, con código de país y sin +.', 'contacto', 1),
  ('whatsapp_message', 'Hola MAXING.py, quiero consultar por: ', 'text', 'Mensaje inicial de WhatsApp',
                       'Texto con el que arranca la conversación. El producto se agrega al final.', 'contacto', 2),
  ('contact_email',    '', 'text', 'Email de contacto', 'Vacío mientras el cliente no lo defina.', 'contacto', 3),
  ('contact_address',  '', 'text', 'Dirección', 'Vacío mientras el cliente no lo defina.', 'contacto', 4),
  ('contact_hours',    '', 'text', 'Horarios de atención', 'Vacío mientras el cliente no lo defina.', 'contacto', 5),

  ('price_step',       '5000', 'number', 'Escalón del filtro de precio', 'En guaraníes.', 'catalogo', 1),
  ('currency_prefix',  'Gs. ', 'text', 'Prefijo de precio', null, 'catalogo', 2),

  ('show_hero',        'true', 'boolean', 'Mostrar hero', null, 'secciones', 1),
  ('show_categories',  'true', 'boolean', 'Mostrar categorías', null, 'secciones', 2),
  ('show_featured',    'true', 'boolean', 'Mostrar destacados', null, 'secciones', 3),
  ('show_offers',      'true', 'boolean', 'Mostrar ofertas', null, 'secciones', 4),
  ('show_novedades',   'true', 'boolean', 'Mostrar novedades', null, 'secciones', 5),
  ('show_brands',      'true', 'boolean', 'Mostrar marcas', null, 'secciones', 6),
  ('show_benefits',    'true', 'boolean', 'Mostrar beneficios', null, 'secciones', 7),
  ('show_nosotros',    'true', 'boolean', 'Mostrar "Quiénes somos" en el inicio', null, 'secciones', 8),
  ('show_setup',       'true', 'boolean', 'Mostrar sección "Setup completo"', null, 'secciones', 9),
  ('show_seo_block',   'true', 'boolean', 'Mostrar bloque editorial', null, 'secciones', 10)
on conflict (key) do update set
  label = excluded.label,
  description = excluded.description,
  value_type = excluded.value_type,
  group_key = excluded.group_key,
  sort_order = excluded.sort_order;

-- ------------------------------------------------- SEO por pagina
insert into maxingpy.seo_pages
  (page_key, path, title, meta_description, og_title, og_description, og_image_url, canonical_url, robots, json_ld)
values
  ('home', '/',
   'MAXING.py — Tecnología, informática y accesorios en Paraguay',
   'Tienda de tecnología en Paraguay: notebooks, celulares, monitores, gaming, periféricos y accesorios. Asesoramiento directo por WhatsApp.',
   'MAXING.py — Tecnología que mejora tu día.',
   'Notebooks, celulares, monitores, gaming, periféricos y accesorios con asesoramiento directo.',
   'hero.jpg', 'https://maxing.py/', 'index,follow',
   jsonb_build_object(
     '@context', 'https://schema.org',
     '@type', 'Organization',
     '@id', 'https://maxing.py/#org',
     'name', 'MAXING.py',
     'url', 'https://maxing.py/',
     'slogan', 'Tecnología que mejora tu día.',
     'areaServed', 'PY',
     'contactPoint', jsonb_build_object(
       '@type', 'ContactPoint',
       'telephone', '+595984127274',
       'contactType', 'customer service',
       'availableLanguage', 'es'),
     'sameAs', jsonb_build_array('https://instagram.com/maxing.py', 'https://tiktok.com/@maxing.py'))),

  ('catalog', '/productos',
   'Productos — MAXING.py',
   'Catálogo completo de tecnología e informática en Paraguay. Filtrá por categoría, marca, disponibilidad y precio.',
   'Productos — MAXING.py', 'Catálogo completo de tecnología e informática en Paraguay.',
   null, 'https://maxing.py/', 'index,follow', null),

  ('product', '/producto',
   null,
   null,
   null, null, null, null, 'index,follow', null),

  ('nosotros', '/nosotros',
   'Quiénes somos — MAXING.py',
   'MAXING.PY E.A.S., empresa paraguaya fundada en 2025, especializada en soluciones tecnológicas para personas, profesionales y empresas.',
   'Quiénes somos — MAXING.py',
   'Empresa paraguaya de soluciones tecnológicas, fundada en 2025.',
   'nosotros.jpg', 'https://maxing.py/', 'index,follow', null),

  ('favoritos', '/favoritos',
   'Favoritos — MAXING.py', 'Tus productos guardados.',
   null, null, null, null, 'noindex,follow', null),

  ('carrito', '/lista-de-consulta',
   'Lista de consulta — MAXING.py', 'Los productos que querés consultar por WhatsApp.',
   null, null, null, null, 'noindex,follow', null)
on conflict (page_key) do update set
  path = excluded.path,
  title = excluded.title,
  meta_description = excluded.meta_description,
  og_title = excluded.og_title,
  og_description = excluded.og_description,
  og_image_url = excluded.og_image_url,
  canonical_url = excluded.canonical_url,
  robots = excluded.robots,
  json_ld = excluded.json_ld;
