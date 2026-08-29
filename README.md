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

## Deploy en Vercel

Sitio estático, sin build. Framework: **Other** / Static. Vercel sirve `index.html`
en la raíz automáticamente (ver `vercel.json`).

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
