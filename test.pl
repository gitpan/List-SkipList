# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 173 };
use List::SkipList 0.02;
ok(1); # If we made it this far, we're ok.

#########################

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

foreach my $key (sort keys %TESTDATA1) {
  $value = $TESTDATA{ $key };

  ok(!$c->exists($key) );

  $c->insert($key, $value );
  $Size++;

  ok( $c->size      == $Size );

  ok( $c->exists($key) );
  ok( $c->find($key) == $value );

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
