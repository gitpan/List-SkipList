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

package main;

use Test;
BEGIN { plan tests => 315 };
use List::SkipList 0.63;
ok(1); # If we made it this far, we're ok.

my $n = new List::SkipList::Node( 123, 987 );
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
  $value = $TESTDATA1{ $key };

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
  $value = $TESTDATA1{ $key };

  ok(!$c->exists($key) );

  $c->insert($key, $value );
  $Size++;

  ok( $c->size      == $Size );

  ok( $c->exists($key) );
  ok( $c->find($key) == $value );

  ($aux_value, $finger) = $c->find_with_finger($key, $finger);
  ok( defined $aux_value );
  ok( $aux_value == $value );
  ok( defined $finger );

  $c->insert($key, $value-1 );
  ok( $c->size      == $Size );
  ok( $c->find($key) == ($value-1) );

  $c->insert($key, $value );

}


foreach my $key (keys %TESTDATA1) {
  $value = $TESTDATA1{ $key };
  ok( defined $value );

#  unless (defined $value) { die "undefined"; }

  ok( $value == $c->delete( $key ) );
  $Size--;

  ok( $c->size == $Size );
}


foreach my $key (reverse sort keys %TESTDATA1) {
  $value = $TESTDATA1{ $key };

  ok(!$c->exists($key) );

  $c->insert($key, $value );
  $Size++;

  ok( $c->size      == $Size );

  ok( $c->exists($key) );
  ok( $c->find($key), $value );

  $c->insert($key, $value-1000 );
  ok( $c->size       == $Size );
  ok( $c->find($key) == ($value-1000) );

  $c->insert($key, $value );

}


# v0.03 we added ability to define custom nodes

$n = new NumericNode();
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

# Test decimal keys
{
  $d->clear;

  no integer;
  my $PI = 3.14159;
  $d->insert($PI, -999);
  ok($d->find($PI) == -999);
  ok(! $d->find(int($PI)));
}





