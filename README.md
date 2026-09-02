# MAXING.py

Sitio web de **MAXING.py** — tecnología e informática en Paraguay.

Sitio estático (HTML + JS), sin build. `index.html` es la página; `MAXING Home.dc.html`
es el artboard editable del design canvas y `support.js` el runtime que lo renderiza.

## Estructura

| Archivo | Descripción |
|---|---|
| `index.html` | Página del sitio (home, productos, detalle de producto). Incluye meta tags SEO, Open Graph, Twitter Card y JSON-LD (Organization, WebSite, BreadcrumbList). |
| `MAXING Home.dc.html` | Artboard fuente del design canvas (mismo contenido que `index.html`). |
| `support.js` | Runtime del design canvas. Generado — no editar a mano. |
| `robots.txt` | Reglas de rastreo. Bloquea `/carrito` y `/cuenta`, apunta al sitemap. |
| `sitemap.xml` | Sitemap con las URLs públicas de `https://maxing.py/`. |
| `favicon.svg` | Favicon principal: monograma "M" + punto verde. La M es un `path`, no texto — los favicons SVG no cargan fuentes externas. |
| `favicon.ico` | Fallback con 16/32/48 px embebidos como PNG. |
| `apple-touch-icon.png` | 180×180 para iOS. |

## Deploy en Vercel

Sitio estático, sin build. Framework: **Other** / Static. Vercel sirve `index.html`
en la raíz automáticamente (ver `vercel.json`), resuelve las rutas de producto y
categoría con sus rewrites, y genera `/sitemap.xml` con la función `api/sitemap.js`.

## Deploy en Hostinger

```bash
powershell -ExecutionPolicy Bypass -File scripts\build.ps1
```

Deja el paquete en `dist/`. Se sube el **contenido** de esa carpeta a
`public_html`, incluidos los `.htaccess` —que el explorador de Windows oculta
por empezar con punto—. Con `-Zip` además arma `dist.zip` para arrastrar al
hPanel.

El build resuelve las dos cosas que en Vercel hace la plataforma y en Hostinger
no existen:

- Los rewrites de `vercel.json` se traducen a `.htaccess`. Sin eso, entrar
  directo a `/productos/msi-katana-15` da 404: ese archivo no existe, la ruta
  la resuelve `index.html` leyendo la URL.
- `/api/sitemap` es una función serverless y Hostinger no ejecuta Node, así que
  el sitemap se congela en un `sitemap.xml` generado durante el build.

**Consecuencia:** cuando se cargan productos nuevos desde el panel, el sitio los
muestra al instante, pero el sitemap sigue con la lista vieja hasta que se
vuelva a correr el build y se suba. En Vercel esto no pasa.

## Ver localmente

`index.html` carga `./support.js`, así que hay que servirlo por HTTP (con `file://` no funciona).

```bash
npx serve .
```

Luego abrir la URL que imprime (por defecto <http://localhost:3000/>).

## Marca

- Dominio: `https://maxing.py/`
- Tipografía: Manrope (Google Fonts)
- Acento: `#40DF36`
- WhatsApp: +595 984 127 274
- Instagram: [@maxing.py](https://instagram.com/maxing.py) · TikTok: [@maxing.py](https://tiktok.com/@maxing.py)

## Efectos visuales (port de React Bits a vanilla)

El sitio no usa React, así que los efectos de [React Bits](https://reactbits.dev)
están reimplementados en CSS/JS puro dentro de `index.html`. Sin dependencias,
sin build, sin peer deps (`motion`, `gsap`, `three`, `ogl`).

| React Bits | Dónde | Técnica |
|---|---|---|
| Aurora | Hero y sección "Setup completo" | 3 capas `radial-gradient` animadas por `transform` |
| BlurText | H1 del hero | Una palabra por `<span>`, entrada escalonada con `blur` + `translateY` |
| ShinyText | Volanta del hero y del promo | `background-clip: text` con degradé en movimiento |
| SpotlightCard | Cards de categorías, productos, marcas e imágenes | `::after` con `radial-gradient` en `--rb-x` / `--rb-y` |
| AnimatedContent / ScrollReveal | Todas las secciones | `IntersectionObserver` + stagger por hermano |
| Marquee | Fila de marcas | Lista duplicada, `translate3d(-50%)` en loop, pausa al hover |
| Magnet | CTA principal y "Armar mi setup" | Wrapper que se desplaza hacia el cursor |

### Cómo está enganchado

- **Hooks por `data-rb`**, no por clases: el runtime del canvas reescribe el
  marcado, pero los `data-*` pasan intactos.
- **El CSS vive en el `<style>` del `<helmet>`**.
- **El JS vive en `rbInit()` / `rbDestroy()` de la clase `Component`**, llamados
  desde `componentDidMount` / `componentWillUnmount`. No se puede usar un
  `<script>` inline suelto: `support.js` re-parsea el documento entero y lo
  renderiza como texto.
- Todo va por **delegación en `document` + `MutationObserver`**, así los efectos
  sobreviven a los re-render del runtime y al cambio de página (home / catálogo /
  producto).
- **Nada de `filter: blur()`** en capas grandes: sólo se animan `transform` y
  `opacity`, que son propiedades compuestas.
- `prefers-reduced-motion: reduce` apaga todas las animaciones y deja el
  contenido visible y con el contraste original.

### Regenerar los iconos

Los tres derivan de la misma geometría (cuadrado negro `rx=14`, M blanca, punto
`#40DF36`). Si cambia la marca, editá `favicon.svg` y replicá los puntos en el
script generador — no hay ImageMagick ni Node en el equipo, así que los raster
se producen con `System.Drawing` de .NET:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/mkicon.ps1 -OutDir .
```

## Modelo: vidriera, no e-commerce

MAXING.py no tiene carrito ni checkout **a propósito**: la venta se cierra por
WhatsApp. Todo lo del catálogo está construido alrededor de esa decisión.

### Filtros del catálogo

Las opciones **se derivan de `PRODUCTS`**, no de listas fijas: si se agrega un
producto con una marca o categoría nueva, el filtro aparece solo, con su conteo.
El rango del slider sale de los precios reales (`PMIN` / `PMAX`).

| Filtro | Campo | Comportamiento |
|---|---|---|
| Categoría | `cat` | Multi-selección; vacío = todas |
| Marca | `brand` | Multi-selección; vacío = todas |
| Disponibilidad | `stock` | `Disponible` / `A pedido` |
| Rango de precio | `price` | Tope máximo, con etiqueta en vivo |
| Ordenar por | — | Relevancia, menor/mayor precio, más recientes |

Los precios se guardan **numéricos** en `PRODUCTS` y se formatean al renderizar
con `P()`. Guardarlos ya formateados hacía imposible comparar y ordenar.

### WhatsApp con el producto identificado

`waFor(p)` arma el link de la ficha con marca, nombre, código y precio, para que
el mensaje llegue sin necesidad de repreguntar cuál producto es. El botón
flotante y los CTA genéricos siguen usando el mensaje corto (`wa`).

### Pendiente de datos reales del cliente

- **Banda operativa del footer** (`footerOps`): cada slot tiene una línea
  `completar:` con lo que falta — cobertura de envíos, dirección del local,
  plazo de garantía y horarios de atención.
- **Códigos de producto**: los `sku` actuales (`MX-NB-0142`, `MX-PE-0207`, …)
  son de demostración, igual que las fotos. Reemplazar por los códigos reales.
- **"IVA incluido"** en la ficha: confirmar que los precios publicados lo
  incluyen antes de salir a producción.

### Color e interacción añadidos

La identidad base sigue siendo negro / blanco / `#40DF36`. El color adicional
está acotado a dos lugares donde aporta significado:

- **Íconos de beneficios**: cada uno tiene su tinte y borde propios
  (verde `#1F8F19`, azul `#1E6FE8`, violeta `#6D3BD1`, ámbar `#C97A06`),
  definidos junto al texto en `benefits`, no en el markup.
- **Redes**: gradiente oficial de Instagram (`#FEC053 → #F2203E → #B729A8 →
  #5342D6`) vía `<linearGradient>`, y el desfase cian/rojo/negro de TikTok
  (`#25F4EE` / `#FE2C55` / `#171717`) con tres capas superpuestas.

Movimiento agregado, todo sobre `transform` y `opacity`:

| Efecto | Dónde |
|---|---|
| Zoom de la foto | 25 fichas; se dispara desde la card entera, no desde la imagen |
| Elevación del ícono | Beneficios |
| Escala + giro del ícono | Botones de redes |
| Latido leve | 5 badges de descuento |
| Feedback táctil | Todos los `<button>` |
| Scroll suave | `html { scroll-behavior: smooth }` |

Todo queda anulado bajo `prefers-reduced-motion: reduce`.

### Verde de marca en navegación y categorías

- **Nav principal**: al hover, texto `#2A8F24`, fondo `#F4FCF3` y subrayado
  `#40DF36`. El subrayado del ítem con mega-menú abierto sigue saliendo del
  estado (`n.underline`), así que ambos conviven sin pisarse.
- **Fichas de categoría**: borde y sombra verdes al hover, y la **barrita de
  2px** del hero reutilizada como motivo — está presente en reposo (18 px) y
  crece a 38 px al pasar por encima.

Se eligió reusar la barrita en lugar de inventar un adorno nuevo: ya existía en
los `heroFacts`, así que el verde suma sin agregar vocabulario visual.
