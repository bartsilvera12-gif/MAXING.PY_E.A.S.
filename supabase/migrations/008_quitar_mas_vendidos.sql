-- =====================================================================
-- MAXING.py — 008: quitar la colección "Más vendidos"
-- =====================================================================
-- Se creó en la migración 004 y nunca pudo mostrarse, por dos motivos:
--
--   1. El sitio dibuja tres secciones de colección —Ofertas, Novedades y
--      Destacados— y esta no tiene ninguna, ni un ancla a la que saltar.
--   2. Su regla es "los más vistos", pero nada incrementa la columna
--      `views`: siempre vale cero, así que ordenaría por nada.
--
-- Se elimina en vez de dejarla apagada: una colección que el panel deja
-- administrar pero el sitio no puede mostrar es una promesa que no se
-- cumple, y confunde a quien administra.
--
-- Para tenerla de verdad haría falta contar las visitas a la ficha de
-- producto y agregarle su propia sección en el inicio. Ese día se crea de
-- nuevo desde el panel, con su ancla.
--
-- Idempotente: si ya no está, no hace nada.
-- =====================================================================

-- Primero las relaciones, por si alguien alcanzó a elegirle productos a
-- mano. El borrado en cascada ya lo haría, pero dejarlo explícito muestra
-- qué se está tocando.
delete from maxingpy.product_collections
 where collection_id in (
   select id from maxingpy.collections where slug = 'mas-vendidos'
 );

delete from maxingpy.collections where slug = 'mas-vendidos';
