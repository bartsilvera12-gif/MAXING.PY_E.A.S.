#!/usr/bin/perl
# Genera supabase/migrations/003_maxingpy_seed_catalogo.sql leyendo los arrays
# CAT y PRODUCTOS_TODOS de index.html.
#
# Se genera en vez de transcribirse a mano por dos razones: son 24 productos
# con parrafos largos (transcribir a mano garantiza erratas), y si el catalogo
# del HTML cambia antes de correr la migracion, basta con volver a ejecutar
# este script para que el seed siga coincidiendo con el sitio.
#
# Uso: perl .claude/generar-seed.pl
use strict;
use warnings;
use utf8;                 # los nombres de categoria del script llevan acentos
binmode(STDOUT, ":encoding(UTF-8)");

my $raiz = "C:/NEURA/MAXING.PY_E.A.S";
open(my $fh, '<:encoding(UTF-8)', "$raiz/index.html") or die "No pude abrir index.html: $!";
my $html = do { local $/; <$fh> };
close $fh;

# --- utilidades -------------------------------------------------------

# Extrae los literales de string JS de un fragmento, respetando \" y \\.
sub strings {
  my ($txt) = @_;
  my @out;
  while ($txt =~ /"((?:[^"\\]|\\.)*)"/g) {
    my $s = $1;
    $s =~ s/\\"/"/g;
    $s =~ s/\\\\/\\/g;
    push @out, $s;
  }
  return @out;
}

# Valor de un campo `clave: "..."` dentro de una entrada.
sub campo {
  my ($txt, $clave) = @_;
  return undef unless $txt =~ /\b\Q$clave\E:\s*"((?:[^"\\]|\\.)*)"/;
  my $s = $1;
  $s =~ s/\\"/"/g;
  $s =~ s/\\\\/\\/g;
  return $s;
}

# Contenido de un campo `clave: [ ... ]`, contando corchetes para no cortar
# en el primer ] que aparezca dentro de un string.
sub lista {
  my ($txt, $clave) = @_;
  return () unless $txt =~ /\b\Q$clave\E:\s*\[/g;
  my $ini = pos($txt);
  my $prof = 1;
  my $i = $ini;
  my $encomillado = 0;
  while ($i < length($txt) && $prof > 0) {
    my $c = substr($txt, $i, 1);
    if ($encomillado) {
      if ($c eq '\\') { $i += 2; next; }
      $encomillado = 0 if $c eq '"';
    } else {
      if    ($c eq '"') { $encomillado = 1 }
      elsif ($c eq '[') { $prof++ }
      elsif ($c eq ']') { $prof-- }
    }
    $i++;
  }
  return strings(substr($txt, $ini, $i - $ini - 1));
}

# Escape para literales SQL.
sub q_sql {
  my ($v) = @_;
  return 'null' unless defined $v && $v ne '';
  $v =~ s/'/''/g;
  return "'$v'";
}

# --- CAT --------------------------------------------------------------

my ($bloque_cat) = $html =~ /const CAT = \[(.*?)\n\];/s
  or die "No encontre el array CAT";

my @cats;
for my $linea (split /\n/, $bloque_cat) {
  next unless $linea =~ /\{\s*name:/;
  my $nombre = campo($linea, 'name') // next;
  my $foto = campo($linea, 'foto');
  $foto =~ s{^\./}{} if defined $foto;
  push @cats, {
    name  => $nombre,
    desc  => campo($linea, 'count'),
    foto  => $foto,
    icono => campo($linea, 'icono'),
    color => campo($linea, 'color'),
    ink   => campo($linea, 'ink'),
  };
}
die "CAT: esperaba 12, encontre " . scalar(@cats) unless @cats == 12;

# Slug estable por categoria. Se fija a mano y no se deriva del nombre:
# el nombre lo puede editar el admin, el slug es la clave con la que el
# frontend y las urls identifican la categoria.
my %slug_cat = (
  'Celulares' => 'celulares',
  'Notebooks' => 'notebooks',
  'PC & Componentes' => 'pc-componentes',
  'Gaming' => 'gaming',
  'Monitores' => 'monitores',
  'Audio' => 'audio',
  'Periféricos' => 'perifericos',
  'Almacenamiento' => 'almacenamiento',
  'Accesorios' => 'accesorios',
  'Tablets' => 'tablets',
  'Smartwatch & Wearables' => 'smartwatch-wearables',
  'TV' => 'tv',
);

# --- PRODUCTOS_TODOS --------------------------------------------------

my ($bloque_prod) = $html =~ /const PRODUCTOS_TODOS = \[(.*?)\n\];/s
  or die "No encontre el array PRODUCTOS_TODOS";

# Cada entrada arranca con "  { brand:" al principio de una linea.
my @crudas = split /\n(?=\s*\{\s*brand:)/, $bloque_prod;

my @prods;
for my $entrada (@crudas) {
  next unless $entrada =~ /\bfoto:\s*"/;   # solo los reales, los demo no tienen foto
  my $foto = campo($entrada, 'foto');
  (my $slug = $foto) =~ s{^\./productos/}{};
  $slug =~ s/\.(jpg|jpeg|png|webp)$//i;
  $foto =~ s{^\./}{};

  my ($precio) = $entrada =~ /\bprice:\s*(\d+)/;
  my ($precio_viejo) = $entrada =~ /\boldPrice:\s*(\d+)/;

  push @prods, {
    slug     => $slug,
    brand    => campo($entrada, 'brand'),
    name     => campo($entrada, 'name'),
    spec     => campo($entrada, 'spec'),
    sku      => campo($entrada, 'sku'),
    stock    => campo($entrada, 'stock') // 'Disponible',
    alt      => campo($entrada, 'img'),
    foto     => $foto,
    price    => $precio,
    oldprice => $precio_viejo,
    cats     => [ lista($entrada, 'cats') ],
    desc     => [ lista($entrada, 'desc') ],
    features => [ lista($entrada, 'features') ],
  };
}
die "Productos reales: esperaba 24, encontre " . scalar(@prods) unless @prods == 24;

# --- marcas -----------------------------------------------------------

my %slug_marca = (
  'ADATA' => 'adata', 'Ajazz' => 'ajazz', 'Apple' => 'apple', 'FTX' => 'ftx',
  'HP' => 'hp', 'MSI' => 'msi', 'Mtek' => 'mtek', 'Razer' => 'razer',
  'Redragon' => 'redragon', 'Samsung' => 'samsung', 'Seagate' => 'seagate',
  'Sony' => 'sony', 'Xiaomi' => 'xiaomi',
);
my %vistas;
my @marcas = grep { !$vistas{$_}++ } map { $_->{brand} } @prods;
@marcas = sort { lc($a) cmp lc($b) } @marcas;
for my $m (@marcas) {
  die "Falta el slug de la marca '$m'" unless $slug_marca{$m};
}

# --- salida -----------------------------------------------------------

my @sql;
push @sql, <<"CAB";
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

CAB

# categorias
push @sql, "-- ------------------------------------------------- categorias\n";
push @sql, "insert into maxingpy.categories\n  (slug, name, short_description, image_url, icon_svg, color, ink_color, sort_order, is_active)\nvalues\n";
my @filas;
my $orden = 0;
for my $c (@cats) {
  $orden++;
  my $slug = $slug_cat{ $c->{name} } or die "Falta slug para '$c->{name}'";
  push @filas, sprintf("  (%s, %s, %s, %s, %s, %s, %s, %d, true)",
    q_sql($slug), q_sql($c->{name}), q_sql($c->{desc}), q_sql($c->{foto}),
    q_sql($c->{icono}), q_sql($c->{color}), q_sql($c->{ink}), $orden);
}
push @sql, join(",\n", @filas), "\n";
push @sql, "on conflict (slug) do update set\n  name = excluded.name,\n  short_description = excluded.short_description,\n  image_url = excluded.image_url,\n  icon_svg = excluded.icon_svg,\n  color = excluded.color,\n  ink_color = excluded.ink_color,\n  sort_order = excluded.sort_order;\n\n";

# marcas
push @sql, "-- ------------------------------------------------- marcas\n";
push @sql, "insert into maxingpy.brands (slug, name, logo_url, sort_order, is_active)\nvalues\n";
@filas = ();
$orden = 0;
for my $m (@marcas) {
  $orden++;
  push @filas, sprintf("  (%s, %s, %s, %d, true)",
    q_sql($slug_marca{$m}), q_sql($m), q_sql("marcas/$slug_marca{$m}.png"), $orden);
}
push @sql, join(",\n", @filas), "\n";
push @sql, "on conflict (slug) do update set\n  name = excluded.name,\n  logo_url = excluded.logo_url,\n  sort_order = excluded.sort_order;\n\n";

# productos
push @sql, "-- ------------------------------------------------- productos\n";
push @sql, "insert into maxingpy.products\n  (slug, sku, name, brand_id, short_spec, description, price, old_price,\n   stock_status, main_image_url, image_alt, is_published, sort_order)\nvalues\n";
@filas = ();
$orden = 0;
for my $p (@prods) {
  $orden++;
  my $descripcion = join("\n\n", @{ $p->{desc} });
  push @filas, sprintf(
    "  (%s, %s, %s,\n   (select id from maxingpy.brands where slug = %s),\n   %s,\n   %s,\n   %s, %s, %s, %s, %s, true, %d)",
    q_sql($p->{slug}), q_sql($p->{sku}), q_sql($p->{name}),
    q_sql($slug_marca{ $p->{brand} }),
    q_sql($p->{spec}),
    q_sql($descripcion),
    $p->{price}, (defined $p->{oldprice} ? $p->{oldprice} : 'null'),
    q_sql($p->{stock}), q_sql($p->{foto}), q_sql($p->{alt}), $orden);
}
push @sql, join(",\n", @filas), "\n";
push @sql, "on conflict (slug) do update set\n  sku = excluded.sku,\n  name = excluded.name,\n  brand_id = excluded.brand_id,\n  short_spec = excluded.short_spec,\n  description = excluded.description,\n  price = excluded.price,\n  old_price = excluded.old_price,\n  stock_status = excluded.stock_status,\n  main_image_url = excluded.main_image_url,\n  image_alt = excluded.image_alt,\n  sort_order = excluded.sort_order;\n\n";

# producto <-> categoria
push @sql, "-- ------------------------------------------------- producto x categoria\n";
push @sql, "insert into maxingpy.product_categories (product_id, category_id, is_primary)\nvalues\n";
@filas = ();
for my $p (@prods) {
  my $primera = 1;
  for my $c (@{ $p->{cats} }) {
    my $sc = $slug_cat{$c} or die "Producto '$p->{slug}': categoria desconocida '$c'";
    push @filas, sprintf(
      "  ((select id from maxingpy.products where slug = %s),\n   (select id from maxingpy.categories where slug = %s), %s)",
      q_sql($p->{slug}), q_sql($sc), ($primera ? 'true' : 'false'));
    $primera = 0;
  }
}
push @sql, join(",\n", @filas), "\n";
push @sql, "on conflict (product_id, category_id) do update set is_primary = excluded.is_primary;\n\n";

# imagen principal en la galeria
push @sql, "-- ------------------------------------------------- galeria\n";
push @sql, "-- La foto principal tambien entra como primera imagen de la galeria,\n";
push @sql, "-- para que el panel pueda reordenarla junto con las demas.\n";
push @sql, "delete from maxingpy.product_images\n where product_id in (select id from maxingpy.products where slug in (\n";
push @sql, "   " . join(",\n   ", map { q_sql($_->{slug}) } @prods) . "\n ));\n";
push @sql, "insert into maxingpy.product_images (product_id, image_url, alt_text, sort_order)\nvalues\n";
@filas = ();
for my $p (@prods) {
  push @filas, sprintf(
    "  ((select id from maxingpy.products where slug = %s), %s, %s, 1)",
    q_sql($p->{slug}), q_sql($p->{foto}), q_sql($p->{alt}));
}
push @sql, join(",\n", @filas), ";\n\n";

# features
push @sql, "-- ------------------------------------------------- caracteristicas\n";
push @sql, "delete from maxingpy.product_features\n where product_id in (select id from maxingpy.products where slug in (\n";
push @sql, "   " . join(",\n   ", map { q_sql($_->{slug}) } @prods) . "\n ));\n";
push @sql, "insert into maxingpy.product_features (product_id, feature, sort_order)\nvalues\n";
@filas = ();
for my $p (@prods) {
  my $i = 0;
  for my $f (@{ $p->{features} }) {
    $i++;
    push @filas, sprintf("  ((select id from maxingpy.products where slug = %s), %s, %d)",
      q_sql($p->{slug}), q_sql($f), $i);
  }
}
push @sql, join(",\n", @filas), ";\n";

open(my $out, '>:encoding(UTF-8)', "$raiz/supabase/migrations/003_maxingpy_seed_catalogo.sql") or die $!;
print $out join('', @sql);
close $out;

printf("003_maxingpy_seed_catalogo.sql generado\n  %d categorias\n  %d marcas\n  %d productos\n  %d relaciones producto-categoria\n  %d caracteristicas\n",
  scalar(@cats), scalar(@marcas), scalar(@prods),
  scalar(map { @{ $_->{cats} } } @prods),
  scalar(map { @{ $_->{features} } } @prods));
