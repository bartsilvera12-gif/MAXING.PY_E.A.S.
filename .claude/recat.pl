# Reasigna la categoria de cada producto a las 12 nuevas.
# La clave es el SKU: es unico y no trae comillas ni acentos que compliquen el
# reemplazo. Cambia `cat: "X"` por `cats: [...]` en la linea de ese producto.
use strict;
use warnings;

my $PERIF = "Perif\x{00E9}ricos";  # Perifericos, con acento

my %mapa = (
  # --- catalogo real ---
  'B14WEK-001US'   => ['Notebooks', 'Gaming'],
  '15-FD2050WM'    => ['Notebooks'],
  'MFHP4ZA/A'      => ['Audio'],
  'M27SFV280C'     => ['Monitores', 'Gaming'],
  'MAG 242C'       => ['Monitores', 'Gaming'],
  'LL/A3256'       => ['Celulares'],
  'BE/A3526'       => ['Celulares'],
  'MHFA4LL/A'      => ['Notebooks'],
  'CFI-7119/7019'  => ['Gaming'],
  'CFI-2115 B01X'  => ['Gaming'],
  'BE/A3520'       => ['Celulares'],
  'UN55U8000FGXPR' => ['TV'],
  'L65MB-APH'      => ['TV'],
  'MEQT4LW'        => ['Smartwatch & Wearables'],
  # --- demo, pendiente de reemplazo ---
  'MX-NB-0142'     => ['Notebooks', 'Gaming'],
  'MX-PE-0207'     => [$PERIF],
  'MX-MO-0311'     => ['Monitores', 'Gaming'],
  'MX-AL-0128'     => ['Almacenamiento'],
  'MX-NB-0163'     => ['Notebooks'],
  'MX-PE-0245'     => [$PERIF, 'Gaming'],
  'MX-CO-0189'     => ['PC & Componentes', 'Gaming'],
  'MX-AU-0102'     => ['Audio'],
  'MX-AC-0154'     => ['Accesorios'],
  'MX-NB-0171'     => ['Notebooks', 'Gaming'],
  'MX-CE-0119'     => ['Celulares'],
  'MX-AC-0136'     => ['Accesorios', $PERIF],
);

my $ruta = 'index.html';
open(my $in, '<:encoding(UTF-8)', $ruta) or die "no puedo abrir $ruta: $!";
my @lineas = <$in>;
close($in);

my $cambiadas = 0;
my @sinMapa;
for my $l (@lineas) {
  next unless $l =~ /sku: "([^"]+)"/;
  my $sku = $1;
  unless (exists $mapa{$sku}) { push @sinMapa, $sku; next; }
  my $lista = join(', ', map { "\"$_\"" } @{ $mapa{$sku} });
  $cambiadas++ if $l =~ s/cat: "[^"]*"/cats: [$lista]/;
}

open(my $out, '>:encoding(UTF-8)', $ruta) or die "no puedo escribir $ruta: $!";
print $out @lineas;
close($out);
print "productos reasignados: $cambiadas\n";
print "sin mapa: @sinMapa\n" if @sinMapa;
