#-*- mode: perl;-*-

package NumericNode;

# use Carp::Assert;

our @ISA = qw( List::SkipList::Node );

sub validate_key {
  my $self = shift;
#  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  my $key = shift;
  return ($key =~ /^\-?\d+$/); # make sure key is simple natural number
}

sub key_cmp {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  my $left  = $self->key;
  my $right = shift;

  unless (defined $left) { return -1; }

  # Numeric Comparison

  return ($left <=> $right);
}

package main;

use Test::More tests => 134;
use List::SkipList 0.70;

# We build two lists and merge them

my $f = new List::SkipList( node_class => 'NumericNode' );
ok( ref($f) eq "List::SkipList");

foreach my $i (qw( 1 3 5 7 9 )) {
  my $finger = $f->insert($i, $i);
  ok($f->find($i, $finger) == $i);   # test return of fingers from insertion
}
ok($f->size == 5);

$f->merge($f);
ok($f->size == 5);

my $g = new List::SkipList( node_class => 'NumericNode' );
ok( ref($g) eq "List::SkipList");

foreach my $i (qw( 2 4 6 8 10 )) {
  $g->insert($i, $i);
}
ok($g->size == 5);

$f->merge($g);
ok($f->size == 10);

# $f->_debug;
# $g->_debug;

foreach my $i (1..10) {
  ok($f->find($i) == $i);
}



# redefine $g

foreach my $i (qw( 2 4 6 8 10 )) {
  $g->insert($i, -$i);
}
ok($g->size == 5);

$g->merge($g);
ok($g->size == 5);

# We want to test that mergine does not overwrite original values

$g->merge($f);
ok($g->size == 10);


foreach my $i (1..10) {
  ok($g->find($i) == (($i%2)?$i:-$i) );
}


{
  my ($k,$v) = $g->least;
  ok($k == 1);
  ok($v == 1);

  ($k, $v) = $g->greatest;
  ok($k == 10);
  ok($v == -10);
}

$f->clear;
ok($f->size == 0);


$f->append($g);
ok($f->size == $g->size);

$f->clear;
ok($f->size == 0);

$f->insert(-1, -1);
$f->insert(-2, 2);

ok($f->size == 2);


$f->append($g);

ok($f->size == 2+$g->size);

foreach my $i (-2..10) {
  ok($f->find($i) == (($i%2)?$i:-$i) ), if ($i);
}

{
  my ($k1,$v1) = $g->greatest;
  my ($k2,$v2) = $f->greatest;
  ok($k1 == $k2);
  ok($v1 == $v2);
}

my $z = $f->copy;
ok($z->size == $f->size);

# if ($z->size != $f->size) {
#   $z->_debug;
#   $f->_debug;
#   $g->_debug;
#   die;
# }

foreach my $i (-2..10) {
  ok($f->find($i) == (($i%2)?$i:-$i) ), if ($i);
  ok($z->find($i) == (($i%2)?$i:-$i) ), if ($i);
}

$z->clear;
ok($z->size == 0);


$z->append( $f->copy );
ok($z->size == $f->size);

foreach my $i (-2..10) {
  ok($z->find($i) == (($i%2)?$i:-$i) ), if ($i);
}

{
  my @keys = $g->keys;
  ok(scalar @keys == $g->size);

  foreach my $i (1..10) {
    ok($i == $keys[$i-1]); }

  ok(scalar $g->first_key == shift @keys);
  while (@keys) { ok($g->next_key == shift @keys); }

  my @vals = $g->values;

  foreach my $i (1..10) {
    ok($g->find($i) == $vals[$i-1]); }
}


# For completion sake, we added the ability to tie

tie my %hash, 'List::SkipList';

my $h = tied %hash;
ok(ref($h) eq 'List::SkipList');
ok($h->size == 0);

$hash{abc} = 2;

ok($hash{abc} == 2);

ok($h->size == 1);
ok($h->find('abc') == 2);

delete $hash{'abc'};

ok($h->size == 0);
ok(!$h->find('abc'));

# TODO: More tests should be added
