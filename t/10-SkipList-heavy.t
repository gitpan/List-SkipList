package main;

use strict;
use warnings;

# These tests are redundant, but they are useful for "heavy" testing
# to find rare errors (since this is a non-deterministic algorithm)
# and for some informal benchmark comparisons.

# For "heavy" testing, change size to a larger value (1,000 or 10,000).

use constant SIZE => 100;

use Test;
BEGIN { plan tests => 1+(8*SIZE) };
use List::SkipList 0.51;
ok(1);

my @Keys = ();
my $Cnt  = SIZE;

my $Stuff = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

sub random_stuff {
  my $len ||= 8;
  my $thing = "";
  for(1..$len) {
    $thing .= substr($Stuff, int(rand(length($Stuff))),1);
  }
  return $thing;
}

my %Hash = ();
my $List = new List::SkipList;

foreach (1..SIZE) {
  my $k = random_stuff();
  my $v = random_stuff();
  $Hash{ $k } = $v;

#  print STDERR $k, " ", $v, "\n";

  my $finger = $List->insert( $k, $v );
  ok( $List->size, scalar(keys %Hash) );

  ok( $List->exists( $k ) );
  ok( $List->find( $k ), $v );

  ok( $List->exists( $k, $finger ) );
  ok( $List->find( $k, $finger ), $v );
}

foreach my $key (sort keys %Hash) {
  ok($key eq $List->next_key);
}

foreach my $key (keys %Hash) {
  my $sz = $List->size;
  ok( $List->delete( $key ), $Hash{$key} );
  ok( $List->size == $sz-1 );
}



