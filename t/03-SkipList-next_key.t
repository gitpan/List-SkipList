package main;

use constant SIZE => 100;

use Test;
BEGIN { plan tests => 6+(2*SIZE) };
use List::SkipList 0.51;
ok(1);

my $List = new List::SkipList;

ok(!defined $List->first_key); # make sure this returns nothing

my @data = sort (1..SIZE);

ok(SIZE == @data);

foreach (@data) {
  $List->insert($_);
}
ok($List->size == @data);

# check that next_key works without first_key

foreach (@data) {
  ok($_ eq $List->next_key);
}

# check that first_key/next_key still work

{
  my $i = 0;

  ok($data[$i++] eq $List->first_key);

  while (my $key = $List->next_key) {
    ok($data[$i++] eq $key);
  }
}

# test reset method

{
  ok($data[0] eq $List->first_key);
  $List->reset;
  ok($data[0] eq $List->next_key);
}
