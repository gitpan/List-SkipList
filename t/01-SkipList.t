package NumericNode;

use Carp::Assert;

our @ISA = qw( List::SkipList::Node );

sub validate_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  my $key = shift;
  return ($key =~ /^\-?\d+$/); # make sure key is simple natural number
}

sub key_cmp {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  my $left  = $self->key;
  my $right = shift;

  unless (defined $left) { return -1; }

  # Numeric Comparison

  return ($left <=> $right);
}

package MemoizedNode;

# This is here really to test an example that was in the v0.30
# POD. Example was removed but the test is left here anyway.

use Carp::Assert;

our @ISA = qw( List::SkipList::Node );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );

    $self->{MEMORY} = { };

    bless $self, $class;
}

sub key_cmp {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  my $key = shift;

  if (!exists $self->{MEMORY}->{$key}) {
    $self->{MEMORY}->{$key} = $self->SUPER::key_cmp( $key );
  }

  return $self->{MEMORY}->{$key};
}

package main;

use Test;
BEGIN { plan tests => 452 };
use List::SkipList 0.32;
ok(1); # If we made it this far, we're ok.

my $n = new List::SkipList::Node( key => 123, value => 987 );
ok( ref($n) eq "List::SkipList::Node" );
ok( $n->key == 123 );
ok( $n->value == 987 );

$n->key(456);
ok( $n->key == 456 );

$n->value(765);
ok( $n->value == 765 );

# ok( $n->is_nil );

my $c = new List::SkipList( max_level => 4 );
ok( ref($c) eq "List::SkipList" );

ok( $c->max_level == 4 );
ok( $c->size      == 0 );

undef $c;

$c = new List::SkipList();
ok( ref($c) eq "List::SkipList" );

ok( $c->max_level == 32 );
ok( $c->size      == 0 );


my %TESTDATA1 = (
 'aaa' => 100,
 'aa'  => 101,
 'a'   => 102,
 'bbb' => 103,
 'ccc' => 104,
 'zzz' => 200,
 'mmm' => 201,
 'naf' => 0,
);

my $Size = 0;

foreach my $key (keys %TESTDATA1) {
  $value = $TESTDATA{ $key };

  ok(!$c->exists($key) );

  $c->insert($key, $value );
  $Size++;

  ok( $c->size      == $Size );

  ok( $c->exists($key) );
  ok( $c->find($key) == $value );

  $c->insert($key, $value+1 );
  ok( $c->size      == $Size );
  ok( $c->find($key) == ($value+1) );
}

$c->clear;
$Size = 0;
ok( $c->size == 0 );

my ($aux_value, $finger);

foreach my $key (sort keys %TESTDATA1) {
  $value = $TESTDATA{ $key };

  ok(!$c->exists($key) );

  $c->insert($key, $value );
  $Size++;

  ok( $c->size      == $Size );

  ok( $c->exists($key) );
  ok( $c->find($key) == $value );

  ($aux_value, $finger) = $c->find($key, $finger);
  ok( $aux_value == $value );
  ok( defined $finger );

  $c->insert($key, $value-1 );
  ok( $c->size      == $Size );
  ok( $c->find($key) == ($value-1) );

  $c->insert($key, $value );

}

foreach my $key (keys %TESTDATA1) {
  $value = $TESTDATA{ $key };

  ok( $value == $c->delete( $key ) );
  $Size--;

  ok( $c->size == $Size );
}

foreach my $key (reverse sort keys %TESTDATA1) {
  $value = $TESTDATA{ $key };

  ok(!$c->exists($key) );

  $c->insert($key, $value );
  $Size++;

  ok( $c->size      == $Size );

  ok( $c->exists($key) );
  ok( $c->find($key) == $value );

  $c->insert($key, $value-1000 );
  ok( $c->size      == $Size );
  ok( $c->find($key) == ($value-1000) );

  $c->insert($key, $value );

}

# v0.03 we added ability to define custom nodes

my $n = new NumericNode();
ok( ref($n) eq "NumericNode" );
ok( UNIVERSAL::isa($n, "List::SkipList::Node") );
ok( $n->validate_key(1) );
ok(!$n->validate_key('a'));
ok( $n->validate_value( undef ) );

my $d = new List::SkipList( node_class => 'NumericNode' );
ok( ref($d) eq "List::SkipList");

for (my $i=1; $i<21; $i++) {
  ok($d->size == ($i-1));
  $d->insert($i, $i*100);
  ok($d->size == ($i));
}

my $last = $d->first_key;
ok($last == 1);

while (my $next = $d->next_key($last)) {
  ok( $next == ($last+1) );
  $last = $next;
}

# Same tests, with fingers

{
  my $size = $d->size;
  ok($size != 0);

  ($last, $finger) = $d->first_key;
  ok($last == 1);
  ok(defined $finger);

  my $count = 1;

  while (my ($next, $finger) = $d->next_key($last)) {
    $count++;
    ok( $next == ($last+1) );
    ok( defined $finger );
    $last = $next;
  }

  ok($count == $size);
}

# Testing memoized node example

my $e = new List::SkipList( node_class => 'MemoizedNode' );
ok( ref($e) eq "List::SkipList");

foreach my $key (keys %TESTDATA1) {
  $value = $TESTDATA{ $key };

  ok(! $e->exists($key) );

  $e->insert($key, $value );

  ok( $e->exists($key) );
  ok( $e->find($key) == $value );

  $e->insert($key, $value+1 );
  ok( $e->find($key) == ($value+1) );
}

# We build two lists and merge them

my $f = new List::SkipList( node_class => 'NumericNode' );
ok( ref($f) eq "List::SkipList");

foreach my $i (qw( 1 3 5 7 9 )) {
  my $finger = $f->insert($i, $i);
  ok($f->find($i, $finger), $i);   # test return of fingers from insertion
}
ok($f->size,5);

$f->merge($f);
ok($f->size,5);

my $g = new List::SkipList( node_class => 'NumericNode' );
ok( ref($g) eq "List::SkipList");

foreach my $i (qw( 2 4 6 8 10 )) {
  $g->insert($i, $i);
}
ok($g->size,5);

$f->merge($g);
ok($f->size,10);

foreach my $i (1..10) {
  ok($f->find($i), $i);
}

# redefine $g

foreach my $i (qw( 2 4 6 8 10 )) {
  $g->insert($i, -$i);
}
ok($g->size,5);

$g->merge($g);
ok($g->size,5);

# We want to test that mergine does not overwrite original values

$g->merge($f);
ok($g->size,10);

foreach my $i (1..10) {
  ok($g->find($i), (($i%2)?$i:-$i) );
}

{
  my ($k,$v) = $g->least;
  ok($k, 1);
  ok($v, 1);

  ($k, $v) = $g->greatest;
  ok($k,10);
  ok($v, -10);
}

$f->clear;
ok($f->size,0);

$f->append($g);
ok($f->size,$g->size);

$f->clear;
ok($f->size,0);

$f->insert(-1, -1);
$f->insert(-2, 2);

ok($f->size, 2);

$f->append($g);

ok($f->size, 2+$g->size);

foreach my $i (-2..10) {
  ok($f->find($i), (($i%2)?$i:-$i) ), if ($i);
}

{
  my ($k1,$v1) = $g->greatest;
  my ($k2,$v2) = $f->greatest;
  ok($k1, $k2);
  ok($v1, $v2);
}

my $z = $f->copy;
ok($z->size, $f->size);

foreach my $i (-2..10) {
  ok($z->find($i), (($i%2)?$i:-$i) ), if ($i);
}

$z->clear;
ok($z->size, 0);

$z->append( $f->copy );
ok($z->size, $f->size);

foreach my $i (-2..10) {
  ok($z->find($i), (($i%2)?$i:-$i) ), if ($i);
}

{
  my @keys = $g->keys;
  ok(scalar @keys, $g->size);

  foreach my $i (1..10) {
    ok($i, @keys[$i-1]); }

  ok(scalar $g->first_key, shift @keys);
  while (@keys) { ok($g->next_key, shift @keys); }

  my @vals = $g->values;

  foreach my $i (1..10) {
    ok($g->find($i), @vals[$i-1]); }
}



# For completion sake, we added the ability to tie

tie my %hash, 'List::SkipList';

my $h = tied %hash;
ok(ref($h), 'List::SkipList');
ok($h->size,0);

$hash{abc} = 2;

ok($hash{abc}, 2);

ok($h->size, 1);
ok($h->find('abc'), 2);

delete $hash{'abc'};

ok($h->size, 0);
ok(!$h->find('abc'));

# TODO: More tests should be added
