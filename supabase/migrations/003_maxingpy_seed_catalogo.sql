-- =====================================================================
-- MAXING.py — 003: seed del catalogo real
-- =====================================================================
-- GENERADO por .claude/generar-seed.pl desde index.html. No editar a mano:
-- volve a correr el script si cambia el catalogo del HTML.
--
-- Contiene solo los productos con foto real. Los 12 productos demo del
-- HTML quedan afuera a proposito: publicar precios inventados en una
-- vidriera es peor que un catalogo mas corto.
--
-- Idempotente: se apoya en `on conflict (slug)` para poder re-ejecutarse.
-- =====================================================================

-- ------------------------------------------------- categorias
insert into maxingpy.categories
  (slug, name, short_description, image_url, icon_svg, color, ink_color, sort_order, is_active)
values
  ('celulares', 'Celulares', 'Smartphones y accesorios', 'productos/apple-iphone-17-pro.jpg', null, '#86DC2C', '#4E7F13', 1, true),
  ('notebooks', 'Notebooks', 'Trabajo, estudio y gaming', 'productos/hp-15-fd2050wm.jpg', null, '#6FDD2E', '#3F7F15', 2, true),
  ('pc-componentes', 'PC & Componentes', 'Placas, procesadores, RAM', 'categorias/pc-componentes.jpg', 'M7 7h10v10H7z M10 4v3 M14 4v3 M10 17v3 M14 17v3 M4 10h3 M4 14h3 M17 10h3 M17 14h3', '#5FDE31', '#327F17', 3, true),
  ('gaming', 'Gaming', 'Consolas y setups', 'productos/sony-ps5-pro-2tb.jpg', null, '#4EDE33', '#2A8018', 4, true),
  ('monitores', 'Monitores', 'Full HD a 4K', 'productos/mtek-m27sfv280c.jpg', null, '#40DF36', '#24801C', 5, true),
  ('audio', 'Audio', 'Auriculares y parlantes', 'productos/apple-airpods-pro-3.jpg', null, '#35D944', '#1E7D26', 6, true),
  ('perifericos', 'Periféricos', 'Teclados, mouse y webcams', 'categorias/perifericos.jpg', 'M3 7h18v10H3z M7 11h0.01 M11 11h0.01 M15 11h0.01 M8 14h8', '#2FD453', '#187A32', 7, true),
  ('almacenamiento', 'Almacenamiento', 'SSD, HDD y memorias', 'categorias/almacenamiento.jpg', 'M4 7h16v10H4z M7 12h0.01 M10 12h7 M4 15h16', '#26CC62', '#14783C', 8, true),
  ('accesorios', 'Accesorios', 'Cables, soportes, impresoras', 'categorias/accesorios.jpg', 'M9 3v6 M15 3v6 M6 9h12v3a6 6 0 0 1-12 0V9z M12 18v3', '#22C86F', '#12784A', 9, true),
  ('tablets', 'Tablets', 'iPad y Android', 'categorias/tablets.jpg', 'M6 3h12a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z M10 18h4', '#1DC17C', '#107553', 10, true),
  ('smartwatch-wearables', 'Smartwatch & Wearables', 'Relojes y pulseras', 'productos/apple-watch-s11-42mm.jpg', null, '#1ABB86', '#0E7358', 11, true),
  ('tv', 'TV', 'Smart TV 4K', 'productos/xiaomi-tv-a-2026-65.jpg', null, '#16AE95', '#0C6E60', 12, true)
on conflict (slug) do update set
  name = excluded.name,
  short_description = excluded.short_description,
  image_url = excluded.image_url,
  icon_svg = excluded.icon_svg,
  color = excluded.color,
  ink_color = excluded.ink_color,
  sort_order = excluded.sort_order;

-- ------------------------------------------------- marcas
insert into maxingpy.brands (slug, name, logo_url, sort_order, is_active)
values
  ('adata', 'ADATA', 'marcas/adata.png', 1, true),
  ('ajazz', 'Ajazz', 'marcas/ajazz.png', 2, true),
  ('apple', 'Apple', 'marcas/apple.png', 3, true),
  ('ftx', 'FTX', 'marcas/ftx.png', 4, true),
  ('hp', 'HP', 'marcas/hp.png', 5, true),
  ('msi', 'MSI', 'marcas/msi.png', 6, true),
  ('mtek', 'Mtek', 'marcas/mtek.png', 7, true),
  ('razer', 'Razer', 'marcas/razer.png', 8, true),
  ('redragon', 'Redragon', 'marcas/redragon.png', 9, true),
  ('samsung', 'Samsung', 'marcas/samsung.png', 10, true),
  ('seagate', 'Seagate', 'marcas/seagate.png', 11, true),
  ('sony', 'Sony', 'marcas/sony.png', 12, true),
  ('xiaomi', 'Xiaomi', 'marcas/xiaomi.png', 13, true)
on conflict (slug) do update set
  name = excluded.name,
  logo_url = excluded.logo_url,
  sort_order = excluded.sort_order;

-- ------------------------------------------------- productos
insert into maxingpy.products
  (slug, sku, name, brand_id, short_spec, description, price, old_price,
   stock_status, main_image_url, image_alt, is_published, sort_order)
values
  ('msi-katana-15', 'B14WEK-001US', 'Katana 15 B14WEK-001US',
   (select id from maxingpy.brands where slug = 'msi'),
   'Core i7-14650HX · RTX 5050 8 GB · 16 GB / 512 GB',
   'Potencia gaming lista para llevarla al siguiente nivel. El MSI Katana 15 combina un potente Intel Core i7-14650HX, 16 GB de memoria RAM y 512 GB de almacenamiento SSD, ofreciendo el rendimiento que necesitás para jugar, trabajar y crear sin complicaciones.

Su pantalla de 15,6" brinda una experiencia cómoda para tus partidas y tareas diarias, mientras que la NVIDIA GeForce RTX 5050 de 8 GB aporta la potencia gráfica necesaria para disfrutar de juegos exigentes, edición de contenido y aplicaciones que requieren alto rendimiento.

Con Windows 11 y el característico diseño gaming de MSI, el Katana 15 es una excelente opción para quienes buscan rendimiento, velocidad y versatilidad en un solo equipo.',
   9200000, null, 'Disponible', 'productos/msi-katana-15.jpg', 'foto: MSI Katana 15', true, 1),
  ('hp-15-fd2050wm', '15-FD2050WM', '15-FD2050WM',
   (select id from maxingpy.brands where slug = 'hp'),
   'Core Ultra 5 225U · 15,6" táctil · 8 GB / 512 GB',
   'Elegancia, versatilidad y rendimiento para acompañarte todos los días. El HP 15-FD2050WM cuenta con una pantalla de 15,6" táctil y un diseño en color Silver, combinando comodidad y funcionalidad en un equipo ideal para estudio, trabajo y entretenimiento.

Su procesador Intel Core Ultra 5 225U, acompañado de 8 GB de RAM y 512 GB de almacenamiento SSD, ofrece una experiencia rápida y fluida para realizar múltiples tareas, trabajar con documentos, navegar, estudiar y utilizar tus aplicaciones favoritas.

La pantalla táctil permite interactuar de forma intuitiva con el equipo, mientras que Windows 11 brinda una experiencia moderna y sencilla desde el primer momento.',
   4000000, null, 'Disponible', 'productos/hp-15-fd2050wm.jpg', 'foto: HP 15-FD2050WM', true, 2),
  ('apple-airpods-pro-3', 'MFHP4ZA/A', 'AirPods Pro 3',
   (select id from maxingpy.brands where slug = 'apple'),
   'MagSafe · USB-C · inalámbrico',
   'Sumergite en una experiencia de audio premium con los Apple AirPods Pro 3, diseñados para ofrecer un sonido envolvente, comodidad y una conexión inalámbrica fluida. Su formato compacto y ergonómico permite disfrutarlos cómodamente durante el día, ya sea para escuchar música, realizar llamadas o consumir contenido.

Incorporan estuche de carga MagSafe con conexión USB-C, brindando una forma práctica de mantener tus AirPods siempre listos para usar. Su diseño elegante y minimalista los convierte en el complemento ideal para tus dispositivos Apple.',
   1800000, null, 'Disponible', 'productos/apple-airpods-pro-3.jpg', 'foto: AirPods Pro 3', true, 3),
  ('mtek-m27sfv280c', 'M27SFV280C', 'Monitor Gamer 27" M27SFV280C',
   (select id from maxingpy.brands where slug = 'mtek'),
   'Curvo · Full HD · 280 Hz · 1 ms',
   'Llevá tu experiencia visual al siguiente nivel con el Mtek M27SFV280C, un monitor curvo de 27" diseñado para ofrecer velocidad, fluidez y una experiencia inmersiva, especialmente en gaming.

Su panel VA con resolución Full HD (1920 × 1080) ofrece imágenes nítidas y colores vibrantes, mientras que sus 280 Hz de frecuencia de actualización y 1 ms de tiempo de respuesta permiten disfrutar de movimientos más fluidos y una respuesta rápida en partidas competitivas.

Además, incorpora tecnologías Flicker Free y Blue Light Reduction, pensadas para brindar mayor comodidad durante largas jornadas frente a la pantalla. Su conectividad incluye 2 puertos HDMI, 1 DisplayPort y salida de audio, junto con cables HDMI y DisplayPort incluidos.',
   1400000, null, 'Disponible', 'productos/mtek-m27sfv280c.jpg', 'foto: Mtek M27SFV280C', true, 4),
  ('msi-mag-242c', 'MAG 242C', 'Monitor Gamer 24" MAG 242C',
   (select id from maxingpy.brands where slug = 'msi'),
   'Curvo · Full HD · 180 Hz · 1 ms',
   'Llevá tus partidas a otro nivel con el MSI MAG 242C, un monitor gaming de 24" con pantalla curva, diseñado para ofrecer una experiencia fluida e inmersiva.

Su resolución Full HD proporciona imágenes nítidas, mientras que su frecuencia de actualización de 180 Hz permite disfrutar de movimientos más fluidos, especialmente en juegos competitivos y de acción. Además, su tiempo de respuesta de 1 ms ayuda a mantener una respuesta rápida durante las escenas más dinámicas.

Con su diseño curvo y estética gaming, el MAG 242C es una excelente opción para complementar tu setup, ya sea para jugar, disfrutar de contenido multimedia o trabajar.',
   1100000, null, 'Disponible', 'productos/msi-mag-242c.jpg', 'foto: MSI MAG 242C', true, 5),
  ('apple-iphone-17-pro', 'LL/A3256', 'iPhone 17 Pro 256 GB',
   (select id from maxingpy.brands where slug = 'apple'),
   '6,3" · eSIM · 48+48+48 MP · Deep Blue',
   'Descubrí el nuevo iPhone 17 Pro, un smartphone diseñado para quienes buscan potencia, tecnología y una experiencia premium en cada momento. Su elegante acabado Deep Blue y sus 256 GB de almacenamiento ofrecen el equilibrio perfecto entre estilo y espacio para tus fotos, videos, aplicaciones y archivos.

Con eSIM, disfrutás de una conectividad práctica y moderna, ideal para mantenerte comunicado estés donde estés. Su rendimiento permite disfrutar de tus aplicaciones, juegos, contenido multimedia y herramientas de trabajo con una experiencia fluida.',
   8300000, null, 'Disponible', 'productos/apple-iphone-17-pro.jpg', 'foto: iPhone 17 Pro', true, 6),
  ('apple-iphone-17-pro-max', 'BE/A3526', 'iPhone 17 Pro Max 256 GB',
   (select id from maxingpy.brands where slug = 'apple'),
   '6,9" · 48+48+48 MP · 18 MP · Silver',
   'Potencia, elegancia y una experiencia premium en un solo equipo. El iPhone 17 Pro Max cuenta con 256 GB de almacenamiento, ofreciendo espacio de sobra para tus fotos, videos, aplicaciones y archivos, mientras su diseño en acabado Silver aporta un estilo sofisticado.

Pensado para quienes buscan un smartphone capaz de acompañar un uso exigente, es ideal para crear contenido, editar videos, trabajar, disfrutar de entretenimiento y gestionar tus tareas diarias con comodidad. Su formato Pro Max ofrece una experiencia especialmente atractiva para quienes priorizan una pantalla amplia y una experiencia móvil completa.',
   9100000, null, 'Disponible', 'productos/apple-iphone-17-pro-max.jpg', 'foto: iPhone 17 Pro Max', true, 7),
  ('apple-macbook-neo-13', 'MHFA4LL/A', 'MacBook Neo 13"',
   (select id from maxingpy.brands where slug = 'apple'),
   'Chip A18 Pro · 8 GB / 256 GB · Silver',
   'Elegancia, portabilidad y rendimiento en un solo equipo. El MacBook Neo combina un diseño compacto en color Silver con la potencia y eficiencia del chip Apple A18 Pro, ofreciendo una experiencia fluida para acompañarte tanto en el trabajo como en el estudio.

Cuenta con 8 GB de memoria y 256 GB de almacenamiento, ideales para gestionar documentos, navegar, utilizar aplicaciones, realizar videollamadas y disfrutar de contenido multimedia. Su formato de 13" facilita llevarlo a cualquier lugar sin renunciar a una experiencia cómoda de uso.

Además, forma parte del ecosistema Apple, permitiendo una integración práctica con otros dispositivos y servicios de la marca.',
   5600000, null, 'Disponible', 'productos/apple-macbook-neo-13.jpg', 'foto: MacBook Neo 13', true, 8),
  ('sony-ps5-pro-2tb', 'CFI-7119/7019', 'PlayStation 5 Pro 2 TB Digital',
   (select id from maxingpy.brands where slug = 'sony'),
   '2 TB · Digital Edition · DualSense · White',
   'Llevá tu experiencia gaming al siguiente nivel con la PlayStation 5 Pro, una consola diseñada para quienes buscan mayor potencia, calidad gráfica y rendimiento. Su almacenamiento de 2 TB te permite disfrutar de una amplia biblioteca de juegos sin preocuparte constantemente por el espacio.

La edición Digital ofrece una experiencia completamente enfocada en juegos descargables, mientras que su diseño en color White mantiene la estética moderna y característica de PlayStation.',
   8200000, null, 'Disponible', 'productos/sony-ps5-pro-2tb.jpg', 'foto: PlayStation 5 Pro', true, 9),
  ('sony-ps5-slim-825gb', 'CFI-2115 B01X', 'PlayStation 5 Slim 825 GB Digital',
   (select id from maxingpy.brands where slug = 'sony'),
   '825 GB · Digital Edition · DualSense · White',
   'Disfrutá de una nueva generación de gaming con la PlayStation 5 Slim, una consola que combina potencia, velocidad y un diseño más compacto. Su almacenamiento de 825 GB te permite tener tus títulos favoritos siempre listos para jugar.

Esta Digital Edition está pensada para quienes prefieren descargar y disfrutar sus juegos directamente desde la consola. Además, incluye el control inalámbrico DualSense, que ofrece una experiencia de juego más inmersiva gracias a sus funciones de respuesta háptica y gatillos adaptativos.

Su diseño Slim en color blanco aporta un estilo moderno que se adapta perfectamente a cualquier setup o espacio de entretenimiento.',
   4650000, null, 'Disponible', 'productos/sony-ps5-slim-825gb.jpg', 'foto: PlayStation 5 Slim', true, 10),
  ('apple-iphone-17', 'BE/A3520', 'iPhone 17 256 GB',
   (select id from maxingpy.brands where slug = 'apple'),
   '6,3" · 48+48 MP · 18 MP · Black',
   'Descubrí el iPhone 17, un smartphone que combina potencia, diseño y versatilidad para acompañarte en cada momento. Su elegante acabado Black le brinda un estilo moderno y sofisticado, mientras que sus 256 GB de almacenamiento ofrecen amplio espacio para tus fotos, videos, aplicaciones y archivos.

Pensado para el día a día, es una excelente opción tanto para trabajo como para entretenimiento. Disfrutá de tus contenidos, capturá tus mejores momentos y mantenete conectado estés donde estés, con una experiencia fluida y práctica.',
   6700000, null, 'Disponible', 'productos/apple-iphone-17.jpg', 'foto: iPhone 17', true, 11),
  ('samsung-tv-55-un55u8000', 'UN55U8000FGXPR', 'Smart TV LED 55" UN55U8000FGXPR',
   (select id from maxingpy.brands where slug = 'samsung'),
   '55" · UHD 4K · Crystal · Smart TV',
   'Disfrutá de una experiencia de entretenimiento más inmersiva con el Samsung Smart TV de 55", que combina un diseño elegante con la calidad de imagen UHD 4K y la tecnología Crystal para ofrecer imágenes nítidas, colores vibrantes y gran nivel de detalle.

Su pantalla de 55 pulgadas es ideal para disfrutar películas, series, deportes y videojuegos con una experiencia visual envolvente. Gracias a sus funciones Smart, podés acceder fácilmente a tus plataformas y contenidos favoritos desde un solo lugar.

Perfecto para convertir tu sala en un verdadero espacio de entretenimiento, ya sea para una noche de películas, disfrutar de tus series favoritas o vivir tus partidas en una pantalla de gran tamaño.',
   3200000, null, 'Disponible', 'productos/samsung-tv-55-un55u8000.jpg', 'foto: Samsung Smart TV 55', true, 12),
  ('xiaomi-tv-a-2026-65', 'L65MB-APH', 'Smart TV LED 65" A 2026 L65MB-APH',
   (select id from maxingpy.brands where slug = 'xiaomi'),
   '65" · 4K UHD · Google TV · LED',
   'Llevá el entretenimiento a otro nivel con la Xiaomi Smart TV A 2026 de 65", una pantalla de gran formato que combina resolución 4K, tecnología LED y Google TV para ofrecer una experiencia completa en tu hogar.

Su pantalla de 65 pulgadas permite disfrutar películas, series, deportes y videojuegos con gran nivel de detalle, mientras que Google TV facilita el acceso a tus aplicaciones y plataformas de streaming favoritas desde una interfaz práctica y moderna.

Ideal para convertir tu sala en un verdadero centro de entretenimiento, disfrutar noches de cine en familia o vivir tus contenidos favoritos con una experiencia más inmersiva.',
   3750000, null, 'Disponible', 'productos/xiaomi-tv-a-2026-65.jpg', 'foto: Xiaomi Smart TV 65', true, 13),
  ('apple-watch-s11-42mm', 'MEQT4LW', 'Watch Series 11 42 mm GPS',
   (select id from maxingpy.brands where slug = 'apple'),
   '42 mm · GPS · Sport Band · Jet Black',
   'Tecnología, estilo y funcionalidad en tu muñeca. El Apple Watch Series 11 de 42 mm combina un diseño elegante en color Jet Black con una correa Sport Band, ofreciendo un look moderno que se adapta tanto a tu rutina diaria como a tus momentos de entrenamiento.

Su conectividad GPS te permite disfrutar de funciones de ubicación y seguimiento durante tus actividades, mientras que su integración con el ecosistema Apple facilita mantenerte conectado, consultar información y gestionar diferentes funciones directamente desde tu muñeca.',
   2550000, null, 'Disponible', 'productos/apple-watch-s11-42mm.jpg', 'foto: Apple Watch Series 11', true, 14),
  ('apple-ipad-11-128gb', 'MD4A4LL/A', 'iPad 11" 128 GB Wi-Fi',
   (select id from maxingpy.brands where slug = 'apple'),
   '11" · A16 · 128 GB · 12+12 MP · Blue',
   'El iPad 11" MD4A4LL/A es una tablet de 11" en color azul, con conectividad Wi-Fi y 128 GB de almacenamiento. Combina un diseño ligero y una pantalla amplia para que puedas leer, crear y disfrutar contenido con fluidez, ideal para quienes buscan un equipo versátil para el día a día.

Es especialmente útil para estudiar y trabajar en movilidad: tomá notas, revisá documentos y organizá tareas desde cualquier lugar. También funciona muy bien para entretenimiento y creatividad, como ver series en casa y editar o diseñar contenido en aplicaciones compatibles. Su formato de 11" facilita el uso tanto en modo vertical como horizontal.

Para una experiencia consistente, usalo con tu cuenta Apple y sincronizá tus apps y archivos según tu flujo de trabajo. Mantené la pantalla limpia con un paño suave y evitá golpes o presión en el borde. La instalación es sencilla: encendé, seguí el asistente de configuración y conectá a tu red Wi-Fi.',
   3300000, null, 'Disponible', 'productos/apple-ipad-11-128gb.jpg', 'foto: iPad 11', true, 15),
  ('xiaomi-redmi-pad-2', 'Redmi Pad 2', 'Redmi Pad 2 11" 256 GB',
   (select id from maxingpy.brands where slug = 'xiaomi'),
   '11" · 8 GB RAM · 256 GB · Wi-Fi · Gray',
   'Potencia, comodidad y entretenimiento en un solo dispositivo. La Xiaomi Redmi Pad 2 cuenta con una amplia pantalla de 11", 8 GB de RAM y 256 GB de almacenamiento, ofreciendo espacio y fluidez para tus aplicaciones, archivos, fotos y contenido favorito.

Su conectividad Wi-Fi la convierte en una excelente compañera para estudiar, trabajar o disfrutar de entretenimiento desde cualquier lugar. Es ideal para tomar notas, revisar documentos, navegar, seguir clases, ver series y disfrutar de contenido multimedia con mayor comodidad.

El acabado Graphite Gray aporta un estilo moderno y sofisticado, mientras que su formato permite utilizarla cómodamente tanto en casa como en movimiento.',
   1620000, null, 'Disponible', 'productos/xiaomi-redmi-pad-2.jpg', 'foto: Redmi Pad 2', true, 16),
  ('samsung-galaxy-tab-s10-fe', 'X520', 'Galaxy Tab S10 FE 10,9" 128 GB',
   (select id from maxingpy.brands where slug = 'samsung'),
   '10,9" · 8 GB RAM · 128 GB · S Pen · Gray',
   'Potencia, versatilidad y creatividad en un solo dispositivo. La Samsung Galaxy Tab S10 FE cuenta con una pantalla de 10,9", 8 GB de RAM y 128 GB de almacenamiento, ofreciendo una experiencia fluida para estudiar, trabajar, crear y disfrutar de tu contenido favorito.

Su gran diferencial es el S Pen incluido, que permite tomar apuntes, escribir, dibujar y trabajar sobre documentos de manera natural y precisa. Es una excelente compañera para estudiantes, profesionales y creadores que buscan la comodidad de una tablet sin renunciar a productividad.

Su elegante acabado Gray aporta un estilo moderno y sofisticado, mientras que su conectividad Wi-Fi permite mantenerte conectado en casa, la oficina o la universidad.',
   2900000, null, 'Disponible', 'productos/samsung-galaxy-tab-s10-fe.jpg', 'foto: Galaxy Tab S10 FE', true, 17),
  ('ajazz-af98-negro', 'AF98 Nacodexx', 'Teclado Gamer AF98 Nacodexx',
   (select id from maxingpy.brands where slug = 'ajazz'),
   'RGB · USB · inglés · negro / gris',
   'Dale personalidad y rendimiento a tu setup con el Ajazz AF98 Nacodexx, un teclado gamer diseñado para quienes buscan una experiencia cómoda, rápida y con estilo.

Su formato compacto permite aprovechar mejor el espacio del escritorio sin renunciar a una distribución completa de teclas. Además, su iluminación RGB aporta un toque gaming que podés adaptar a tu setup, convirtiéndolo en una excelente opción tanto para jugar como para trabajar o estudiar.

Cuenta con conexión USB, ofreciendo una conexión práctica y estable para disfrutarlo desde el primer momento.',
   185000, null, 'Disponible', 'productos/ajazz-af98-negro.jpg', 'foto: Ajazz AF98 negro', true, 18),
  ('ajazz-af98-azul', 'AF98 Nacodexx Azul', 'Teclado Gamer AF98 Nacodexx Azul',
   (select id from maxingpy.brands where slug = 'ajazz'),
   'RGB · USB · inglés · azul',
   'Dale un toque único a tu setup con el Ajazz AF98 Nacodexx, un teclado gamer que combina diseño, iluminación RGB y comodidad en un formato compacto y moderno.

Su distribución está pensada para aprovechar el espacio del escritorio sin dejar de lado las funciones necesarias para gaming y uso diario. La iluminación RGB aporta personalidad a tu setup y crea una experiencia más inmersiva durante tus partidas.

Con su conexión USB, ofrece una conexión sencilla y estable, ideal para conectar directamente a tu PC y comenzar a utilizarlo.',
   185000, null, 'Disponible', 'productos/ajazz-af98-azul.jpg', 'foto: Ajazz AF98 azul', true, 19),
  ('razer-tartarus-v2', 'Tartarus V2', 'Tartarus V2 Chroma',
   (select id from maxingpy.brands where slug = 'razer'),
   '32 teclas programables · Mecha-Membrane · RGB',
   'Llevá tu experiencia gaming a otro nivel con el Razer Tartarus V2 Chroma, un teclado gamer diseñado para ofrecer control, precisión y personalización en cada partida.

Su formato de 32 teclas totalmente programables permite configurar comandos, atajos y funciones según tus preferencias, brindando un acceso rápido a las acciones más importantes durante el juego. Además, la tecnología Mecha-Membrane combina la respuesta táctil de un teclado mecánico con la comodidad de una membrana.

La iluminación Razer Chroma RGB completa el setup con una experiencia visual personalizable, ideal para crear un espacio gaming a tu medida.',
   735000, null, 'Disponible', 'productos/razer-tartarus-v2.jpg', 'foto: Razer Tartarus V2', true, 20),
  ('ftx-gk03s-dorado', 'GK03S', 'Kit Teclado + Mouse GK03S Wireless',
   (select id from maxingpy.brands where slug = 'ftx'),
   'Inalámbrico · portugués · dorado',
   'Combiná estilo, comodidad y libertad de movimiento con el kit inalámbrico FTX GK03S, que incluye teclado y mouse en un elegante acabado Dorado.

Su conexión inalámbrica permite mantener un escritorio más ordenado y disfrutar de una experiencia práctica tanto para trabajar como para estudiar o navegar. El diseño moderno y minimalista se adapta fácilmente a distintos espacios, aportando un toque sofisticado a tu setup.',
   135000, null, 'Disponible', 'productos/ftx-gk03s-dorado.jpg', 'foto: kit FTX GK03S', true, 21),
  ('adata-xpg-lancer-blade-16gb', 'AX5U6000C4816G-SLABRBK', 'XPG Lancer Blade DDR5 16 GB 6000 MHz',
   (select id from maxingpy.brands where slug = 'adata'),
   'DDR5 · 16 GB · 6000 MHz · RGB · perfil bajo',
   'Potenciá el rendimiento de tu PC con la ADATA XPG Lancer Blade DDR5, una memoria RAM diseñada para ofrecer velocidad, fluidez y una estética gaming que destaca en cualquier setup.

Con 16 GB de capacidad y una velocidad de 6000 MHz, es una excelente opción para mejorar la respuesta del sistema, disfrutar de gaming, multitarea y aplicaciones exigentes. Su diseño de perfil bajo facilita su integración en diferentes configuraciones, mientras que la iluminación RGB aporta un toque personalizable a tu equipo.',
   2200000, null, 'Disponible', 'productos/adata-xpg-lancer-blade-16gb.jpg', 'foto: ADATA XPG Lancer Blade', true, 22),
  ('seagate-constellation-es3-3tb', 'ST3000NM0023', 'Constellation ES.3 3 TB SAS 3,5"',
   (select id from maxingpy.brands where slug = 'seagate'),
   '3 TB · SAS · 7200 RPM · 3,5"',
   'Potenciá el almacenamiento de tus equipos con el Seagate Constellation ES.3, un disco duro de 3 TB diseñado para ofrecer capacidad y rendimiento en entornos que requieren un almacenamiento confiable.

Su formato de 3,5" y conexión SAS lo convierten en una alternativa ideal para servidores, estaciones de trabajo y sistemas de almacenamiento compatibles. Con 7.200 RPM, ofrece un desempeño adecuado para gestionar grandes volúmenes de información y mantener un acceso ágil a tus datos.

Una excelente opción para ampliar la capacidad de almacenamiento de sistemas profesionales y equipos compatibles con tecnología SAS.',
   700000, null, 'Disponible', 'productos/seagate-constellation-es3-3tb.jpg', 'foto: Seagate Constellation ES.3', true, 23),
  ('redragon-m916w-pro-4k', 'M916W-PRO-4K', 'Mouse Gamer K1NG M916W-PRO-4K',
   (select id from maxingpy.brands where slug = 'redragon'),
   'Inalámbrico · 4K Pro · 5 botones · blanco',
   'Llevá tu precisión al siguiente nivel con el Redragon M916W-PRO-4K K1NG, un mouse gamer inalámbrico diseñado para quienes buscan velocidad, control y libertad de movimiento en cada partida.

Su diseño liviano y ergonómico permite jugar cómodamente durante largas sesiones, mientras que sus 5 botones programables ofrecen la posibilidad de personalizar comandos y accesos según tu estilo de juego. Su conectividad Wireless brinda una experiencia más limpia, sin cables que limiten tus movimientos.

El acabado Blanco aporta un look moderno que combina perfectamente con setups minimalistas o gaming.',
   450000, null, 'Disponible', 'productos/redragon-m916w-pro-4k.jpg', 'foto: Redragon K1NG', true, 24)
on conflict (slug) do update set
  sku = excluded.sku,
  name = excluded.name,
  brand_id = excluded.brand_id,
  short_spec = excluded.short_spec,
  description = excluded.description,
  price = excluded.price,
  old_price = excluded.old_price,
  stock_status = excluded.stock_status,
  main_image_url = excluded.main_image_url,
  image_alt = excluded.image_alt,
  sort_order = excluded.sort_order;

-- ------------------------------------------------- producto x categoria
insert into maxingpy.product_categories (product_id, category_id, is_primary)
values
  ((select id from maxingpy.products where slug = 'msi-katana-15'),
   (select id from maxingpy.categories where slug = 'notebooks'), true),
  ((select id from maxingpy.products where slug = 'msi-katana-15'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'),
   (select id from maxingpy.categories where slug = 'notebooks'), true),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'),
   (select id from maxingpy.categories where slug = 'audio'), true),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'),
   (select id from maxingpy.categories where slug = 'monitores'), true),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'),
   (select id from maxingpy.categories where slug = 'monitores'), true),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'),
   (select id from maxingpy.categories where slug = 'celulares'), true),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'),
   (select id from maxingpy.categories where slug = 'celulares'), true),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'),
   (select id from maxingpy.categories where slug = 'notebooks'), true),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'),
   (select id from maxingpy.categories where slug = 'gaming'), true),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'),
   (select id from maxingpy.categories where slug = 'gaming'), true),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'),
   (select id from maxingpy.categories where slug = 'celulares'), true),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'),
   (select id from maxingpy.categories where slug = 'tv'), true),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'),
   (select id from maxingpy.categories where slug = 'tv'), true),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'),
   (select id from maxingpy.categories where slug = 'smartwatch-wearables'), true),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'),
   (select id from maxingpy.categories where slug = 'tablets'), true),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'),
   (select id from maxingpy.categories where slug = 'tablets'), true),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'),
   (select id from maxingpy.categories where slug = 'tablets'), true),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'),
   (select id from maxingpy.categories where slug = 'perifericos'), true),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'),
   (select id from maxingpy.categories where slug = 'perifericos'), true),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'),
   (select id from maxingpy.categories where slug = 'perifericos'), true),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'),
   (select id from maxingpy.categories where slug = 'perifericos'), true),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'),
   (select id from maxingpy.categories where slug = 'pc-componentes'), true),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'),
   (select id from maxingpy.categories where slug = 'gaming'), false),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'),
   (select id from maxingpy.categories where slug = 'almacenamiento'), true),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'),
   (select id from maxingpy.categories where slug = 'pc-componentes'), false),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'),
   (select id from maxingpy.categories where slug = 'perifericos'), true),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'),
   (select id from maxingpy.categories where slug = 'gaming'), false)
on conflict (product_id, category_id) do update set is_primary = excluded.is_primary;

-- ------------------------------------------------- galeria
-- La foto principal tambien entra como primera imagen de la galeria,
-- para que el panel pueda reordenarla junto con las demas.
delete from maxingpy.product_images
 where product_id in (select id from maxingpy.products where slug in (
   'msi-katana-15',
   'hp-15-fd2050wm',
   'apple-airpods-pro-3',
   'mtek-m27sfv280c',
   'msi-mag-242c',
   'apple-iphone-17-pro',
   'apple-iphone-17-pro-max',
   'apple-macbook-neo-13',
   'sony-ps5-pro-2tb',
   'sony-ps5-slim-825gb',
   'apple-iphone-17',
   'samsung-tv-55-un55u8000',
   'xiaomi-tv-a-2026-65',
   'apple-watch-s11-42mm',
   'apple-ipad-11-128gb',
   'xiaomi-redmi-pad-2',
   'samsung-galaxy-tab-s10-fe',
   'ajazz-af98-negro',
   'ajazz-af98-azul',
   'razer-tartarus-v2',
   'ftx-gk03s-dorado',
   'adata-xpg-lancer-blade-16gb',
   'seagate-constellation-es3-3tb',
   'redragon-m916w-pro-4k'
 ));
insert into maxingpy.product_images (product_id, image_url, alt_text, sort_order)
values
  ((select id from maxingpy.products where slug = 'msi-katana-15'), 'productos/msi-katana-15.jpg', 'foto: MSI Katana 15', 1),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), 'productos/hp-15-fd2050wm.jpg', 'foto: HP 15-FD2050WM', 1),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'productos/apple-airpods-pro-3.jpg', 'foto: AirPods Pro 3', 1),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'productos/mtek-m27sfv280c.jpg', 'foto: Mtek M27SFV280C', 1),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'productos/msi-mag-242c.jpg', 'foto: MSI MAG 242C', 1),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), 'productos/apple-iphone-17-pro.jpg', 'foto: iPhone 17 Pro', 1),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), 'productos/apple-iphone-17-pro-max.jpg', 'foto: iPhone 17 Pro Max', 1),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), 'productos/apple-macbook-neo-13.jpg', 'foto: MacBook Neo 13', 1),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), 'productos/sony-ps5-pro-2tb.jpg', 'foto: PlayStation 5 Pro', 1),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'productos/sony-ps5-slim-825gb.jpg', 'foto: PlayStation 5 Slim', 1),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), 'productos/apple-iphone-17.jpg', 'foto: iPhone 17', 1),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'productos/samsung-tv-55-un55u8000.jpg', 'foto: Samsung Smart TV 55', 1),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'productos/xiaomi-tv-a-2026-65.jpg', 'foto: Xiaomi Smart TV 65', 1),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'productos/apple-watch-s11-42mm.jpg', 'foto: Apple Watch Series 11', 1),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), 'productos/apple-ipad-11-128gb.jpg', 'foto: iPad 11', 1),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), 'productos/xiaomi-redmi-pad-2.jpg', 'foto: Redmi Pad 2', 1),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), 'productos/samsung-galaxy-tab-s10-fe.jpg', 'foto: Galaxy Tab S10 FE', 1),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'productos/ajazz-af98-negro.jpg', 'foto: Ajazz AF98 negro', 1),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'productos/ajazz-af98-azul.jpg', 'foto: Ajazz AF98 azul', 1),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), 'productos/razer-tartarus-v2.jpg', 'foto: Razer Tartarus V2', 1),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'productos/ftx-gk03s-dorado.jpg', 'foto: kit FTX GK03S', 1),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'productos/adata-xpg-lancer-blade-16gb.jpg', 'foto: ADATA XPG Lancer Blade', 1),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), 'productos/seagate-constellation-es3-3tb.jpg', 'foto: Seagate Constellation ES.3', 1),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), 'productos/redragon-m916w-pro-4k.jpg', 'foto: Redragon K1NG', 1);

-- ------------------------------------------------- caracteristicas
delete from maxingpy.product_features
 where product_id in (select id from maxingpy.products where slug in (
   'msi-katana-15',
   'hp-15-fd2050wm',
   'apple-airpods-pro-3',
   'mtek-m27sfv280c',
   'msi-mag-242c',
   'apple-iphone-17-pro',
   'apple-iphone-17-pro-max',
   'apple-macbook-neo-13',
   'sony-ps5-pro-2tb',
   'sony-ps5-slim-825gb',
   'apple-iphone-17',
   'samsung-tv-55-un55u8000',
   'xiaomi-tv-a-2026-65',
   'apple-watch-s11-42mm',
   'apple-ipad-11-128gb',
   'xiaomi-redmi-pad-2',
   'samsung-galaxy-tab-s10-fe',
   'ajazz-af98-negro',
   'ajazz-af98-azul',
   'razer-tartarus-v2',
   'ftx-gk03s-dorado',
   'adata-xpg-lancer-blade-16gb',
   'seagate-constellation-es3-3tb',
   'redragon-m916w-pro-4k'
 ));
insert into maxingpy.product_features (product_id, feature, sort_order)
values
  ((select id from maxingpy.products where slug = 'msi-katana-15'), 'Intel Core i7-14650HX', 1),
  ((select id from maxingpy.products where slug = 'msi-katana-15'), 'NVIDIA GeForce RTX 5050 8 GB', 2),
  ((select id from maxingpy.products where slug = 'msi-katana-15'), '16 GB de RAM', 3),
  ((select id from maxingpy.products where slug = 'msi-katana-15'), 'SSD de 512 GB', 4),
  ((select id from maxingpy.products where slug = 'msi-katana-15'), 'Pantalla de 15,6"', 5),
  ((select id from maxingpy.products where slug = 'msi-katana-15'), 'Windows 11', 6),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), 'Intel Core Ultra 5 225U', 1),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), 'Pantalla táctil de 15,6"', 2),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), '8 GB de RAM', 3),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), 'SSD de 512 GB', 4),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), 'Windows 11', 5),
  ((select id from maxingpy.products where slug = 'hp-15-fd2050wm'), 'Diseño Silver', 6),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'Audio de alta calidad', 1),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'Conexión inalámbrica', 2),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'Estuche de carga MagSafe', 3),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'Puerto USB-C', 4),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'Diseño compacto y elegante', 5),
  ((select id from maxingpy.products where slug = 'apple-airpods-pro-3'), 'Integración con el ecosistema Apple', 6),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'Pantalla curva de 27"', 1),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'Frecuencia de actualización de 280 Hz', 2),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'Tiempo de respuesta de 1 ms', 3),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'Panel VA Full HD (1920 × 1080)', 4),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'Flicker Free y Blue Light Reduction', 5),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), '2 HDMI, 1 DisplayPort y salida de audio', 6),
  ((select id from maxingpy.products where slug = 'mtek-m27sfv280c'), 'Cables HDMI y DisplayPort incluidos', 7),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'Pantalla curva de 24"', 1),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'Resolución Full HD', 2),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'Frecuencia de actualización de 180 Hz', 3),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'Tiempo de respuesta de 1 ms', 4),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'Diseño gaming MSI', 5),
  ((select id from maxingpy.products where slug = 'msi-mag-242c'), 'Ideal para gaming competitivo', 6),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), '256 GB de almacenamiento', 1),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), 'Color Deep Blue', 2),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), 'Tecnología eSIM', 3),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), 'Cámaras 48+48+48 MP', 4),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), 'Frontal de 18 MP', 5),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro'), 'Pantalla de 6,3"', 6),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), '256 GB de almacenamiento', 1),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), 'Color Silver', 2),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), 'Rendimiento de gama Pro', 3),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), 'Cámaras 48+48+48 MP', 4),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), 'Frontal de 18 MP', 5),
  ((select id from maxingpy.products where slug = 'apple-iphone-17-pro-max'), 'Pantalla de 6,9"', 6),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), 'Pantalla de 13"', 1),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), 'Chip Apple A18 Pro', 2),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), '8 GB de memoria', 3),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), '256 GB de almacenamiento', 4),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), 'Color Silver', 5),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), 'Ecosistema Apple', 6),
  ((select id from maxingpy.products where slug = 'apple-macbook-neo-13'), 'Diseño compacto y portátil', 7),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), '2 TB de almacenamiento', 1),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), 'Alto rendimiento para gaming', 2),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), 'Experiencia visual de nueva generación', 3),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), 'Edición Digital', 4),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), 'Color White', 5),
  ((select id from maxingpy.products where slug = 'sony-ps5-pro-2tb'), 'Incluye control inalámbrico DualSense', 6),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), '825 GB de almacenamiento', 1),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'Alto rendimiento y carga rápida', 2),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'Edición Digital', 3),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'Control inalámbrico DualSense incluido', 4),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'Color White', 5),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'Modelo CFI-2115 B01X', 6),
  ((select id from maxingpy.products where slug = 'sony-ps5-slim-825gb'), 'Diseño compacto Slim', 7),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), '256 GB de almacenamiento', 1),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), 'Color Black', 2),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), 'Alto rendimiento', 3),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), 'Cámaras 48+48 MP', 4),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), 'Frontal de 18 MP', 5),
  ((select id from maxingpy.products where slug = 'apple-iphone-17'), 'Pantalla de 6,3"', 6),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'Pantalla de 55"', 1),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'Resolución UHD 4K', 2),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'Tecnología Crystal', 3),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'Smart TV', 4),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'Ideal para películas, series y streaming', 5),
  ((select id from maxingpy.products where slug = 'samsung-tv-55-un55u8000'), 'Excelente opción para gaming y entretenimiento', 6),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Pantalla LED de 65"', 1),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Resolución 4K UHD', 2),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Google TV', 3),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Ideal para streaming y películas', 4),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Excelente para deportes', 5),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Ideal para gaming casual', 6),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Diseño moderno y elegante', 7),
  ((select id from maxingpy.products where slug = 'xiaomi-tv-a-2026-65'), 'Conectividad inteligente', 8),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'Caja de 42 mm', 1),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'GPS', 2),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'Color Jet Black', 3),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'Correa Sport Band, talle S/M', 4),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'Integración con el ecosistema Apple', 5),
  ((select id from maxingpy.products where slug = 'apple-watch-s11-42mm'), 'Diseño moderno y elegante', 6),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), 'Pantalla de 11"', 1),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), 'Chip A16', 2),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), '128 GB de almacenamiento', 3),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), 'Conectividad Wi-Fi', 4),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), 'Cámaras de 12 MP', 5),
  ((select id from maxingpy.products where slug = 'apple-ipad-11-128gb'), 'Color Blue', 6),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), 'Pantalla de 11"', 1),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), '8 GB de RAM', 2),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), '256 GB de almacenamiento', 3),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), 'Conectividad Wi-Fi', 4),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), 'Cámaras 8 + 5 MP', 5),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), 'Color Graphite Gray', 6),
  ((select id from maxingpy.products where slug = 'xiaomi-redmi-pad-2'), 'Ideal para entretenimiento y streaming', 7),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), 'Pantalla de 10,9"', 1),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), '8 GB de RAM', 2),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), '128 GB de almacenamiento', 3),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), 'S Pen incluido', 4),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), 'Conectividad Wi-Fi', 5),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), 'Cámaras 13 + 12 MP', 6),
  ((select id from maxingpy.products where slug = 'samsung-galaxy-tab-s10-fe'), 'Color Gray', 7),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'Diseño gamer', 1),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'Iluminación RGB', 2),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'Conexión USB', 3),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'Distribución en inglés', 4),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'Color negro / gris', 5),
  ((select id from maxingpy.products where slug = 'ajazz-af98-negro'), 'Ideal para gaming y productividad', 6),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Diseño gaming', 1),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Iluminación RGB', 2),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Conexión USB', 3),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Distribución en inglés', 4),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Color azul', 5),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Formato compacto', 6),
  ((select id from maxingpy.products where slug = 'ajazz-af98-azul'), 'Ideal para gaming, estudio y trabajo', 7),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), '32 teclas totalmente programables', 1),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), 'Tecnología Mecha-Membrane', 2),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), 'Iluminación Razer Chroma RGB', 3),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), 'Diseño pensado para gaming', 4),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), 'Color Black', 5),
  ((select id from maxingpy.products where slug = 'razer-tartarus-v2'), 'Ideal para juegos competitivos y de acción', 6),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Teclado inalámbrico', 1),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Mouse inalámbrico incluido', 2),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Conexión Wireless', 3),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Diseño moderno y elegante', 4),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Color Dorado', 5),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Distribución en portugués', 6),
  ((select id from maxingpy.products where slug = 'ftx-gk03s-dorado'), 'Ideal para PC, oficina y estudio', 7),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), '16 GB de memoria RAM', 1),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'Tecnología DDR5', 2),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'Velocidad de 6000 MHz', 3),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'Iluminación RGB', 4),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'Diseño de perfil bajo', 5),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'Color negro', 6),
  ((select id from maxingpy.products where slug = 'adata-xpg-lancer-blade-16gb'), 'Ideal para gaming y multitarea', 7),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), '3 TB de capacidad', 1),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), '7.200 RPM', 2),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), 'Interfaz SAS', 3),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), 'Formato 3,5"', 4),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), 'Diseñado para entornos profesionales', 5),
  ((select id from maxingpy.products where slug = 'seagate-constellation-es3-3tb'), 'Ideal para servidores y almacenamiento de datos', 6),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), 'Tecnología 4K Pro', 1),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), 'Conexión inalámbrica', 2),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), '5 botones programables', 3),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), 'Diseño gamer ergonómico', 4),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), 'Color White', 5),
  ((select id from maxingpy.products where slug = 'redragon-m916w-pro-4k'), 'Ideal para gaming competitivo', 6);
