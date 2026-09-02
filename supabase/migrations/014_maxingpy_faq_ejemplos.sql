-- MAXING.py — preguntas frecuentes de arranque
--
-- La migración 012 dejó los ocho temas creados pero ninguna pregunta, así que
-- la sección no aparecía en el sitio. Estas siete son para que el cliente vea
-- cómo se muestra y tenga desde dónde empezar a editar.
--
-- NINGUNA respuesta inventa un dato del negocio. Cada una dice exactamente lo
-- mismo que ya dice el sitio en otro lado (las tarjetas del pie, el modelo de
-- venta por WhatsApp, el estado de stock del catálogo). Donde hace falta un
-- dato que todavía no tenemos —cobertura de envíos, dirección del local,
-- plazo de garantía, horarios— la respuesta lo deja abierto en vez de
-- afirmar algo falso.
--
-- LO QUE HAY QUE COMPLETAR con datos reales, desde el panel:
--   · Envíos      → a qué ciudades llegan y con qué transportadora
--   · Retiro      → dirección del local y cómo llegar
--   · Garantía    → plazo y cómo se tramita
--   · Atención    → horarios
-- Son los mismos cuatro que ya están marcados como pendientes en el pie.
--
-- Solo siembra si la tabla está vacía: correrla dos veces no duplica nada ni
-- pisa lo que el cliente haya escrito.

begin;

insert into maxingpy.faqs (faq_category_id, question, answer, sort_order, is_active)
select t.id, v.question, v.answer, v.sort_order, true
from (values
  ('proceso-de-compra',
   '¿Cómo compro en MAXING.py?',
   'Elegís el producto en el sitio y tocás el botón de WhatsApp: el mensaje ya sale con el modelo, el código y el precio publicado. Desde ahí coordinamos el pago y la entrega. No hace falta crear una cuenta ni cargar datos de tarjeta en la web.',
   1),

  ('disponibilidad',
   '¿Todos los productos que veo están disponibles?',
   'Cada producto muestra su estado en la ficha. De todos modos, conviene confirmarlo por WhatsApp antes de cerrar la compra, porque el stock se mueve durante el día.',
   2),

  ('envios',
   '¿Hacen envíos?',
   'Sí. El envío se coordina por WhatsApp al confirmar la compra: ahí te pasamos el plazo y el costo según a dónde vaya.',
   3),

  ('retiro-de-productos',
   '¿Puedo retirar el producto en lugar de que me lo envíen?',
   'Sí. El retiro se coordina por WhatsApp: te confirmamos el punto y el horario antes de que salgas.',
   4),

  ('garantias',
   '¿Los productos tienen garantía?',
   'Sí, todos los productos tienen la garantía oficial del fabricante. Si necesitás usarla, escribinos por WhatsApp con el código del producto y te acompañamos en el trámite.',
   5),

  ('medios-de-pago',
   '¿Qué medios de pago aceptan?',
   'Los precios del sitio están publicados en guaraníes. Los medios de pago disponibles te los confirmamos por WhatsApp al momento de cerrar la compra.',
   6),

  ('facturacion',
   '¿Emiten factura?',
   'Sí. Avisanos por WhatsApp antes de cerrar la compra y te pedimos los datos para emitirla.',
   7)
) as v(tema, question, answer, sort_order)
join maxingpy.faq_categories t on t.slug = v.tema
where not exists (select 1 from maxingpy.faqs);

commit;
