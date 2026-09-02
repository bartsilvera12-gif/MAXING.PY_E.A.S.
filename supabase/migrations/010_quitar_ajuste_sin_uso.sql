-- =====================================================================
-- MAXING.py — 010: quitar el ajuste "Mostrar Quiénes somos en el inicio"
-- =====================================================================
-- Ese interruptor no controla nada. "Quiénes somos" vive en su propia
-- página (/nosotros) y no se dibuja en el inicio: el cliente pidió
-- justamente que fuera una subpágina y no apareciera en la portada.
--
-- Se elimina en vez de dejarlo apagado, por lo mismo que "Más vendidos":
-- un interruptor que no apaga nada hace dudar de todos los demás.
--
-- Idempotente.
-- =====================================================================

delete from maxingpy.site_settings where key = 'show_nosotros';
